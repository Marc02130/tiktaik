# Video Comments Review

## Overview
The CommentsReviewView provides a comprehensive analysis of video comments, including:
- AI-generated comment summary
- Engagement metrics
- Paginated comment list
- Technical and user feedback categorization

## Technical Requirements

### Comment Loading
- Load comments in pages of 10
- Sort by most recent first
- Support infinite scroll pagination
- Cache loaded comments for performance

### AI Summary Generation
- Analyze comment sentiment
- Identify key themes/topics
- Generate concise summary (max 3 paragraphs)
- Update summary when new comments are added

### Engagement Metrics
- Total comments count
- Unique commenters count
- Average comment length
- Response rate
- Peak commenting times
- Engagement trends

### Performance Requirements
- Initial load < 2 seconds
- Summary generation < 3 seconds
- Smooth scroll performance
- Efficient memory usage

## User Requirements

### Comment Review Interface
- Clear comment threading
- Easy navigation between pages
- Visual distinction between user/creator comments
- Quick access to comment context

### Summary Display
- Clear, readable summary format
- Key insights highlighted
- Easy to understand metrics
- Visual data representations

### Interaction Features
- Filter comments by:
  - Date range
  - Sentiment
  - User type
  - Response status
- Search within comments
- Sort options:
  - Most recent
  - Most liked
  - Most discussed

## Implementation

### View Structure
```swift
struct CommentsReviewView {
    let video: Video
    let comments: [Comment]
    let summary: CommentSummary
    let engagement: EngagementMetrics
}
```

### Data Models
```swift
struct CommentSummary {
    let overview: String
    let keyThemes: [String]
    let sentiment: SentimentScore
    let recommendations: [String]
}

struct EngagementMetrics {
    let totalComments: Int
    let uniqueCommenters: Int
    let averageLength: Int
    let responseRate: Double
    let peakTimes: [TimeWindow]
}
```

### Navigation
- Access from VideoEditView via "Review Comments" button
- Return to VideoEditView preserves edit state
- Share summary via standard share sheet
