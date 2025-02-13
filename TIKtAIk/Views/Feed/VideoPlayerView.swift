//
// VideoPlayerView.swift
// TIKtAIk
//
// Created: 2024-02-14
// Last modified: 2024-02-14
//
// Purpose: Video player component for feed
// Author: Assistant
// Copyright © 2024 TIKtAIk. All rights reserved.
//

import SwiftUI
import AVKit
import Foundation
import FirebaseFirestore

// Define notification name using NSNotification.Name
extension NSNotification.Name {
    static let advanceToNextVideo = NSNotification.Name("AdvanceToNextVideo")
    static let stopVideo = NSNotification.Name("StopVideo")
    static let startVideo = NSNotification.Name("StartVideo")
}

struct VideoPlayerView: View {
    let video: Video
    let isVisible: Bool
    let onPlaybackStatusChanged: (PlaybackStatus) -> Void
    
    @StateObject private var viewModel: VideoPlayerViewModel
    @StateObject private var statsViewModel: VideoStatsViewModel
    @StateObject private var subtitleViewModel: VideoSubtitleViewModel
    @AppStorage("showSubtitles") private var showSubtitles = true
    @State private var showComments = false
    
    init(video: Video, isVisible: Bool, onPlaybackStatusChanged: @escaping (PlaybackStatus) -> Void) {
        print("DEBUG: Initializing VideoPlayerView for video \(video.id)")
        self.video = video
        self.isVisible = isVisible
        self.onPlaybackStatusChanged = onPlaybackStatusChanged
        
        // Initialize view models
        self._viewModel = StateObject(wrappedValue: VideoPlayerViewModel(video: video))
        self._statsViewModel = StateObject(wrappedValue: VideoStatsViewModel(video: video))
        self._subtitleViewModel = StateObject(wrappedValue: VideoSubtitleViewModel(
            videoId: video.id,
            videoURL: URL(string: "placeholder")!
        ))
        
        print("DEBUG: VideoPlayerView initialization complete for \(video.id)")
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                if let player = viewModel.player {
                    VideoPlayer(player: player)
                        .onAppear {
                            print("DEBUG: VideoPlayer appeared, isVisible=\(isVisible)")
                            if isVisible {
                                viewModel.startPlayback()
                            }
                        }
                } else {
                    ProgressView()
                        .debugLog("Loading indicator for \(video.id)")
                }
                
                // Controls and subtitles in front
                VStack {
                    if shouldShowSubtitles {
                        SubtitleOverlayView(
                            subtitles: subtitleViewModel.subtitles,
                            currentTime: viewModel.currentTime,
                            preferences: subtitleViewModel.preferences
                        )
                    }

                    VideoControlsOverlay(
                        video: video,
                        stats: statsViewModel.stats,
                        onLike: statsViewModel.toggleLike,
                        onComment: { showComments = true },
                        onShare: statsViewModel.shareVideo
                    )
                }
            }
        }
        .sheet(isPresented: $showComments) {
            CommentSheet(video: video)
                .onAppear { 
                    print("DEBUG: Comment sheet appearing")
                    viewModel.handleSheetPresented() 
                }
                .onDisappear { 
                    print("DEBUG: Comment sheet disappearing")
                    viewModel.handleSheetDismissed() 
                }
        }
        .onAppear {
            // Listen for start video notification
            NotificationCenter.default.addObserver(
                forName: .startVideo,
                object: nil,
                queue: .main
            ) { [video] notification in
                if let videoId = notification.userInfo?["videoId"] as? String,
                   videoId == video.id {
                    print("DEBUG: Received start notification for video \(video.id)")
                    if isVisible {
                        viewModel.startPlayback()
                    }
                }
            }
        }
        .onChange(of: isVisible) { _, newValue in
            print("DEBUG: Visibility changed to \(newValue) for video \(video.id)")
            if newValue {
                viewModel.startPlayback()
            } else {
                viewModel.pausePlayback()
            }
        }
        .onChange(of: viewModel.playbackStatus) { _, newStatus in
            onPlaybackStatusChanged(newStatus)
        }
        .task {
            // Load video immediately when view is created
            await loadVideo()
        }
        .debugVideoState(videoId: video.id, isVisible: isVisible)
    }
    
    private func loadVideo() async {
        print("DEBUG: Starting video load task for \(video.id)")
        do {
            let videoURL = try await video.getVideoURL()
            await viewModel.loadVideo(from: videoURL)
            await subtitleViewModel.updateVideoURL(videoURL)
        } catch {
            print("ERROR: Failed to load video \(video.id): \(error)")
        }
    }
    
    private var shouldShowSubtitles: Bool {
        return viewModel.showSubtitles && !subtitleViewModel.subtitles.isEmpty
    }
}

// Custom view modifier for debugging
private struct DebugLogModifier: ViewModifier {
    let message: String
    let isVisible: Bool?
    
    func body(content: Content) -> some View {
        content
            .onAppear {
                if let isVisible = isVisible {
                    print("DEBUG: \(message), isVisible: \(isVisible)")
                } else {
                    print("DEBUG: \(message) appeared")
                }
            }
            .onDisappear {
                print("DEBUG: \(message) disappeared")
            }
    }
}

// Custom view modifier for video state debugging
private struct VideoStateModifier: ViewModifier {
    let videoId: String
    let isVisible: Bool
    
    func body(content: Content) -> some View {
        content
            .onAppear {
                print("DEBUG: VideoPlayerView appeared for \(videoId)")
            }
            .onDisappear {
                print("DEBUG: VideoPlayerView disappeared for \(videoId)")
            }
            .onChange(of: isVisible) { oldValue, newValue in
                print("DEBUG: Visibility changed for video \(videoId) from \(oldValue) to \(newValue)")
            }
    }
}

// Helper extensions
extension View {
    func debugLog(_ message: String, isVisible: Bool? = nil) -> some View {
        modifier(DebugLogModifier(message: message, isVisible: isVisible))
    }
    
    func debugVideoState(videoId: String, isVisible: Bool) -> some View {
        modifier(VideoStateModifier(videoId: videoId, isVisible: isVisible))
    }
}

// Helper extension for conditional modifiers
extension View {
    @ViewBuilder
    func `if`<Transform: View>(
        _ condition: Bool,
        transform: (Self) -> Transform
    ) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
} 