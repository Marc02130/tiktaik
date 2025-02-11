//
// VideoCache.swift
// TIKtAIk
//
// Created: 2024-02-14
// Last modified: 2024-02-14
//
// Purpose: Cache service for video URLs and thumbnails
// Author: Assistant
// Copyright © 2024 TIKtAIk. All rights reserved.
//

import Foundation
import AVFoundation

final class VideoCache {
    static let shared = VideoCache()
    private var urlCache: [String: URL] = [:]
    private var playerCache: [String: AVPlayer] = [:]
    private let maxCacheSize = 50
    
    private init() {}
    
    func cacheURL(_ url: URL, for videoId: String) {
        urlCache[videoId] = url
        cleanCacheIfNeeded()
    }
    
    func getCachedURL(for videoId: String) -> URL? {
        urlCache[videoId]
    }
    
    func cachePlayer(id: String, player: AVPlayer) {
        cleanCacheIfNeeded()
        playerCache[id] = player
    }
    
    func getCachedPlayer(for id: String) -> AVPlayer? {
        playerCache[id]
    }
    
    private func cleanCacheIfNeeded() {
        if urlCache.count > maxCacheSize {
            urlCache.removeAll()
        }
        if playerCache.count > maxCacheSize {
            playerCache.removeAll()
        }
    }
} 