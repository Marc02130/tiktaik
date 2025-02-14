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

## Subtitle Requirements

### Timing and Synchronization
- Subtitles must be precisely synchronized with video playback using a 50ms (0.05s) update interval
- Subtitle transitions should be smooth with no visible gaps between subtitle segments
- Subtitle timing checks should not interfere with video playback performance

### Performance
- Subtitle existence checks should be optimized to run only when needed
- Subtitle view model caching should be used to prevent redundant loading
- Subtitle updates should not cause video playback stalls

### User Experience
- Subtitles should remain visible for their full duration
- Next subtitle information should only be logged when debug mode is enabled
- Subtitle gaps should be handled gracefully without UI flicker

### Video Playback Integration
- Subtitle system should not interfere with video auto-advance behavior
- Video player state changes should properly handle subtitle view cleanup
- Subtitle loading should not block video playback initialization

These requirements complement existing feed requirements:
- Auto-play when video becomes visible
- Auto-advance to next video when current video finishes
- Proper async/await handling
- Cache video players for performance

# Video Feed Component Responsibilities

## FeedView
- Manages video list and pagination
- Handles scroll position and visibility
- Coordinates which video should play/stop
- Manages feed-level state (loading, error, loaded)
- Handles video advancement logic

## VideoPlayerView
- Handles video UI presentation (player, controls, stats)
- Coordinates between FeedView and ViewModel
- Manages subtitle visibility based on user preferences
- Reports playback status to FeedView

## VideoPlayerViewModel
- Single source of truth for player state
- Manages player lifecycle (create/cache/cleanup)
- Handles video loading and playback
- Tracks playback time and status
- Reports errors to view

## SubtitleOverlayView
- Pure presentation component
- Renders subtitles at correct time/position
- Handles subtitle styling and animation

## VideoSubtitleViewModel
- Manages subtitle data and timing
- Handles subtitle loading and parsing
- Caches subtitle data
- Provides subtitle preferences

## VideoCache (Service)
- Handles player instance caching
- Manages cache lifecycle and cleanup
- Provides cached players to ViewModels

## FeedViewModel
- Manages feed data loading and pagination
- Handles feed filtering and configuration
- Maintains feed state
- Coordinates with backend services

This division ensures:
- Clear separation of concerns
- Single responsibility for each component
- Proper data flow and state management
- Efficient resource usage through caching
- Clean interfaces between components