//
// FeedService.swift
// TIKtAIk
//
// Created: 2024-02-14
// Last modified: 2024-02-14
//
// Purpose: Service for fetching and managing video feed
// Author: Assistant
// Copyright © 2024 TIKtAIk. All rights reserved.
//

import Foundation
import FirebaseFirestore
import FirebaseAuth
import SwiftUI // For pow() function

@Observable final class FeedService {
    private let db = Firestore.firestore()
    private let auth = Auth.auth()
    private let metrics = FeedMetricsService()
    
    /// Cache for feed results
    private var feedCache: [String: (videos: [Video], timestamp: Date)] = [:]
    private let cacheTimeout: TimeInterval = 300 // 5 minutes
    
    /// Fetches next batch of videos based on configuration
    /// - Parameter query: Feed query parameters
    /// - Returns: Array of videos matching query
    func fetchFeedVideos(query: FeedQuery) async throws -> [Video] {
        // Check cache first
        let cacheKey = "\(query.config.feedType)_\(query.lastVideo?.id ?? "initial")"
        if let cached = feedCache[cacheKey],
           Date().timeIntervalSince(cached.timestamp) < cacheTimeout {
            return cached.videos
        }
        
        // Track performance
        let (videos, duration) = await FeedMetrics.track {
            if query.config.isCreatorOnly {
                return try await fetchCreatorVideos(query)
            } else if query.config.followingOnly {
                return try await fetchFollowingVideos(query)
            } else {
                return try await fetchMixedFeed(query)
            }
        }
        
        // Cache results
        feedCache[cacheKey] = (videos, Date())
        
        // Schedule cache cleanup
        Task {
            try await Task.sleep(nanoseconds: UInt64(cacheTimeout * 1_000_000_000))
            feedCache.removeValue(forKey: cacheKey)
        }
        
        print("Feed load time: \(duration)s")
        return videos
    }
    
    /// Fetches videos for creator-only mode
    private func fetchCreatorVideos(_ query: FeedQuery) async throws -> [Video] {
        let videosRef = Firestore.firestore().collection(Video.collectionName)
        
        var queryRef: Query = videosRef
        
        if query.config.isCreatorOnly {
            print("DEBUG: Applying creator filter for userId:", query.config.userId)
            // Only show videos from this creator
            queryRef = queryRef.whereField("userId", isEqualTo: query.config.userId)
        } else {
            // Show videos from all creators
            queryRef = queryRef.whereField("isCreator", isEqualTo: true)
        }
        
        queryRef = queryRef
            .order(by: "createdAt", descending: true)
            .limit(to: query.limit)
        
        let snapshot = try await queryRef.getDocuments()
        print("DEBUG: Found \(snapshot.documents.count) documents")
        
        let videos = snapshot.documents.compactMap { doc -> Video? in
            do {
                let video = try Video.from(doc)
                print("DEBUG: Decoded video:", video.id)
                return video
            } catch {
                print("DEBUG: Failed to decode video from doc:", doc.documentID, error)
                return nil
            }
        }
        
        print("DEBUG: Returning \(videos.count) videos")
        return videos
    }
    
    /// Fetches videos from followed creators
    private func fetchFollowingVideos(_ query: FeedQuery) async throws -> [Video] {
        // Get followed creator IDs
        let followsRef = db.collection("follows")
            .whereField("followerId", isEqualTo: query.config.userId)
        let followsSnapshot = try await followsRef.getDocuments()
        let followedIds = followsSnapshot.documents.map { $0.get("followedId") as? String ?? "" }
        
        guard !followedIds.isEmpty else { return [] }
        
        // Fetch videos from followed creators
        var videosRef = db.collection(Video.collectionName)
            .whereField("userId", in: followedIds)
            .whereField("isPrivate", isEqualTo: false)
            .order(by: "createdAt", descending: true)
            .limit(to: query.limit)
        
        if let lastVideo = query.lastVideo {
            videosRef = videosRef.start(after: [lastVideo.createdAt])
        }
        
        let snapshot = try await videosRef.getDocuments()
        return try snapshot.documents.map { try Video.from($0) }
    }
    
