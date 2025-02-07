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
    @StateObject private var viewModel: VideoPlayerViewModel
    @State private var creatorUsername: String = ""
    
    init(video: Video) {
        self.video = video
        self._viewModel = StateObject(wrappedValue: VideoPlayerViewModel(video: video))
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Video Player
                VideoPlayer(player: viewModel.player)
                    .edgesIgnoringSafeArea(.all)
                    .frame(width: geometry.size.width, height: geometry.size.height)
                
                // Overlay Controls
                VStack {
                    Spacer()
                    
                    // Video Info
                    HStack(alignment: .bottom) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(video.title)
                                .font(.headline)
                            Text(creatorUsername.isEmpty ? "@\(video.userId)" : "@\(creatorUsername)")
                                .font(.subheadline)
                        }
                        .foregroundColor(.white)
                        .shadow(radius: 2)
                        
                        Spacer()
                        
                        // Interaction Buttons
                        VStack(spacing: 16) {
                            InteractionButton(
                                icon: "heart.fill",
                                count: viewModel.likes,
                                isActive: viewModel.isLiked,
                                action: viewModel.toggleLike
                            )
                            
                            InteractionButton(
                                icon: "message.fill",
                                count: viewModel.comments,
                                action: viewModel.showComments
                            )
                            
                            InteractionButton(
                                icon: "square.and.arrow.up.fill",
                                count: viewModel.shares,
                                action: viewModel.shareVideo
                            )
                        }
                    }
                    .padding()
                }
            }
            .onAppear {
                print("DEBUG: VideoPlayerView appeared for video:", video.id)
                viewModel.startPlayback()
                viewModel.incrementViews()
                fetchUsername()
            }
            .onDisappear {
                viewModel.stopPlayback()
            }
        }
        .aspectRatio(9/16, contentMode: .fit)
    }
    
    private func fetchUsername() {
        Task {
            do {
                let doc = try await Firestore.firestore()
                    .collection("users")
                    .document(video.userId)
                    .getDocument()
                creatorUsername = doc.get("username") as? String ?? ""
            } catch {
                print("Error fetching username:", error)
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