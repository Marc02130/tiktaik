//
// VideoLibraryView.swift
// TIKtAIk
//
// Created: 2024-02-14
// Last modified: 2024-02-14
//
// Purpose: View for displaying user's video library
// Author: Assistant
// Copyright © 2024 TIKtAIk. All rights reserved.
//

// Framework: SwiftUI - UI Framework
import SwiftUI

/// View for displaying and managing user's video library
///
/// Features:
/// - Grid layout of video thumbnails
/// - Video metadata preview
/// - Navigation to video editing
/// - Pull to refresh
struct VideoLibraryView: View {
    /// View model managing library operations
    @StateObject private var viewModel = VideoLibraryViewModel()
    @State private var refreshTrigger = RefreshTrigger()
    
    /// Grid layout configuration
    private let columns = [
        GridItem(.adaptive(minimum: 150, maximum: 200), spacing: 12)
    ]
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(viewModel.videos) { video in
                    VideoThumbnailView(video: video)
                        .onTapGesture {
                            viewModel.selectedVideo = video
                        }
                }
            }
            .padding()
        }
        .navigationTitle("My Videos")
        .refreshable {
            await viewModel.loadVideos()
        }
        .sheet(item: $viewModel.selectedVideo) { video in
            VideoEditView(videoId: video.id, refreshTrigger: refreshTrigger)
                .environmentObject(viewModel)
        }
        .task {
            await viewModel.loadVideos()
        }
        .onChange(of: refreshTrigger.shouldRefresh) { _, shouldRefresh in
            if shouldRefresh {
                Task {
                    await viewModel.loadVideos()
                    refreshTrigger.refreshCompleted()
                }
            }
        }
    }
}

/// View for displaying video thumbnail and metadata
private struct VideoThumbnailView: View {
    let video: Video
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Thumbnail container with fixed size
            AsyncImage(url: URL(string: video.thumbnailUrl ?? "")) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 150, height: 200)
                    .clipped()
            } placeholder: {
                Color.gray.opacity(0.2)
                    .frame(width: 150, height: 200)
            }
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(alignment: .topTrailing) {
                if video.isPrivate {
                    Image(systemName: "lock.fill")
                        .padding(8)
                        .foregroundStyle(.white)
                        .background(.ultraThinMaterial)
                        .clipShape(Circle())
                        .padding(8)
                }
            }
            
            // Metadata
            Text(video.title)
                .font(.headline)
                .lineLimit(1)
                .frame(maxWidth: 150, alignment: .leading)
            
            HStack {
                Label("\(video.stats.views)", systemImage: "eye.fill")
                Label("\(video.stats.likes)", systemImage: "heart.fill")
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
    }
} 