# Video Edit Technical Requirements

## Overview
The video editing feature allows users to view their uploaded videos and edit basic metadata. This document outlines the technical requirements for implementing the initial video editing functionality.

## Functional Requirements

### Video Preview
- **Display**
  - Video thumbnail preview
  - Current video duration
  - Upload date/time
  - Current view count
  - Current like count

### Thumbnail Selection
- **Features**
  - Auto-generated thumbnails from video
  - Manual thumbnail selection
  - Preview of selected thumbnail
  - Thumbnail upload to Firebase Storage
  - Update thumbnail URL in Firestore

### Metadata Editing
- **Basic Information**
  - Title (max 100 characters)
  - Description (max 500 characters)
  - Tags/Categories
  - Visibility settings (public/private)

### User Interface
- **Preview Section**
  - Play/pause preview
  - Mute/unmute controls
  - Progress bar

- **Edit Form**
  - Input fields for metadata
  - Character count indicators
  - Save/Cancel buttons
  - Validation feedback

### Creator Features
- **Analytics Preview**
  - Basic view statistics
  - Engagement metrics
  - Share count

### Error Handling
- **User Feedback**
  - Error alerts with messages
  - Loading states
  - Save confirmation
  - Network error handling

### State Management
- **Refresh Mechanism**
  - RefreshTrigger pattern
  - Library update after edits
  - State synchronization

## Performance Requirements
- **Video Loading**
  - Preview load time < 1 second
  - Smooth playback at original quality
  - Efficient memory management

## Technical Implementation

### SwiftUI Structure
```swift
@Observable final class RefreshTrigger {
    var shouldRefresh = false
    
    func triggerRefresh() {
        shouldRefresh = true
    }
    
    func refreshCompleted() {
        shouldRefresh = false
    }
}

struct VideoEditView: View {
    @StateObject private var viewModel: VideoEditViewModel
    
    init(videoId: String, refreshTrigger: RefreshTrigger) {
        _viewModel = StateObject(wrappedValue: 
            VideoEditViewModel(videoId: videoId, refreshTrigger: refreshTrigger))
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                videoPreviewSection
                thumbnailSelectionSection
                metadataFormSection
                analyticsSection
                actionButtons
            }
            .padding()
        }
    }
}

struct ThumbnailSelectionView: View {
    @Binding var selectedIndex: Int
    let thumbnails: [UIImage]
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(thumbnails.indices, id: \.self) { index in
                    ThumbnailButton(
                        image: thumbnails[index],
                        isSelected: index == selectedIndex,
                        action: { selectedIndex = index }
                    )
                }
            }
            .padding()
        }
    }
}
```

### Components
- **VideoPreviewPlayer**: Video preview component
- **MetadataForm**: Form for editing video details
- **AnalyticsPreview**: Basic statistics display
- **ValidationSystem**: Input validation and feedback

## Testing Requirements

### Unit Tests
- Metadata validation logic
- Form input handling
- Data persistence
- State management

### UI Tests
- Form interaction
- Video preview controls
- Save/cancel functionality
- Input validation feedback

### Integration Tests
- Data persistence
- API communication
- State updates

## Error Handling
- **Input Validation**
  - Title/description length
  - Required fields
  - Invalid characters
  
- **System Errors**
  - Save failures
  - Load failures
  - Network issues

## Accessibility
- VoiceOver support
- Dynamic Type
- Keyboard navigation
- High contrast support

## Data Model
```swift
struct VideoMetadata {
    var id: String
    var title: String
    var description: String
    var tags: [String]
    var visibility: VideoVisibility
    var uploadDate: Date
    var statistics: VideoStatistics
}
```

## Dependencies
- SwiftUI
- AVFoundation
- Firebase Storage
- Firebase Firestore

## Future Enhancements
- Thumbnail selection/generation
- Advanced video trimming
- Filters and effects
- Batch editing support

## Notes
- Focus on stability and data integrity
- Implement proper validation
- Ensure smooth preview playback
- Follow iOS Human Interface Guidelines

