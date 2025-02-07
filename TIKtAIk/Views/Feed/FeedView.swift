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

extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

struct FeedView: View {
    @StateObject private var viewModel = FeedViewModel()
    @State private var currentIndex = 0
    @Environment(\.userProfile) private var userProfile: UserProfile?
    private let metrics = FeedMetricsService()
    @State private var showTagSelection = false
    @Namespace private var scrollSpace
    @State private var scrollProxy: ScrollViewProxy?
    @State private var observer: NSObjectProtocol? = nil
    
    var body: some View {
        VStack(spacing: 0) {
            // Tag selector only
            HStack {
                Spacer()
                Button {
                    showTagSelection = true
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
                GeometryReader { geometry in
                    ScrollViewReader { proxy in
                        ScrollView(.vertical, showsIndicators: false) {
                            LazyVStack(spacing: 0) {
                                ForEach(Array(videos.enumerated()), id: \.element.id) { index, video in
                                    VideoPlayerView(video: video)
                                        .frame(width: geometry.size.width, height: geometry.size.height)
                                        .id(video.id)
                                }
                            }
                        }
                        .scrollTargetBehavior(.paging)
                        .scrollTargetLayout()
                        .scrollPosition(id: Binding(
                            get: { videos[safe: currentIndex]?.id },
                            set: { newId in
                                if let index = videos.firstIndex(where: { $0.id == newId }) {
                                    currentIndex = index
                                }
                            }
                        ))
                        .onAppear {
                            scrollProxy = proxy
                        }
                        .onChange(of: currentIndex) { _, newIndex in
                            if case .loaded(let videos) = viewModel.state {
                                Task { @MainActor in
                                    // Wait for any pending state updates
                                    try? await Task.sleep(nanoseconds: 100_000_000)
                                    
                                    if let videoId = videos[safe: newIndex]?.id {
                                        withAnimation {
                                            proxy.scrollTo(videoId, anchor: .center)
                                        }
                                    }
                                }
                            }
                        }
                        .ignoresSafeArea()
                    }
                }
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
        .onChange(of: userProfile?.isCreator) { _, isCreator in
            viewModel.config.isCreatorOnly = isCreator ?? false
            Task {
                try? await viewModel.updateFeedType()
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
        .sheet(isPresented: $showTagSelection) {
            TagSelectionView(selectedTags: $viewModel.config.selectedTags)
        }
        .onAppear {
            observer = NotificationCenter.default.addObserver(
                forName: .advanceToNextVideo,
                object: nil,
                queue: .main
            ) { [weak viewModel] _ in
                print("DEBUG: Advance notification received in FeedView")
                guard let viewModel = viewModel else {
                    print("DEBUG: ViewModel is nil")
                    return
                }
                
                Task { @MainActor in
                    print("DEBUG: Checking state for advancement")
                    if case .loaded(let videos) = viewModel.state {
                        print("DEBUG: Videos loaded, count:", videos.count)
                        print("DEBUG: Current index:", currentIndex)
                        
                        if currentIndex >= videos.count - 1 {
                            print("DEBUG: At last video, can't advance")
                            return
                        }
                        
                        // Just advance to next video
                        withAnimation {
                            currentIndex += 1
                            print("DEBUG: Advanced to index:", currentIndex)
                            if let videoId = videos[safe: currentIndex]?.id,
                               let proxy = scrollProxy {
                                print("DEBUG: Scrolling to video:", videoId)
                                proxy.scrollTo(videoId, anchor: .center)
                            } else {
                                print("DEBUG: Failed to scroll - videoId or proxy missing")
                            }
                        }
                    } else {
                        print("DEBUG: Invalid state for advancement:", viewModel.state)
                    }
                }
            }
        }
        .onDisappear {
            if let observer = observer {
                NotificationCenter.default.removeObserver(observer)
            }
        }
    }
}

#Preview {
    FeedView()
} 