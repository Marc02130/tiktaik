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
}

struct VideoPlayerView: View {
    let video: Video
    let isVisible: Bool
    let onPlaybackStatusChanged: (PlaybackStatus) -> Void
    
    @StateObject private var viewModel: VideoPlayerViewModel
    @StateObject private var statsViewModel: VideoStatsViewModel
    @StateObject private var subtitleViewModel: VideoSubtitleViewModel
    @AppStorage("showSubtitles") private var showSubtitles = true
    
    init(video: Video, isVisible: Bool, onPlaybackStatusChanged: @escaping (PlaybackStatus) -> Void) {
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
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                if let player = viewModel.player {
                    VideoPlayer(player: player)
                        .onAppear {
                            // Start playback when view appears if visible
                            if isVisible {
                                viewModel.startPlayback()
                            }
                        }
                } else {
                    // Show loading state
                    ProgressView()
                }
                
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
                    onComment: statsViewModel.showComments,
                    onShare: statsViewModel.shareVideo
                )
            }
        }
        .onChange(of: isVisible) { oldValue, newValue in
            if newValue {
                viewModel.startPlayback()
                if !oldValue {
                    statsViewModel.incrementViews()
                }
            } else {
                viewModel.pausePlayback()
            }
        }
        .onChange(of: viewModel.playbackStatus) { status in
            onPlaybackStatusChanged(status)
        }
        .task {
            // Load video URL and initialize player
            do {
                let videoURL = try await video.getVideoURL()
                await viewModel.loadVideo(from: videoURL)
                await subtitleViewModel.updateVideoURL(videoURL)
            } catch {
                print("Error loading video:", error)
            }
        }
    }
    
    private var shouldShowSubtitles: Bool {
        showSubtitles && !subtitleViewModel.subtitles.isEmpty
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