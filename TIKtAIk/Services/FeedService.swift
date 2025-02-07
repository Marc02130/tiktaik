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
        #if DEBUG
        print("Fetching creator videos for userId:", query.config.userId)
        
        // Debug: Print all videos in collection
        let allVideos = try await db.collection(Video.collectionName).getDocuments()
        print("Total videos in collection:", allVideos.documents.count)
        allVideos.documents.forEach { doc in
            let data = doc.data()
            print("Video document:")
            print("- id:", doc.documentID)
            print("- userId:", data["userId"] as? String ?? "nil")
            print("- title:", data["title"] as? String ?? "nil")
        }
        #endif
        
        // Query by userId (not creatorId)
        var videosRef = db.collection(Video.collectionName)
            .whereField("userId", isEqualTo: query.config.userId)
            .order(by: "createdAt", descending: true)
            .limit(to: query.limit)
        
        if let lastVideo = query.lastVideo {
            videosRef = videosRef.start(after: [lastVideo.createdAt])
        }
        
        let snapshot = try await videosRef.getDocuments()
        let videos = try snapshot.documents.map { try Video.from($0) }
        
        #if DEBUG
        print("Found \(videos.count) videos for creator")
        videos.forEach { video in
            print("Video: \(video.id), title: \(video.title), userId: \(video.userId)")
        }
        #endif
        
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
        // Fetch recent videos
        var videosRef = db.collection(Video.collectionName)
            .whereField("isPrivate", isEqualTo: false)
            .order(by: "createdAt", descending: true)
            .limit(to: query.limit * 2)
        
        if let lastVideo = query.lastVideo {
            videosRef = videosRef.start(after: [lastVideo.createdAt])
        }
        
        let snapshot = try await videosRef.getDocuments()
        let videos = try snapshot.documents.map { try Video.from($0) }
        
        // Get user context once for all videos
        let followedCreators = try await fetchFollowedCreators(userId: query.config.userId)
        let videoStats = try await fetchUserVideoStats(userId: query.config.userId)
        let userContext = UserContext(
            userId: query.config.userId,
            followedCreators: followedCreators,
            preferredTags: query.config.selectedTags,
            videoStats: videoStats
        )
        
        // Score and sort videos
        let scoredVideos = videos.sorted { video1, video2 in
            VideoRanking.calculateScore(video: video1, userContext: userContext) >
            VideoRanking.calculateScore(video: video2, userContext: userContext)
        }
        
        return Array(scoredVideos.prefix(query.limit))
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
        let viewsRef = db.collection("videoViews")
            .whereField("userId", isEqualTo: userId)
            .order(by: "timestamp", descending: true)
            .limit(to: 50)
        
        let viewsSnapshot = try await viewsRef.getDocuments()
        let videoIds = viewsSnapshot.documents.compactMap { $0.get("videoId") as? String }
        
        // Get videos and their tags
        let videos = try await withThrowingTaskGroup(of: Video.self) { group in
            for videoId in videoIds {
                group.addTask {
                    let doc = try await self.db.collection(Video.collectionName)
                        .document(videoId)
                        .getDocument()
                    guard let data = doc.data() else {
                        throw FeedError.invalidQuery
                    }
                    
                    return Video(
                        id: doc.documentID,
                        userId: data["userId"] as? String ?? "",
                        title: data["title"] as? String ?? "",
                        description: data["description"] as? String,
                        metadata: self.parseVideoMetadata(data),
                        stats: Video.Stats(
                            views: data["stats.views"] as? Int ?? 0,
                            likes: data["stats.likes"] as? Int ?? 0,
                            shares: data["stats.shares"] as? Int ?? 0,
                            commentsCount: data["stats.commentsCount"] as? Int ?? 0
                        ),
                        status: Video.Status(rawValue: data["status"] as? String ?? "") ?? .ready,
                        storageUrl: data["storageUrl"] as? String ?? "",
                        thumbnailUrl: data["thumbnailUrl"] as? String,
                        createdAt: (data["createdAt"] as? Timestamp)?.dateValue() ?? Date(),
                        updatedAt: (data["updatedAt"] as? Timestamp)?.dateValue() ?? Date(),
                        tags: Set(data["tags"] as? [String] ?? []),
                        isPrivate: data["isPrivate"] as? Bool ?? false,
                        allowComments: data["allowComments"] as? Bool ?? true
                    )
                }
            }
            
            var result: [Video] = []
            for try await video in group {
                result.append(video)
            }
            return result
        }
        
        // Count tag frequencies
        var tagFrequencies: [String: Int] = [:]
        for video in videos {
            for tag in video.tags {
                tagFrequencies[tag, default: 0] += 1
            }
        }
        
        return Set(tagFrequencies.sorted { $0.value > $1.value }
            .prefix(10)
            .map { $0.key })
    }
    
    /// Calculates video score based on multiple factors
    private func calculateVideoScore(
        uploadDate: Date,
        isFollowing: Bool,
        matchingTags: Int,
        stats: Video.Stats
    ) -> Double {
        var score = 1.0
        
        // Recency boost (max 2.0)
        let hoursSinceUpload = -uploadDate.timeIntervalSinceNow / 3600
        let recencyScore = max(0, 2.0 - (hoursSinceUpload / 24))
        score *= recencyScore
        
        // Following boost (1.5x)
        if isFollowing {
            score *= 1.5
        }
        
        // Tag matching boost (1.2x per tag)
        if matchingTags > 0 {
            score *= pow(1.2, Double(matchingTags))
        }
        
        // Engagement boost
        let viewScore = log10(Double(stats.views + 1))
        let likeScore = log10(Double(stats.likes + 1)) * 2
        let commentScore = log10(Double(stats.commentsCount + 1)) * 1.5
        let shareScore = log10(Double(stats.shares + 1)) * 3
        
        let engagementScore = 1.0 + (viewScore + likeScore + commentScore + shareScore) / 10
        score *= engagementScore
        
        return score
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