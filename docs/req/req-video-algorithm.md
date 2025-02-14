# Feed Algorithm Requirements - Week 1 Minimum

## Overview
Basic feed population based on user profile type and preferences.

## Feed Types

### Creator Feed Algorithm
```swift
struct CreatorFeedQuery {
    let userId: String
    let limit: Int
    let lastVideo: Video?
}
```

### Consumer Feed Algorithm
```swift
struct ConsumerFeedQuery {
    let userId: String
    let followingOnly: Bool
    let selectedTags: [String]
    let limit: Int
    let lastVideo: Video?
}
```

## Implementation

### Data Models
```swift
struct FeedConfiguration {
    let userProfile: UserProfile
    let limit: Int = 10
    
    var feedQuery: Any {
        switch userProfile {
        case .creator:
            return CreatorFeedQuery(
                userId: userId,
                limit: limit,
                lastVideo: nil
            )
        case .consumer(let preferences):
            return ConsumerFeedQuery(
                userId: userId,
                followingOnly: preferences.followingOnly,
                selectedTags: preferences.selectedTags,
                limit: limit,
                lastVideo: nil
            )
        }
    }
}
```

## Query Rules
1. Creator Profile:
   - Filter: userId matches current user
   - Sort: by uploadDate descending
   - Limit: 10 videos per fetch

2. Consumer Profile:
   - Filter: followingOnly OR selectedTags
   - Sort: by uploadDate descending
   - Limit: 10 videos per fetch

## Performance Requirements
- Initial load: < 1 second
- Pagination: < 500ms
- Cache results

## Error Handling
```swift
enum AlgorithmError: Error {
    case invalidQuery
    case noResults
    case fetchFailed
}
```

## Testing Requirements
- Query generation
- Filter logic
- Basic pagination

## Dependencies
- Firebase Firestore
- Combine
- SwiftUI

## Future Enhancements
- Advanced recommendation engine
- User preferences
- View time weighting
- Engagement scoring

## Notes
- Start with simple, deterministic algorithm
- Focus on performance and reliability
- Monitor query costs
- Cache aggressively 