# Video Feed Requirements - Week 1 Minimum

## Overview
Basic video feed with creator/consumer profile distinction.

## Feed Types

### Creator Profile Feed
- Shows only user's own videos
- Vertical scrolling list
- Basic video controls (play/pause)
- Upload date sorting

### Consumer Profile Feed
- Shows videos from followed creators
- Shows videos matching selected tags
- Vertical scrolling list
- Basic video controls (play/pause)

## Technical Implementation

### SwiftUI Structure
```swift
struct VideoFeedView: View {
    @StateObject private var viewModel: VideoFeedViewModel
    let userProfile: UserProfile // creator or consumer
    
    var body: some View {
        VideoFeedContainer {
            ForEach(viewModel.videos) { video in
                VideoPlayerView(video: video)
                    .overlay(VideoControlsOverlay(video: video))
            }
        }
        .refreshable { await viewModel.refreshFeed() }
    }
}

struct VideoControlsOverlay: View {
    let video: Video
    
    var body: some View {
        VStack {
            playPauseButton
            creatorName
            videoTitle
        }
    }
}
```

### Video Playback Requirements
- Auto-play when video becomes visible
- Auto-advance to next video when current video finishes
- Proper async/await handling for video operations:
  ```swift
  // Seek must be awaited
  await player.seek(to: .zero)
  // Play is synchronous
  player.play()
  ```
- Cache video players for performance
- Use storage paths for video URLs, not download URLs

### Data Models
```swift
struct Video: Identifiable {
    let id: String
    let storageUrl: String  // Format: "videos/{videoId}.{extension}"
    let userId: String
    let title: String
    let uploadDate: Date
    let tags: [String]
    
    func getVideoURL() async throws -> URL {
        let storage = Storage.storage()
        let ref = storage.reference(withPath: storageUrl)
        return try await ref.downloadURL()
    }
}

enum UserProfile {
    case creator
    case consumer(ConsumerPreferences)
}

struct ConsumerPreferences {
    var followingOnly: Bool
    var selectedTags: [String]
}
```

## Performance Requirements
- Scrolling: 60fps
- Video load: < 500ms
- Feed refresh: < 1s
- Cache video players to reduce load times

## Error Handling
```swift
enum FeedError: Error {
    case loadFailed
    case videoUnavailable
    case networkError
}
```

## Testing Requirements
- Basic video playback
- Feed scrolling
- Profile switching
- Auto-advance functionality
- Auto-play behavior
