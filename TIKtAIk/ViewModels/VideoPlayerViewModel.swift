//
// VideoPlayerViewModel.swift
// TIKtAIk
//
// Created: 2024-02-14
// Last modified: 2024-02-14
//
// Purpose: View model for video playback management
// Author: Assistant
// Copyright © 2024 TIKtAIk. All rights reserved.
//

import AVKit
import FirebaseStorage
import Combine

final class VideoPlayerViewModel: ObservableObject {
    /// Current video player instance
    @Published private(set) var player: AVPlayer?
    /// Current error message if any
    @Published private(set) var error: String?
    /// Loading state
    @Published private(set) var isLoading = false
    
    private let cache = VideoCache.shared
    
    /// Loads video from Firebase Storage
    /// - Parameter video: Video to load
    func loadVideo(_ video: Video) async {
        await MainActor.run {
            isLoading = true
            error = nil
            
            // Check cache first
            if let cachedPlayer = cache.getCachedPlayer(for: video.id) {
                self.player = cachedPlayer
                self.isLoading = false
                return
            }
        }
        
        do {
            // Check URL cache
            let videoURL: URL
            if let cachedURL = cache.getCachedURL(for: video.id) {
                videoURL = cachedURL
            } else {
                let storageRef = Storage.storage().reference(forURL: video.storageUrl)
                videoURL = try await storageRef.downloadURL()
                cache.cacheURL(id: video.id, url: videoURL)
            }
            
            // Create and cache player
            let playerItem = AVPlayerItem(url: videoURL)
            let player = AVPlayer(playerItem: playerItem)
            cache.cachePlayer(id: video.id, player: player)
            
            await MainActor.run {
                self.player = player
                self.isLoading = false
            }
            
        } catch {
            await MainActor.run {
                self.error = error.localizedDescription
                self.isLoading = false
            }
        }
    }
    
    /// Cleanup resources
    func cleanup() {
        player?.pause()
        player = nil
    }
} 