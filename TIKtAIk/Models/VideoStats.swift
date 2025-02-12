struct VideoStats {
    var likes: Int
    var commentsCount: Int
    var shares: Int
    var views: Int
    
    static let empty = VideoStats(likes: 0, commentsCount: 0, shares: 0, views: 0)
} 