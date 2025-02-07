# Video Library Technical Requirements

## Overview
The video library provides users access to their uploaded videos and navigation to the video editing interface. This document outlines the technical requirements for implementing the video library view and navigation flow.

## Functional Requirements

### Library Display
- **Grid View**
  - Fixed size thumbnails (150x200)
  - Support for both portrait and landscape videos
  - Consistent spacing (12pt)
  - Adaptive grid layout
  - Proper aspect ratio handling

### Thumbnail Display
- **Image Handling**
  - Aspect ratio fill for all orientations
  - Clipped overflow content
  - Rounded corners (12pt radius)
  - Placeholder for loading state
  - Error handling for failed loads

### Metadata Display
- **Video Info**
  - Title with single line limit
  - View count with icon
  - Like count with icon
  - Private video indicator
  - Fixed width constraints

### Navigation
- **Video Selection**
  - Tap to edit
  - Sheet presentation
  - Refresh on dismiss
  - State preservation

### Refresh Mechanism
- **Auto Refresh**
  - Pull to refresh
  - Post-edit refresh
  - Loading indicators
  - Error handling

## Technical Implementation

### SwiftUI Structure
```swift
struct VideoLibraryView: View {
    @StateObject private var viewModel = VideoLibraryViewModel()
    @State private var refreshTrigger = RefreshTrigger()
    
    private let columns = [
        GridItem(.adaptive(minimum: 150, maximum: 200), spacing: 12)
    ]
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(viewModel.videos) { video in
                    VideoThumbnailView(video: video)
                }
            }
        }
        .refreshable {
            await viewModel.loadVideos()
        }
        .onChange(of: refreshTrigger.shouldRefresh) { _, shouldRefresh in
            if shouldRefresh {
                Task {
                    await viewModel.loadVideos()
                    refreshTrigger.refreshCompleted()
                }
            }
        }
    }
}

struct VideoThumbnailView: View {
    let video: Video
    
    var body: some View {
        VStack(alignment: .leading) {
            AsyncImage(url: URL(string: video.thumbnailUrl ?? "")) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 150, height: 200)
                    .clipped()
            }
            // ... metadata display
        }
    }
}
```

## Layout Requirements
- **Grid Configuration**
  - Minimum item width: 150pt
  - Maximum item width: 200pt
  - Horizontal spacing: 12pt
  - Vertical spacing: 12pt
  - Edge padding: 16pt

- **Thumbnail Dimensions**
  - Width: 150pt (fixed)
  - Height: 200pt (fixed)
  - Corner radius: 12pt
  - Aspect ratio: Fill mode

## Performance Optimizations
- LazyVGrid for efficient loading
- Async image loading
- Thumbnail caching
- Memory management
- Proper state updates

## Error Handling
- Failed image loads
- Network issues
- Empty states
- Loading states
- Refresh failures

## Accessibility
- VoiceOver support
- Dynamic Type
- Proper contrast
- Touch targets

## Dependencies
- SwiftUI
- Firebase Storage
- Firebase Firestore
- RefreshTrigger

## Testing Requirements
- Layout testing
- Image loading
- Navigation flow
- Refresh mechanism
- Error states

## Data Requirements

### Video Item Model
```swift
struct Video: Identifiable {
    let id: String
    let title: String
    let thumbnailURL: URL
    let duration: TimeInterval
    let uploadDate: Date
    let viewCount: Int
    let isPrivate: Bool
}
```

## Performance Requirements
- **Loading**
  - Lazy loading of thumbnails
  - Pagination support
  - Cached thumbnails
  - Quick response time (< 500ms)

## Error Handling
- Empty library state
- Loading failures
- Network issues
- Invalid video data

## Testing Requirements

### Unit Tests
- Grid layout logic
- Video data management
- Navigation flow
- Sorting/filtering

### UI Tests
- Library navigation
- Video selection
- Grid scrolling
- Search functionality

### Integration Tests
- Data fetching
- Navigation flow
- Edit view presentation

## Accessibility
- VoiceOver support
- Grid navigation
- Clear labels
- Scaling support

## Dependencies
- SwiftUI
- Firebase Storage
- Firebase Firestore
- AVFoundation

## Future Enhancements
- Multi-select capability
- Batch operations
- Advanced filtering
- Analytics integration

## Notes
- Implement efficient thumbnail loading
- Consider memory management
- Cache frequently accessed data
- Smooth transitions between views 

# Required Firestore Indexes

Create the following composite index for the videos collection:

Fields:
- userId (Ascending)
- createdAt (Descending)
- __name__ (Descending)

You can create this index by:
1. Going to Firebase Console > Firestore > Indexes
2. Click "Add Index"
3. Collection ID: videos
4. Fields:
   - userId (Ascending)
   - createdAt (Descending)
   - __name__ (Descending)
5. Click "Create Index"

Or use this direct link:
https://console.firebase.google.com/v1/r/project/tiktaik/firestore/indexes?create_composite=CkZwcm9qZWN0cy90aWt0YWlrL2RhdGFiYXNlcy8oZGVmYXVsdCkvY29sbGVjdGlvbkdyb3Vwcy92aWRlb3MvaW5kZXhlcy9fEAEaCgoGdXNlcklkEAEaDQoJY3JlYXRlZEF0EAIaDAoIX19uYW1lX18QAg 