    /// Fetches mixed feed with scoring
    private func fetchMixedFeed(_ query: FeedQuery) async throws -> [Video] {
        guard let userId = auth.currentUser?.uid else {
            throw FeedError.notAuthenticated
        }
        
        // Get user's interests and followed creators
        let followedCreators = try await fetchFollowedCreators(userId: userId)
        let userProfile = try await fetchUserProfile(userId: userId)
        let userInterests = Set(userProfile?.interests ?? [])
        
        // Base query for public videos
        var videosRef = db.collection(Video.collectionName)
            .whereField("isPrivate", isEqualTo: false)
        
        // If user has interests, prioritize matching videos
        if !userInterests.isEmpty {
            // Firebase doesn't support array contains any directly with multiple conditions
            // So we'll fetch more videos and filter in memory
            videosRef = videosRef
                .order(by: "createdAt", descending: true)
                .limit(to: query.limit * 3)
        } else {
            videosRef = videosRef
                .order(by: "createdAt", descending: true)
                .limit(to: query.limit)
        }
        
        let snapshot = try await videosRef.getDocuments()
        var videos = try snapshot.documents.map { try Video.from($0) }
        
        // Score videos based on:
        // 1. Matching interests (tags)
        // 2. From followed creators
        // 3. Recency
        videos.sort { video1, video2 in
            let score1 = calculateVideoScore(
                video: video1,
                userInterests: userInterests,
                followedCreators: followedCreators
            )
            let score2 = calculateVideoScore(
                video: video2,
                userInterests: userInterests,
                followedCreators: followedCreators
            )
            return score1 > score2
        }
        
        // Return top videos after scoring
        return Array(videos.prefix(query.limit))
    }
    
    private func calculateVideoScore(
        video: Video,
        userInterests: Set<String>,
        followedCreators: Set<String>
    ) -> Double {
        var score = 1.0
        
        // Interest match bonus (2x per matching tag)
        let matchingTags = Set(video.tags).intersection(userInterests)
        if !matchingTags.isEmpty {
            score *= Double(matchingTags.count) * 2.0
        }
        
        // Following bonus (1.5x)
        if followedCreators.contains(video.userId) {
            score *= 1.5
        }
        
        // Recency bonus (max 1.3x, decreasing over 7 days)
        let ageInHours = -video.createdAt.timeIntervalSinceNow / 3600
        let recencyMultiplier = max(1.0, 1.3 - (ageInHours / (24 * 7)))
        score *= recencyMultiplier
        
        return score
    }
    
    private func fetchUserProfile(userId: String) async throws -> UserProfile? {
        let doc = try await db.collection(UserProfile.collectionName)
            .document(userId)
            .getDocument()
        
        return try? UserProfile.from(doc)
    }
    
    /// Fetches user context for video scoring
    private func fetchUserContext(userId: String) async throws -> UserContext {
        async let followedCreators = fetchFollowedCreators(userId: userId)
        async let preferredTags = fetchUserPreferredTags(userId: userId)
        async let videoStats = fetchUserVideoStats(userId: userId)
        
        return UserContext(
            userId: userId,
            followedCreators: try await followedCreators,
            preferredTags: try await preferredTags,
            videoStats: try await videoStats
        )
    }
    
    /// Fetches user's video viewing statistics
    private func fetchUserVideoStats(userId: String) async throws -> [String: UserContext.VideoStats] {
        let viewsRef = db.collection("videoViews")
            .whereField("userId", isEqualTo: userId)
            .order(by: "timestamp", descending: true)
            .limit(to: 100)
        
        let snapshot = try await viewsRef.getDocuments()
        
        return Dictionary(
            uniqueKeysWithValues: snapshot.documents.compactMap { doc -> (String, UserContext.VideoStats)? in
                guard let videoId = doc.get("videoId") as? String,
                      let completionRate = doc.get("completionRate") as? Double,
                      let watchTime = doc.get("watchTime") as? Int,
                      let timestamp = doc.get("timestamp") as? Timestamp
                else { return nil }
                
                return (videoId, UserContext.VideoStats(
                    completionRate: completionRate,
                    watchTime: watchTime,
                    lastWatched: timestamp.dateValue()
                ))
            }
        )
    }
    
    /// Fetches tag-based recommendations
    private func fetchTagBasedVideos(_ query: FeedQuery, userId: String) async throws -> [Video] {
        // Get user's viewed tags if no specific tags selected
        var tags = query.config.selectedTags
        if tags.isEmpty {
            tags = try await fetchUserPreferredTags(userId: userId)
        }
        
        // Fetch videos with matching tags
        var videosRef = db.collection(Video.collectionName)
            .whereField("isPrivate", isEqualTo: false)
            .order(by: "createdAt", descending: true)
            .limit(to: query.limit * 2)
        
        if let lastVideo = query.lastVideo {
            videosRef = videosRef.start(after: [lastVideo.createdAt])
        }
        
        let snapshot = try await videosRef.getDocuments()
        let videos = try snapshot.documents.map { try Video.from($0) }
        
        // Get user context for scoring
        let followedCreators = try await fetchFollowedCreators(userId: userId)
        let videoStats = try await fetchUserVideoStats(userId: userId)
        let userContext = UserContext(
            userId: userId,
            followedCreators: followedCreators,
            preferredTags: tags,
            videoStats: videoStats
        )
        
        // Filter and score videos
        let scoredVideos = videos
            .filter { !$0.tags.intersection(tags).isEmpty }
            .sorted { video1, video2 in
                VideoRanking.calculateScore(video: video1, userContext: userContext) >
                VideoRanking.calculateScore(video: video2, userContext: userContext)
            }
        
        return Array(scoredVideos.prefix(query.limit))
    }
    
