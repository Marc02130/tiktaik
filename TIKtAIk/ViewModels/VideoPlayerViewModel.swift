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
    private let video: Video
    
    init(video: Video) {
        self.video = video
        self.likes = video.stats.likes
        self.comments = video.stats.commentsCount
        self.shares = video.stats.shares
        
        if let url = URL(string: video.storageUrl) {
            self.player = AVPlayer(url: url)
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(videoDidFinish),
                name: .AVPlayerItemDidPlayToEndTime,
                object: player?.currentItem
            )
        }
        
        // Fix actor isolation with @MainActor.run
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
    
    func startPlayback() {
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