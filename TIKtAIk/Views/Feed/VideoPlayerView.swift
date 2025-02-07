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

// Define notification name using NSNotification.Name
extension NSNotification.Name {
    static let advanceToNextVideo = NSNotification.Name("AdvanceToNextVideo")
}

struct VideoPlayerView: View {
    @StateObject private var viewModel = VideoPlayerViewModel()
    let video: Video
    @State private var isMuted = true
    @Environment(\.verticalSizeClass) var verticalSizeClass
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Video Player
                if let player = viewModel.player {
                    VideoPlayer(player: player)
                        .edgesIgnoringSafeArea(.all)
                        .frame(
                            width: geometry.size.height,
                            height: geometry.size.width
                        )
                        .position(
                            x: geometry.size.width / 2,
                            y: geometry.size.height / 2
                        )
                        .onAppear {
                            player.isMuted = isMuted
                            player.play()
                            
                            // Add observer for video completion
                            NotificationCenter.default.addObserver(
                                forName: .AVPlayerItemDidPlayToEndTime,
                                object: player.currentItem,
                                queue: .main
                            ) { _ in
                                NotificationCenter.default.post(
                                    name: .advanceToNextVideo,
                                    object: nil
                                )
                            }
                        }
                } else {
                    // Loading placeholder
                    Color.black
                        .overlay {
                            ProgressView()
                                .tint(.white)
                        }
                }
                
                // Video Controls - Match video rotation
                VStack {
                    Spacer()
                    HStack {
                        videoInfo
                        Spacer()
                        videoControls
                    }
                    .padding()
                }
                .rotationEffect(.degrees(-90))  // Match video rotation
                .frame(
                    width: geometry.size.height,
                    height: geometry.size.width
                )
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .accessibilityElement(children: .contain)
        .onTapGesture {
            isMuted.toggle()
            viewModel.player?.isMuted = isMuted
        }
        .task {
            await viewModel.loadVideo(video)
        }
        .onDisappear {
            viewModel.cleanup()
        }
    }
    
    private var videoInfo: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(video.title)
                .font(.headline)
                .foregroundStyle(.white)
                .shadow(radius: 2)
            
            if let description = video.description {
                Text(description)
                    .font(.subheadline)
                    .foregroundStyle(.white)
                    .shadow(radius: 2)
            }
            
            HStack {
                ForEach(Array(video.tags.prefix(3)), id: \.self) { tag in
                    Text("#\(tag)")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.8))
                        .shadow(radius: 2)
                }
            }
        }
    }
    
    private var videoControls: some View {
        VStack(spacing: 16) {
            Button {
                isMuted.toggle()
                viewModel.player?.isMuted = isMuted
            } label: {
                Image(systemName: isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill")
                    .font(.title2)
                    .foregroundStyle(.white)
                    .shadow(radius: 2)
            }
        }
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