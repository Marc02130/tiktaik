//
// FeedModels.swift
// TIKtAIk
//
// Created: 2024-02-14
// Last modified: 2024-02-14
//
// Purpose: Models for feed configuration and queries
// Author: Assistant
// Copyright © 2024 TIKtAIk. All rights reserved.
//

import Foundation

/// Configuration for feed content filtering
struct FeedConfiguration {
    let userId: String
    /// Whether to show only the current user's content
    var isCreatorOnly: Bool
    /// Whether to show only followed creators' content
    var followingOnly: Bool
    /// Tags to filter content by
    var selectedTags: Set<String>
}

/// Query parameters for feed pagination
struct FeedQuery {
    /// Maximum number of videos to fetch
    let limit: Int
    /// Last video from previous fetch for pagination
    let lastVideo: Video?
    /// Feed configuration settings
    let config: FeedConfiguration
}

/// Video scoring for feed ranking
struct VideoScore {
    /// Video being scored
    let video: Video
    /// Calculated relevance score
    var score: Double
    
    /// Calculates video relevance score
    /// - Parameters:
    ///   - uploadDate: When the video was uploaded
    ///   - isFollowing: Whether user follows the creator
    ///   - matchingTags: Number of matching tags
    /// - Returns: Relevance score
    static func calculateScore(
        uploadDate: Date,
        isFollowing: Bool,
        matchingTags: Int
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
        score *= pow(1.2, Double(matchingTags))
        
        return score
    }
}

struct FeedMetrics {
    let loadTime: TimeInterval
    let feedType: String
    let resultCount: Int
    let timestamp: Date
    
    static func track(operation: () async throws -> [Video]) async -> ([Video], TimeInterval) {
        let start = Date()
        do {
            let videos = try await operation()
            return (videos, Date().timeIntervalSince(start))
        } catch {
            return ([], Date().timeIntervalSince(start))
        }
    }
} 