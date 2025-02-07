@MainActor
enum FeedOptimizer {
    static func optimizeFeedQuery(_ query: FeedQuery) -> FeedQuery {
        // Adjust limit based on network conditions
        let adjustedLimit = NetworkMonitor.shared.isOnCellular ? 5 : query.limit
        
        // Preload next batch
        let preloadLimit = adjustedLimit + 5
        
        return FeedQuery(
            limit: preloadLimit,
            lastVideo: query.lastVideo,
            config: query.config
        )
    }
    
    static func shouldPreload(currentIndex: Int, totalCount: Int) -> Bool {
        // Preload when within 2 items of the end
        return currentIndex >= totalCount - 2
    }
} 