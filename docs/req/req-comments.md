# Comment System Requirements

## Models

### Comment Model
```swift
struct Comment: Identifiable, Codable {
    let id: String
    let videoId: String
    let userId: String
    let parentId: String?     // For reply support
    let content: String
    var likesCount: Int
    var replyCount: Int
    let createdAt: Date
    var updatedAt: Date
    
    static let collectionName = "videoComments"
}
```

## Services

### Comment Service
```swift
protocol CommentService {
    /// Fetch comments for a video
    func fetchComments(
        videoId: String, 
        limit: Int,
        lastComment: Comment?
    ) async throws -> [Comment]
    
    /// Add new comment
    func addComment(
        videoId: String, 
        content: String
    ) async throws -> Comment
}
```

## View Components

### CommentSheet
- Sheet presentation for comments
- Navigation bar with close button
- Comment count display
- Scrollable comment list
- Comment input field with post button
- Loading state indicator

### CommentRow
- Display comment content
- Show like count
- Show relative timestamp
- Support for reply indication

## View Model

### CommentViewModel
```swift
@Observable final class CommentViewModel {
    var comments: [Comment]
    var isLoading: Bool
    var error: String?
    var newComment: String
    
    func loadComments(for videoId: String) async
    func addComment() async
}
```

## Analytics Requirements

### Comment Volume Analytics
- Total comments count
- Comments per view ratio
- Comment frequency tracking
- Peak commenting periods identification

### Sentiment Analysis
- Positive/negative/neutral distribution
- Sentiment trends
- Keyword analysis
- Topic clustering

### Engagement Metrics
- Most engaging comments tracking
- Reply ratios
- Creator response rates
- Response time tracking
- User engagement patterns

### Performance Analytics
- Most liked comments
- Most replied comments
- Comment timing analysis
- Retention correlation

### Analytics Display
- Sentiment visualization
- Keyword clouds
- Timeline heat maps
- Interactive analytics dashboard

## Firebase Implementation

### Collection Structure
- Collection: "videoComments"
- Document ID: Auto-generated
- Batch updates for comment counts
- Indexes for efficient queries

### Performance Requirements
- Initial load: < 1 second
- Comment posting: < 500ms
- Smooth scrolling
- Efficient batch updates

### Error Handling
```swift
enum CommentError: LocalizedError {
    case notAuthenticated
    case invalidComment
    case operationFailed
    case invalidData
}
```