    /// Fetches user's preferred tags based on view history
    private func fetchUserPreferredTags(userId: String) async throws -> Set<String> {
        // Query videos collection directly and sort by views
        let videosRef = db.collection(Video.collectionName)
            .order(by: "stats.views", descending: true)
            .limit(to: 50)
        
        let snapshot = try await videosRef.getDocuments()
        let videos = try snapshot.documents.compactMap { doc in
            try doc.data(as: Video.self)
        }
        
        // Extract tags from most viewed videos
        return Set(videos.flatMap { $0.tags })
    }
    
    private func fetchFollowedCreators(userId: String) async throws -> Set<String> {
        let followsRef = db.collection("follows")
            .whereField("followerId", isEqualTo: userId)
        let snapshot = try await followsRef.getDocuments()
        return Set(snapshot.documents.compactMap { $0.get("followedId") as? String })
    }
    
    private func parseVideoMetadata(_ data: [String: Any]) -> Video.VideoMetadata {
        let metadata = data["metadata"] as? [String: Any] ?? [:]
        return Video.VideoMetadata(
            duration: metadata["duration"] as? Double ?? 0,
            width: metadata["width"] as? Int ?? 0,
            height: metadata["height"] as? Int ?? 0,
            size: metadata["size"] as? Int ?? 0,
            format: metadata["format"] as? String,
            resolution: metadata["resolution"] as? String,
            uploadDate: (metadata["uploadDate"] as? Timestamp)?.dateValue(),
            lastModified: (metadata["lastModified"] as? Timestamp)?.dateValue()
        )
    }
    
    func fetchFeed(query: FeedQuery) async throws -> [Video] {
        print("DEBUG: FeedService - Fetching feed")
        print("DEBUG: Query config: \(query.config)")
        
        var feedQuery = Firestore.firestore()
            .collection("videos")
            .whereField("status", isEqualTo: Video.Status.ready.rawValue)  // Only get ready videos
            .limit(to: query.limit)
        
        // Add other query conditions...
        if query.config.isCreatorOnly {
            feedQuery = feedQuery.whereField("userId", isEqualTo: query.config.userId)
        }
        
        if query.config.followingOnly {
            // Add following filter
        }
        
        if !query.config.selectedTags.isEmpty {
            feedQuery = feedQuery.whereField("tags", arrayContainsAny: Array(query.config.selectedTags))
        }
        
        // Rest of query implementation...
        
        let snapshot = try await feedQuery.getDocuments()
        print("DEBUG: Found \(snapshot.documents.count) documents")
        
        let videos = try snapshot.documents.compactMap { doc -> Video? in
            try doc.data(as: Video.self)
        }
        
        print("DEBUG: Returning \(videos.count) videos")
        return videos
    }
    
    private func updateVideoStats(_ video: Video) async throws {
        let ref = db.collection(Video.collectionName).document(video.id)
        
        // These operations can throw
        try await ref.updateData([
            "viewCount": FieldValue.increment(Int64(1)),
            "lastViewedAt": Timestamp(date: Date())
        ])
    }
    
    private func updateUserStats(_ userId: String) async throws {
        let ref = db.collection("userStats").document(userId)
        
        // These operations can throw
        try await ref.setData([
            "lastActiveAt": Timestamp(date: Date()),
            "totalViews": FieldValue.increment(Int64(1))
        ], merge: true)
    }
    
    // Update the calling functions to properly handle throws
    func recordView(for video: Video) async {
        do {
            try await updateVideoStats(video)
            if let userId = Auth.auth().currentUser?.uid {
                try await updateUserStats(userId)
            }
        } catch {
            print("Failed to record view:", error)
        }
    }
}

enum FeedError: LocalizedError {
    case notAuthenticated
    case emptyFeed
    case invalidQuery
    
    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "User must be authenticated"
        case .emptyFeed:
            return "No videos found"
        case .invalidQuery:
            return "Invalid feed query"
        }
    }
}

extension FeedConfiguration {
    var feedType: String {
        if isCreatorOnly { return "creator" }
        if followingOnly { return "following" }
        return "mixed"
    }
} 