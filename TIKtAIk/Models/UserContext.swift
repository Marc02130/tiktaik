//
// UserContext.swift
// TIKtAIk
//
// Created: 2024-02-14
// Last modified: 2024-02-14
//

import Foundation

struct UserContext {
    let userId: String
    let followedCreators: Set<String>
    let preferredTags: Set<String>
    let videoStats: [String: VideoStats]
    
    struct VideoStats {
        let completionRate: Double
        let watchTime: Int
        let lastWatched: Date
    }
} 