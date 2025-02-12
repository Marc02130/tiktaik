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
    @StateObject private var viewModel: FeedViewModel
    @State private var currentIndex = 0
    @Environment(\.userProfile) private var userProfile: UserProfile?
    private let metrics = FeedMetricsService()
    @State private var showTagSelection = false
    @Namespace private var scrollSpace
    @State private var scrollProxy: ScrollViewProxy?
    @State private var observer: NSObjectProtocol? = nil
    
    init() {
        // Create the view model on the main actor
        let viewModel = FeedViewModel()
        self._viewModel = StateObject(wrappedValue: viewModel)
    }
    
    // Optional initializer for testing/previews
    init(viewModel: FeedViewModel) {
        self._viewModel = StateObject(wrappedValue: viewModel)
    }
    
    var body: some View {
        GeometryReader { geometry in
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack {
                        ForEach(Array(viewModel.videos.enumerated()), id: \.element.id) { index, video in
                            VideoPlayerView(
                                video: video,
                                isVisible: currentIndex == index,
                                onPlaybackStatusChanged: { status in
                                    handlePlaybackStatus(status, forIndex: index)
                                }
                            )
                        }
                    }
                }
                .onChange(of: currentIndex) { newIndex in
                    scrollToVideo(at: newIndex, proxy: proxy)
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
            setupAdvanceObserver()
        }
        .onDisappear {
            if let observer = observer {
                NotificationCenter.default.removeObserver(observer)
            }
        }
    }
    
    private func handlePlaybackStatus(_ status: PlaybackStatus, forIndex index: Int) {
        switch status {
        case .finished:
            advanceToNextVideo(from: index)
        case .failed(let error):
            handlePlaybackError(error, at: index)
        case .idle, .loading, .ready, .playing, .paused:
            break // Other states don't require feed-level handling
        }
    }
    
    private func advanceToNextVideo(from index: Int) {
        guard index < viewModel.videos.count - 1 else { return }
        withAnimation {
            currentIndex = index + 1
        }
    }
    
    private func handlePlaybackError(_ error: Error, at index: Int) {
        // Handle playback error
        print("DEBUG: Playback error: \(error)")
    }
    
    private func scrollToVideo(at index: Int, proxy: ScrollViewProxy) {
        if let videoId = viewModel.videos[safe: index]?.id {
            withAnimation {
                proxy.scrollTo(videoId, anchor: .center)
            }
        }
    }
    
    private func setupAdvanceObserver() {
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
}

#Preview {
    FeedView()
} 