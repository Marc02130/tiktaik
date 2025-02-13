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

struct VideoListView: View {
    let videos: [Video]
    let currentIndex: Int
    let onPlaybackStatus: (PlaybackStatus, Int) -> Void
    let onScrollPositionChanged: (String) -> Void
    @State private var scrollPosition: String?
    
    var body: some View {
        GeometryReader { geometry in
            ScrollView(.vertical, showsIndicators: false) {
                LazyVStack(spacing: 0) {
                    ForEach(Array(videos.enumerated()), id: \.element.id) { index, video in
                        VideoPlayerView(
                            video: video,
                            isVisible: currentIndex == index,
                            onPlaybackStatusChanged: { status in
                                onPlaybackStatus(status, index)
                            }
                        )
                        .id(video.id)
                        .frame(width: geometry.size.width, height: geometry.size.height)
                    }
                }
            }
            .scrollTargetBehavior(.paging)
            .scrollPosition(id: $scrollPosition)
            .onChange(of: scrollPosition) { _, newPosition in
                if let newPosition {
                    onScrollPositionChanged(newPosition)
                }
            }
        }
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
    @State private var isScrolling = false
    @State private var pendingIndex: Int?
    
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
        ScrollViewReader { proxy in
            VideoListView(
                videos: viewModel.videos,
                currentIndex: currentIndex,
                onPlaybackStatus: { status, index in
                    handlePlaybackStatus(status, at: index)
                },
                onScrollPositionChanged: { videoId in
                    handleScrollPositionChanged(videoId)
                }
            )
            .onAppear {
                scrollProxy = proxy
            }
            .ignoresSafeArea(.all)
            .edgesIgnoringSafeArea(.all)
        }
        .onChange(of: currentIndex) { oldValue, newValue in
            if let proxy = scrollProxy {
                withAnimation {
                    proxy.scrollTo(viewModel.videos[newValue].id, anchor: .center)
                }
            }
        }
        .task {
            print("DEBUG: FeedView task started")
            if case .idle = viewModel.state {
                print("DEBUG: Starting initial feed load")
                metrics.startTiming("initial_load")
                await viewModel.loadInitialFeed()
                if let duration = metrics.endTiming("initial_load") {
                    do {
                        try await metrics.recordLoadTime(duration, feedType: viewModel.config.feedType)
                    } catch {
                        print("DEBUG: Failed to record metrics:", error)
                    }
                }
            }
        }
        .onChange(of: userProfile?.isCreator) { _, isCreator in
            print("DEBUG: Creator status changed to: \(String(describing: isCreator))")
            viewModel.config.isCreatorOnly = isCreator ?? false
            Task {
                    try await viewModel.updateFeedType()
            }
        }
        .onChange(of: viewModel.state) { oldState, newState in
            print("DEBUG: Feed state changed from \(oldState) to \(newState)")
            switch newState {
            case .loaded(let videos):
                print("DEBUG: Feed loaded with \(videos.count) videos")
            case .error(let error):
                print("DEBUG: Feed error: \(error)")
            default:
                break
            }
        }
        .onChange(of: currentIndex) { oldValue, newValue in
            print("DEBUG: Checking if need to load more videos at index \(newValue)")
            if case .loaded(let videos) = viewModel.state,
               newValue >= videos.count - 2 {
                print("DEBUG: Loading more videos")
                Task {
                    await viewModel.loadMore()
                }
            }
        }
        .sheet(isPresented: $showTagSelection) {
            TagSelectionView(selectedTags: $viewModel.config.selectedTags)
        }
        .onAppear {
            print("DEBUG: FeedView appeared")
            setupAdvanceObserver()
        }
        .onDisappear {
            print("DEBUG: FeedView disappeared")
            if let observer = observer {
                NotificationCenter.default.removeObserver(observer)
            }
        }
        .onChange(of: viewModel.videos) { oldVideos, newVideos in
            print("DEBUG: [FEED] Videos array changed from \(oldVideos.count) to \(newVideos.count) videos")
        }
    }
    
    private func handlePlaybackStatus(_ status: PlaybackStatus, at index: Int) {
        if case .finished = status {
            print("DEBUG: Video finished at index \(index), advancing to next")
            // Only advance if this is the current video
            if index == currentIndex {
                advanceToNextVideo(from: index)
                // Load more videos when we're 2 videos away from the end
                if index >= viewModel.videos.count - 3 {
                    Task {
                        await viewModel.loadMore()
                    }
                }
            }
        }
    }
    
    private func handleScrollPositionChanged(_ videoId: String) {
        guard let newIndex = viewModel.videos.firstIndex(where: { video in video.id == videoId }) else {
            return
        }
        
        print("DEBUG: Scroll position changed to video \(videoId) at index \(newIndex)")
        
        // Update current index first
        currentIndex = newIndex
        
        // Then ensure the video starts playing
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            NotificationCenter.default.post(
                name: .startVideo,
                object: nil,
                userInfo: ["videoId": videoId]
            )
        }
    }
    
    private func advanceToNextVideo(from index: Int) {
        guard index < viewModel.videos.count - 1 else {
            print("DEBUG: At end of feed, waiting for more videos")
            return
        }
        
        let nextIndex = index + 1
        print("DEBUG: Advancing to index \(nextIndex)")
        
        withAnimation {
            currentIndex = nextIndex
            if let proxy = scrollProxy {
                proxy.scrollTo(viewModel.videos[nextIndex].id, anchor: .center)
                // Post notification after scroll
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    NotificationCenter.default.post(
                        name: .startVideo,
                        object: nil,
                        userInfo: ["videoId": viewModel.videos[nextIndex].id]
                    )
                }
            }
        }
    }
    
    private func handlePlaybackError(_ error: Error, at index: Int) {
        print("DEBUG: Handling error at index \(index): \(error)")
    }
    
    private func scrollToVideo(at index: Int, proxy: ScrollViewProxy) {
        print("DEBUG: Attempting to scroll to index \(index)")
        if let videoId = viewModel.videos[safe: index]?.id {
            print("DEBUG: Scrolling to video \(videoId)")
            withAnimation {
                proxy.scrollTo(videoId, anchor: .center)
            }
        } else {
            print("DEBUG: Cannot scroll - invalid index or no video ID")
        }
    }
    
    private func setupAdvanceObserver() {
        print("DEBUG: Setting up advance observer")
        observer = NotificationCenter.default.addObserver(
            forName: .advanceToNextVideo,
            object: nil,
            queue: .main
        ) { [weak viewModel] _ in
            print("DEBUG: Received advance notification")
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