# Video Editing Implementation

## Overview
The video editing system consists of four main views:
1. VideoEditView - For metadata editing
2. VideoTrimView - For trimming video length
3. VideoCropView - For cropping video dimensions
4. VideoThumbnailView - For thumbnail selection

## VideoEditView
Purpose: Edit video metadata without modifying video content
- Edit title
- Edit description
- Edit/select tags
- Toggle privacy settings
- Toggle comment settings
- Navigate to trim/crop/thumbnail/comment review selection

Save Operation:
- Updates metadata in Firestore
- Does NOT clear thumbnails
- Does NOT modify video content

## VideoTrimView
Purpose: Trim video length
- Select start/end points
- Preview trimmed result

Technical Implementation:
1. Create temporary working directory
2. Copy source video to working directory
3. Create AVURLAsset from local copy
4. Load video track and verify duration
5. Create composition with:
   - Video track with preserved orientation transform
   - Audio track if present
6. Export trimmed composition
7. Upload trimmed video to replace original in storage
   - Uses same filename/path
   - Preserves video format
   - Updates metadata

Save Operation Flow:
1. Upload trimmed video in same format to replace original
   - Uses Firebase Storage putFileAsync
   - Preserves original path/filename
   - Sets correct content type metadata
2. Set thumbnails to null in video document (handled by calling code)
3. Delete old video from storage not needed (since we replace)
4. Show message: "Video has been trimmed. Please select a new thumbnail in video edit."
5. Close video trim view

Error Handling:
- Validates source file existence and permissions
- Verifies file copy integrity
- Handles export session failures
- Handles upload failures
- Cleans up temporary files
- Provides detailed error messages

Performance Optimizations:
- Uses chunk-based file copying
- Maintains video quality with highest quality preset
- Preserves original video format
- Efficient memory usage with file handles
- Background cleanup of temporary files

## VideoCropView
Purpose: Crop video dimensions
- Select crop area
- Preview cropped result

Save Operation:
1. Upload cropped video in same format to replace original
2. Set thumbnails to null in video document
3. Delete old video from storage
4. Show message: "Video has been cropped. Please select a new thumbnail in video edit."
5. close VideoCropView

## VideoThumbnailView
Purpose: Handle thumbnail selection
- Generate thumbnails from current video
- Display thumbnail options
- Preview selected thumbnail
- Save thumbnail selection

Save Operation:
1. Upload selected thumbnail to storage
2. Update thumbnail URL in video document
3. Return to VideoEditView

## Error Handling
- Handle upload failures
- Handle storage operation failures
- Handle Firestore update failures
- Show appropriate error messages to user
- Prevent saving without thumbnail after content modification

## Thumbnail Management
- Thumbnails are cleared as part of trim/crop save operations
- After trimming or cropping, user must select a new thumbnail
- VideoThumbnailView provides thumbnail selection interface
- Thumbnails should be generated from the modified video content
- Cannot save video without selecting new thumbnail after content modification

## State Management
- Each view handles its own state and save operations independently
- Trim/crop operations manage thumbnail clearing directly
- VideoEditView manages metadata updates only
- VideoThumbnailView manages thumbnail selection and updates

## Comments Review Access

### Navigation
- "Review Comments" button in video edit toolbar
- Opens CommentsReviewView as modal sheet
- Preserves video edit state when reviewing comments

### Integration Requirements
- Accessible after video upload completion
- Comments review does not interrupt edit session
- Return to edit preserves all modifications
- Share comment insights without leaving edit flow

### UI Components
- Comments review button with bubble icon
- Modal presentation for full-screen review
- Dismiss gesture returns to edit
- Share button for comment insights

### State Management
- Maintain edit history during review
- Cache comment data for quick access
- Sync any comment moderation changes
- Preserve video playback position

### Performance
- Lazy load comments data
- Background summary generation
- Maintain edit responsiveness
- Efficient memory management
