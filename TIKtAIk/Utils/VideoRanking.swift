//
// VideoRanking.swift
// TIKtAIk
//
// Created: 2024-02-14
// Last modified: 2024-02-14
//
// Purpose: Video ranking and scoring algorithms
// Author: Assistant
// Copyright © 2024 TIKtAIk. All rights reserved.
//

import Foundation

enum VideoRanking {
    /// Calculates video relevance score based on multiple factors
    /// - Parameters:
    ///   - video: Video to score
    ///   - userContext: User context for personalization
    /// - Returns: Relevance score (higher is more relevant)
    static func calculateScore(video: Video, userContext: UserContext) -> Double {
        var score = 1.0
        
        // Recency boost (max 2.0)
        let hoursSinceUpload = -video.createdAt.timeIntervalSinceNow / 3600
        let recencyScore = max(0, 2.0 - (hoursSinceUpload / 24))
        score *= recencyScore
        
        // Following boost (1.5x)
        if userContext.followedCreators.contains(video.userId) {
            score *= 1.5
        }
        
        // Tag matching boost (1.2x per tag)
        let matchingTags = video.tags.intersection(userContext.preferredTags)
        if !matchingTags.isEmpty {
            score *= pow(1.2, Double(matchingTags.count))
        }
        
        // View history boost
        if let stats = userContext.videoStats[video.id] {
            // Completion rate boost (max 1.3x)
            let completionBoost = 1.0 + (stats.completionRate * 0.3)
            score *= completionBoost
            
            // Watch time boost (max 1.2x)
            let watchTimeBoost = min(1.2, 1.0 + (Double(stats.watchTime) / 300.0)) // 5 min max
            score *= watchTimeBoost
        }
        
        // Engagement metrics
        let viewScore = log10(Double(video.stats.views + 1))
        let likeScore = log10(Double(video.stats.likes + 1)) * 2
        let commentScore = log10(Double(video.stats.commentsCount + 1)) * 1.5
        let shareScore = log10(Double(video.stats.shares + 1)) * 3
        
        let engagementScore = 1.0 + (viewScore + likeScore + commentScore + shareScore) / 10
        score *= engagementScore
        
        return score
    }
} 