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
class VideoPlayerViewModel: ObservableObject {
    /// Current video player instance
    @Published private(set) var player: AVPlayer?
    /// Current error message if any
    @Published private(set) var error: String?
    /// Loading state
    @Published private(set) var isLoading = false
    
    @Published private(set) var playbackStatus: PlaybackStatus = .idle
    @Published private(set) var currentTime: TimeInterval = 0
    
    // Video metadata
    @Published private(set) var creatorUsername: String = ""
    @Published private(set) var stats: VideoStats = .empty
    
    private let video: Video
    private let videoCache: VideoCache
    
    private var playerItem: AVPlayerItem?
    private var timeObserverToken: Any?
    
    @Published private(set) var showSubtitles: Bool = false
    
    init(video: Video, cache: VideoCache = .shared) {
        self.video = video
        self.videoCache = cache
        self.stats = VideoStats(
            likes: video.stats.likes,
            commentsCount: video.stats.commentsCount,
            shares: video.stats.shares,
            views: video.stats.views
        )
        
        // Start loading video immediately
        Task {
            await loadVideo() // Remove try since loadVideo handles errors internally
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
            if videoCache.getCachedPlayer(for: video.id) != nil {
                // Already cached, nothing to do
                return
            }
            
            // Get fresh URL and create player
            let url = try await video.getVideoURL()
            let playerItem = AVPlayerItem(url: url)
            let player = AVPlayer(playerItem: playerItem)
            
            // Cache the player for later use
            videoCache.cachePlayer(id: video.id, player: player)
            
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
    
    // Make seek async since it can fail
    func seekToZero() async {
        let time = CMTime.zero
        await player?.seek(to: time, toleranceBefore: .zero, toleranceAfter: .zero)
    }
    
    /// Loads video from Firebase Storage
    /// - Parameter video: Video to load
    func loadVideo() async {
        guard !isLoading else { return }
        isLoading = true
        updatePlaybackState(.loading)
        
        do {
            print("DEBUG: Starting to load video: \(video.id)")
            error = nil
            
            // Check cache first
            if let cachedPlayer = videoCache.getCachedPlayer(for: video.id) {
                print("DEBUG: Using cached player for video: \(video.id)")
                self.player = cachedPlayer
                self.isLoading = false
                
                // Reset item
                let currentItem = cachedPlayer.currentItem
                cachedPlayer.replaceCurrentItem(with: nil)
                cachedPlayer.replaceCurrentItem(with: currentItem)
                
                // Add observer
                NotificationCenter.default.addObserver(
                    self,
                    selector: #selector(videoDidFinish),
                    name: .AVPlayerItemDidPlayToEndTime,
                    object: currentItem
                )
                
                // Prepare for playback
                await seekToZero() // Make seek async
                print("DEBUG: Cached player ready for video: \(video.id)")
                updatePlaybackState(.ready)
                return
            }
            
            // Get URL in background
            print("DEBUG: Getting video URL for: \(video.id)")
            let url = try await video.getVideoURL()
            print("DEBUG: Got video URL: \(url)")
            
            // Create player on main thread
            let asset = AVURLAsset(url: url)
            let playerItem = AVPlayerItem(asset: asset)
            let newPlayer = AVPlayer(playerItem: playerItem)
            
            // Set up player
            newPlayer.automaticallyWaitsToMinimizeStalling = true
            
            // Cache player
            videoCache.cachePlayer(id: video.id, player: newPlayer)
            print("DEBUG: Created and cached new player for video: \(video.id)")
            
            // Add observer
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(videoDidFinish),
                name: .AVPlayerItemDidPlayToEndTime,
                object: playerItem
            )
            
            // Update state
            self.playerItem = playerItem
            self.player = newPlayer
            self.isLoading = false
            
            print("DEBUG: New player ready for video: \(video.id)")
            
            updatePlaybackState(.ready)
        } catch {
            print("ERROR: Failed to load video \(video.id): \(error)")
            self.error = error.localizedDescription
            self.isLoading = false
            updatePlaybackState(.failed(error))
        }
    }
    
    /// Cleanup resources
    func cleanup() {
        print("DEBUG: Cleaning up video: \(video.id)")
        stopPlayback()
        player?.replaceCurrentItem(with: nil)
        player = nil
        playerItem = nil
        playbackStatus = .idle
    }
    
    func startPlayback() {
        guard case .ready = playbackStatus else { return }
        player?.play()
        playbackStatus = .playing
    }
    
    private func loadAndPlay() {
        Task {
            playbackStatus = .loading
            do {
                await loadVideo()  // Remove try since loadVideo handles errors internally
                player?.play()
                playbackStatus = .playing
            } catch {
                playbackStatus = .failed(error)
            }
        }
    }
    
    func stopPlayback() {
        print("DEBUG: Stopping playback for video: \(video.id)")
        player?.pause()
        player?.seek(to: .zero)
        
        // Remove time observer
        if let token = timeObserverToken {
            player?.removeTimeObserver(token)
            timeObserverToken = nil
        }
    }
    
    func updatePlaybackState(_ newState: PlaybackStatus) {
        Task { @MainActor in
            playbackStatus = newState
            
            // Log state changes
            print("DEBUG: Video \(video.id) playback state changed to: \(newState)")
        }
    }
    
    private func setupTimeObserver() {
        // Move time observation logic here
    }
    
    func pausePlayback() {
        player?.pause()
        playbackStatus = .paused
    }
    
    func updateShowSubtitles(_ show: Bool) {
        showSubtitles = show
    }
    
    @MainActor
    func loadVideo(from url: URL) async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let asset = AVAsset(url: url)
            let playerItem = AVPlayerItem(asset: asset)
            player = AVPlayer(playerItem: playerItem)
            player?.automaticallyWaitsToMinimizeStalling = false
            setupTimeObserver()
            playbackStatus = .ready
        } catch {
            print("Error loading video:", error)
            playbackStatus = .failed(error)
        }
    }
}

enum PlaybackStatus: Equatable {
    case idle
    case loading
    case ready
    case playing
    case paused
    case finished
    case failed(Error)
    
    static func == (lhs: PlaybackStatus, rhs: PlaybackStatus) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle),
             (.loading, .loading),
             (.ready, .ready),
             (.playing, .playing),
             (.finished, .finished):
            return true
        case (.failed(let lhsError), .failed(let rhsError)):
            return lhsError.localizedDescription == rhsError.localizedDescription
        default:
            return false
        }
    }
}