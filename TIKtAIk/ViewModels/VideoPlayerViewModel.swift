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
import FirebaseFirestore

@MainActor
final class VideoPlayerViewModel: ObservableObject {
    /// Current video player instance
    @Published var player: AVPlayer?
    /// Current error message if any
    @Published private(set) var error: String?
    /// Loading state
    @Published private(set) var isLoading = false
    
    @Published var isLiked = false
    @Published var likes = 0
    @Published var comments = 0
    @Published var shares = 0
    
    private let cache = VideoCache.shared
    private let video: Video  // Keep as let since getVideoURL is no longer mutating
    
    init(video: Video) {
        self.video = video
        self.likes = video.stats.likes
        self.comments = video.stats.commentsCount
        self.shares = video.stats.shares
        
        // Remove direct URL initialization since it's using storageUrl incorrectly
        // Instead, start loading video immediately
        Task {
            await loadVideo()
        }
        
        // Keep existing notification observer
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("StopVideo"),
            object: nil,
            queue: .main
        ) { [weak self] notification in
            if let videoId = notification.userInfo?["videoId"] as? String,
               videoId == self?.video.id {
                Task { @MainActor in
                    self?.stopPlayback()
                }
            }
        }
    }
    
    @objc private func videoDidFinish() {
        print("DEBUG: Video finished playing, sending advance notification")
        NotificationCenter.default.post(name: .advanceToNextVideo, object: nil)
    }
    
    /// Preloads video without starting playback
    func preloadVideo() async {
        do {
            // Check cache first
            if cache.getCachedPlayer(for: video.id) != nil {
                // Already cached, nothing to do
                return
            }
            
            // Get fresh URL and create player
            let url = try await video.getVideoURL()
            let playerItem = AVPlayerItem(url: url)
            let player = AVPlayer(playerItem: playerItem)
            
            // Cache the player for later use
            cache.cachePlayer(id: video.id, player: player)
            
            // Add end notification observer
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(videoDidFinish),
                name: .AVPlayerItemDidPlayToEndTime,
                object: playerItem
            )
            
            // Set up player but don't start playing
            await MainActor.run {
                self.player = player
                self.isLoading = false
            }
            
        } catch {
            print("Error preloading video:", error)
        }
    }
    
    /// Loads video from Firebase Storage
    /// - Parameter video: Video to load
    func loadVideo() async {
        do {
            await MainActor.run {
                isLoading = true
                error = nil
            }
            
            // Check cache first
            if let cachedPlayer = cache.getCachedPlayer(for: video.id) {
                await MainActor.run {
                    self.player = cachedPlayer
                    self.isLoading = false
                }
                
                // Add end notification observer
                NotificationCenter.default.addObserver(
                    self,
                    selector: #selector(videoDidFinish),
                    name: .AVPlayerItemDidPlayToEndTime,
                    object: cachedPlayer.currentItem
                )
                
                // Start playback immediately for cached player
                await cachedPlayer.seek(to: .zero)
                cachedPlayer.play()
                return
            }
            
            // Get fresh URL and create player
            let url = try await video.getVideoURL()
            let playerItem = AVPlayerItem(url: url)
            let player = AVPlayer(playerItem: playerItem)
            cache.cachePlayer(id: video.id, player: player)
            
            // Add end notification observer
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(videoDidFinish),
                name: .AVPlayerItemDidPlayToEndTime,
                object: playerItem
            )
            
            await MainActor.run {
                self.player = player
                self.isLoading = false
            }
            
            // Start playback immediately for new player
            player.play()
            
        } catch {
            print("Error loading video:", error)
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
    
    func startPlayback() {
        player?.seek(to: .zero) // Reset to start
        player?.play()
    }
    
    func stopPlayback() {
        player?.pause()
    }
    
    @MainActor
    func toggleLike() {
        isLiked.toggle()
        Task {
            do {
                let db = Firestore.firestore()
                try await db.collection(Video.collectionName)
                    .document(video.id)
                    .updateData([
                        "stats.likes": FieldValue.increment(Int64(isLiked ? 1 : -1))
                    ] as [String: Any])
            } catch {
                print("Error updating like:", error)
                isLiked.toggle()
            }
        }
    }
    
    @MainActor
    func incrementViews() {
        Task {
            do {
                let db = Firestore.firestore()
                try await db.collection(Video.collectionName)
                    .document(video.id)
                    .updateData([
                        "stats.views": FieldValue.increment(Int64(1))
                    ] as [String: Any])
            } catch {
                print("Error incrementing views:", error)
            }
        }
    }
    
    func showComments() {
        // Implement comments functionality
    }
    
    func shareVideo() {
        // Implement share functionality
    }
}