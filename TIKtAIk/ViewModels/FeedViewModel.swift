//
// FeedViewModel.swift
// TIKtAIk
//
// Created: 2024-02-14
// Last modified: 2024-02-14
//
// Purpose: View model for managing video feed
// Author: Assistant
// Copyright © 2024 TIKtAIk. All rights reserved.
//

import Foundation
import Combine
import FirebaseAuth

@MainActor
final class FeedViewModel: ObservableObject {
    enum FeedState: Equatable {
        case idle
        case loading
        case loaded([Video])
        case error(String)
        
        static func == (lhs: FeedState, rhs: FeedState) -> Bool {
            switch (lhs, rhs) {
            case (.idle, .idle):
                return true
            case (.loading, .loading):
                return true
            case (.loaded(let lhsVideos), .loaded(let rhsVideos)):
                return lhsVideos.map { $0.id } == rhsVideos.map { $0.id }
            case (.error(let lhsError), .error(let rhsError)):
                return lhsError == rhsError
            default:
                return false
            }
        }
    }
    
    @Published private(set) var state: FeedState = .idle {
        didSet {
            if case .loaded(let videos) = state {
                self.videos = videos
            }
        }
    }
    private let feedService = FeedService()
    private let auth = Auth.auth()
    private var lastVideo: Video?
    private let networkMonitor = NetworkMonitor.shared
    private var currentQuery: FeedQuery?
    
    @Published var videos: [Video] = []
    @Published var config: FeedConfiguration = FeedConfiguration(
        userId: Auth.auth().currentUser?.uid ?? "",
        isCreatorOnly: false,
        followingOnly: false,
        selectedTags: []
    )
    
    @Published private(set) var isLoading = false
    @Published private(set) var error: String?
    
    private var isLoadingMore = false
    private var isUpdating = false  // Add state update lock
    
    @Published private(set) var currentVideoId: String?
    
    init() {
        // Initialize with current user's ID for creator mode
        self.config = FeedConfiguration(
            userId: Auth.auth().currentUser?.uid ?? "",
            isCreatorOnly: false,
            followingOnly: false,
            selectedTags: []
        )
        
        // DEBUG: Print initial configuration
        #if DEBUG
        print("FeedViewModel initialized with userId:", config.userId)
        #endif
    }
    
    func loadFeed(query: FeedQuery) {
        state = .loading
        currentQuery = query
        
        #if DEBUG
        print("Loading feed with config - isCreatorOnly:", query.config.isCreatorOnly)
        print("Current user ID:", config.userId)
        #endif
        
        Task {
            do {
                let videos = try await feedService.fetchFeedVideos(query: query)
                if query.config.isCreatorOnly {
                    // No need to filter by metadata, use videos as is since they're already filtered by userId
                    state = .loaded(videos)
                    #if DEBUG
                    print("Creator videos loaded:", videos.count)
                    #endif
                } else {
                    state = .loaded(videos)
                }
            } catch {
                state = .error(error.localizedDescription)
                #if DEBUG
                print("Feed loading error:", error)
                #endif
            }
        }
    }
    
    func loadMore() async {
        guard !isUpdating else { return }
        isUpdating = true
        defer { isUpdating = false }
        
        // Prevent multiple simultaneous loadMore calls
        guard !isLoadingMore,
              case .loaded(let videos) = state,
              let query = currentQuery,
              !videos.isEmpty else { return }
        
        isLoadingMore = true
        defer { isLoadingMore = false }
        
        let nextQuery = FeedQuery(
            limit: query.limit,
            lastVideo: videos.last,
            config: query.config
        )
        
        do {
            let newVideos = try await feedService.fetchFeedVideos(query: nextQuery)
            if case .loaded(let existingVideos) = state {
                state = .loaded(existingVideos + newVideos)
            }
        } catch {
            // Keep existing videos on error
            print("Load more failed:", error)
        }
    }
    
    func loadInitialFeed() async {
        print("DEBUG: Starting initial feed load")
        print("DEBUG: Creator mode:", config.isCreatorOnly)
        print("DEBUG: User ID:", config.userId)
        state = .loading
        
        do {
            let query = FeedQuery(limit: 10, lastVideo: nil, config: config)
            print("DEBUG: Fetching feed with query:", query)
            let videos = try await feedService.fetchFeed(query: query)
            print("DEBUG: Raw fetched videos count:", videos.count)
            
            if videos.isEmpty {
                state = .error("No videos found")
                print("DEBUG: No videos found")
            } else {
                state = .loaded(videos)
                print("DEBUG: Feed loaded with \(videos.count) videos")
                // Print video IDs for debugging
                videos.forEach { video in
                    print("DEBUG: Loaded video ID:", video.id)
                }
            }
        } catch {
            print("DEBUG: Feed load error:", error)
            state = .error(error.localizedDescription)
        }
    }
    
    /// Updates feed type and refreshes content
    func updateFeedType() {
        state = .idle
        Task {
            await loadInitialFeed()
        }
    }
    
    /// Updates tag suggestions based on viewed videos
    private func updateTagSuggestions(from videos: [Video]) {
        var tagFrequencies: [String: Int] = [:]
        for video in videos {
            for tag in video.tags {
                tagFrequencies[tag, default: 0] += 1
            }
        }
        
        // Store top tags for suggestions
        let topTags = tagFrequencies.sorted { $0.value > $1.value }
            .prefix(10)
            .map { $0.key }
        
        // Could be used for tag recommendations
        print("Popular tags:", topTags)
    }
    
    /// Preloads the next video in the feed
    private func preloadNextVideo() {
        guard let currentIndex = videos.firstIndex(where: { $0.id == currentVideoId }),
              currentIndex + 1 < videos.count else {
            return
        }
        
        let nextVideo = videos[currentIndex + 1]
        let preloadViewModel = VideoPlayerViewModel(video: nextVideo)
        Task {
            await preloadViewModel.preloadVideo()
        }
    }
    
    /// Called when a video starts playing
    func videoStartedPlaying(_ videoId: String) {
        currentVideoId = videoId
        preloadNextVideo()
    }
    
    private func loadMoreVideos() async {
        guard !isLoading else { return }
        
        print("DEBUG: Loading more videos")
        isLoading = true
        
        let lastVideo = videos.last
        let query = FeedQuery(
            limit: 10,  // Increase batch size
            lastVideo: lastVideo,
            config: config
        )
        
        do {
            let newVideos = try await feedService.fetchFeed(query: query)
            await MainActor.run {
                self.videos.append(contentsOf: newVideos)
                self.isLoading = false
                print("DEBUG: Loaded \(newVideos.count) more videos, total: \(self.videos.count)")
            }
        } catch {
            print("ERROR: Failed to load more videos: \(error)")
            isLoading = false
        }
    }
    
    func checkAndLoadMoreVideos(at index: Int) {
        // Load more when we're 2 videos away from the end
        if index >= videos.count - 2 {
            Task {
                await loadMoreVideos()
            }
        }
    }
} 