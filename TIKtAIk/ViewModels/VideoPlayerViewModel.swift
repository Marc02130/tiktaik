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
    
    @Published private(set) var showSubtitles: Bool = true
    
    private var isPreloading = false
    private var loadTask: Task<Void, Never>?
    
    init(video: Video, cache: VideoCache = .shared) {
        print("DEBUG: Initializing VideoPlayerViewModel for \(video.id)")
        self.video = video
        self.videoCache = cache
        self.stats = VideoStats(
            likes: video.stats.likes,
            commentsCount: video.stats.commentsCount,
            shares: video.stats.shares,
            views: video.stats.views
        )
        
        // Remove automatic load in init
        // Let the view request load when needed
        
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
        
        // Add notification observer for video completion
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(videoDidFinish),
            name: .AVPlayerItemDidPlayToEndTime,
            object: nil  // We'll get notifications for any player item
        )
        
        // Load user settings
        Task {
            if let settings = try? await Firestore.firestore()
                .collection("users")
                .document(video.userId)
                .getDocument()
                .data()?["settings"] as? [String: Any],
               let showSubtitles = settings["showSubtitles"] as? Bool {
                self.showSubtitles = showSubtitles
            }
        }
        
        print("DEBUG: VideoPlayerViewModel initialized for \(video.id)")
    }
    
    @objc private func videoDidFinish() {
        print("DEBUG: Video finished playing")
        playbackStatus = .finished  // This triggers the chain of events
    }
    
    /// Preloads video without starting playback
    func preloadVideo() async {
        guard !isPreloading else {
            print("DEBUG: Already preloading video \(video.id)")
            return
        }
        
        isPreloading = true
        await loadVideo()
        isPreloading = false
    }
    
    // Make seek async since it can fail
    func seekToZero() async {
        let time = CMTime.zero
        await player?.seek(to: time, toleranceBefore: .zero, toleranceAfter: .zero)
    }
    
    /// Loads video from Firebase Storage
    /// - Parameter video: Video to load
    func loadVideo() async {
        // Cancel any existing load
        loadTask?.cancel()
        
        // Create new load task
        loadTask = Task {
            guard !isLoading else {
                print("DEBUG: Skipping load - already loading video \(video.id)")
                return
            }
            
            print("DEBUG: [PLAYER] Starting to load video \(video.id)")
            isLoading = true
            updatePlaybackState(.loading)
            
            do {
                print("DEBUG: [PLAYER] About to call getVideoURL for \(video.id)")
                let url = try await video.getVideoURL()
                print("DEBUG: [PLAYER] Got URL: \(url)")
                
                // Check cache first
                if let cachedPlayer = videoCache.getCachedPlayer(for: video.id) {
                    print("DEBUG: [CACHE] Using cached player for \(video.id)")
                    await MainActor.run {
                        self.player = cachedPlayer
                        self.playbackStatus = .ready
                    }
                    return
                }
                
                // Create player
                print("DEBUG: [PLAYER] Creating new player for video: \(video.id)")
                let asset = AVURLAsset(url: url)
                let playerItem = AVPlayerItem(asset: asset)
                let newPlayer = AVPlayer(playerItem: playerItem)
                
                // Update playback settings to reduce stalls
                newPlayer.automaticallyWaitsToMinimizeStalling = true
                playerItem.preferredForwardBufferDuration = 5.0  // Buffer 5 seconds ahead
                playerItem.preferredMaximumResolution = .init(width: 640, height: 1136)
                
                // Cache player
                videoCache.cachePlayer(id: video.id, player: newPlayer)
                
                // Update state
                self.playerItem = playerItem
                self.player = newPlayer
                self.isLoading = false
                
                print("DEBUG: [PLAYER] Player setup complete for video: \(video.id)")
                updatePlaybackState(.ready)
                
            } catch {
                print("ERROR: [PLAYER] Failed to load: \(error)")
                self.error = error.localizedDescription
                self.isLoading = false
                updatePlaybackState(.failed(error))
            }
        }
        
        await loadTask?.value
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
        print("DEBUG: startPlayback called, player=\(player != nil), status=\(playbackStatus)")
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
        print("DEBUG: Setting up time observer")
        let interval = CMTime(seconds: 0.5, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        timeObserverToken = player?.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            self?.currentTime = time.seconds
        }
        
        // Add notification observer for video completion
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(playerDidFinishPlaying),
            name: .AVPlayerItemDidPlayToEndTime,
            object: player?.currentItem
        )
    }
    
    @objc private func playerDidFinishPlaying() {
        playbackStatus = .finished  // This will trigger the onChange in VideoPlayerView
    }
    
    func pausePlayback() {
        print("DEBUG: pausePlayback called")
        player?.pause()
        playbackStatus = .paused
    }
    
    func updateShowSubtitles(_ show: Bool) {
        showSubtitles = show
    }
    
    @MainActor
    func loadVideo(from url: URL) async {
        print("DEBUG: Starting to load video from URL: \(url) for \(video.id)")
        isLoading = true
        defer { isLoading = false }
        
        do {
            print("DEBUG: Creating AVAsset for \(video.id)")
            let asset = AVAsset(url: url)
            
            print("DEBUG: Creating AVPlayerItem for \(video.id)")
            let playerItem = AVPlayerItem(asset: asset)
            
            print("DEBUG: Creating AVPlayer for \(video.id)")
            player = AVPlayer(playerItem: playerItem)
            player?.automaticallyWaitsToMinimizeStalling = false
            
            print("DEBUG: Setting up time observer for \(video.id)")
            setupTimeObserver()
            
            print("DEBUG: Video ready for playback: \(video.id)")
            playbackStatus = .ready
        } catch {
            print("ERROR: Failed to load video \(video.id): \(error)")
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