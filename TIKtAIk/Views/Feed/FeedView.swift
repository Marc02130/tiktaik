//
// FeedView.swift
// TIKtAIk
//
// Created: 2024-02-14
// Last modified: 2024-02-14
//
// Purpose: Main feed view showing video content
// Author: Assistant
// Copyright © 2024 TIKtAIk. All rights reserved.
//

import SwiftUI

struct FeedView: View {
    @StateObject private var viewModel = FeedViewModel()
    @State private var currentIndex = 0
    private let metrics = FeedMetricsService()
    @State private var showTagSelector = false
    
    var body: some View {
        VStack {
            // Feed type selector
            HStack {
                Button {
                    viewModel.config.followingOnly.toggle()
                    if viewModel.config.followingOnly {
                        viewModel.config.isCreatorOnly = false
                    }
                    viewModel.updateFeedType()
                } label: {
                    Text("Following")
                        .font(.headline)
                        .foregroundStyle(viewModel.config.followingOnly ? .primary : .secondary)
                }
                
                Button {
                    viewModel.config.isCreatorOnly.toggle()
                    if viewModel.config.isCreatorOnly {
                        viewModel.config.followingOnly = false
                    }
                    viewModel.updateFeedType()
                } label: {
                    Text("Creator")
                        .font(.headline)
                        .foregroundStyle(viewModel.config.isCreatorOnly ? .primary : .secondary)
                }
                
                Button {
                    showTagSelector = true
                } label: {
                    Image(systemName: "tag")
                        .font(.headline)
                        .foregroundStyle(viewModel.config.selectedTags.isEmpty ? .secondary : .primary)
                }
            }
            .padding()
            
            if case .loading = viewModel.state {
                ProgressView()
            } else if case .error(let error) = viewModel.state {
                Text(error)
                    .foregroundStyle(.red)
            } else if case .loaded(let videos) = viewModel.state {
                TabView(selection: $currentIndex) {
                    ForEach(Array(videos.enumerated()), id: \.element.id) { index, video in
                        VideoPlayerView(video: video)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
            }
        }
        .task {
            if case .idle = viewModel.state {
                metrics.startTiming("initial_load")
                await viewModel.loadInitialFeed()
                if let duration = metrics.endTiming("initial_load") {
                    try? await metrics.recordLoadTime(duration, feedType: viewModel.config.feedType)
                }
            }
        }
        .onChange(of: currentIndex) { oldValue, newValue in
            if case .loaded(let videos) = viewModel.state,
               newValue >= videos.count - 2 {
                Task {
                    await viewModel.loadMore()
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .advanceToNextVideo)) { _ in
            if case .loaded(let videos) = viewModel.state,
               currentIndex < videos.count - 1 {
                withAnimation {
                    currentIndex += 1
                }
            }
        }
        .sheet(isPresented: $showTagSelector) {
            TagSelectorView(selectedTags: $viewModel.config.selectedTags)
        }
    }
}

struct TagSelectorView: View {
    @Binding var selectedTags: Set<String>
    @Environment(\.dismiss) private var dismiss
    
    let popularTags = [
        "comedy", "music", "dance", "food", "travel",
        "sports", "gaming", "fashion", "beauty", "pets"
    ]
    
    var body: some View {
        NavigationStack {
            List(popularTags, id: \.self) { tag in
                Button {
                    if selectedTags.contains(tag) {
                        selectedTags.remove(tag)
                    } else {
                        selectedTags.insert(tag)
                    }
                } label: {
                    HStack {
                        Text("#\(tag)")
                        Spacer()
                        if selectedTags.contains(tag) {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
            .navigationTitle("Select Tags")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Clear") {
                        selectedTags.removeAll()
                    }
                    .disabled(selectedTags.isEmpty)
                }
            }
        }
    }
}

#Preview {
    FeedView()
} 