# Video Upload Requirements - Week 1 Minimum

## Overview
Basic video upload functionality for creators.

## Upload Flow
1. Select video from library
2. Generate thumbnails
3. Add metadata (title, description, tags)
4. Upload to Firebase Storage
5. Create video document in Firestore

## Technical Implementation

### Storage Path Format
```swift
// Storage paths must follow this format:
"videos/{videoId}.{extension}"  // e.g. "videos/ABC123.mp4"

// Do not store full download URLs
// ❌ Wrong: "https://firebasestorage.googleapis.com/..."
// ✅ Correct: "videos/ABC123.mp4"
```

### Video Document Creation
```swift
struct Video: Identifiable, Codable {
    let id: String
    let userId: String  // Not creatorId
    let title: String
    let description: String?
    let metadata: VideoMetadata
    let stats: Stats
    let status: VideoStatus
    let storageUrl: String  // Storage path only
    let thumbnailUrl: String?
    let createdAt: Date
    let updatedAt: Date
    let tags: Set<String>
    let isPrivate: Bool
    let allowComments: Bool
}

struct VideoMetadata: Codable {
    let duration: Double
    let width: Int
    let height: Int
    let size: Int
    let format: String
    let resolution: String?
    let uploadDate: Date
    let lastModified: Date
}
```

### Upload Process
1. Generate UUID for video
2. Upload to Firebase Storage using storage path format
3. Create video document with storage path
4. Update status as processing completes

## Error Handling
```swift
enum UploadError: LocalizedError {
    case invalidVideo
    case fileTooLarge
    case invalidFormat
}
```

## Validation
- File size < 500MB
- Supported formats: mp4, mov
- Required fields: title, userId
- Valid storage path format

## Testing Requirements
- Video selection
- Metadata extraction
- Upload progress
- Error handling
- Storage path format
- Document creation

## Functional Requirements

### Video Selection
- **Input Methods**
  - PhotosPicker integration
  - Local file selection
  - Camera capture (future)

### Video Validation
- **File Constraints**
  - Maximum size: 500MB
  - Supported formats: MP4, MOV
  - Minimum duration: 3 seconds
  - Maximum duration: 10 minutes

### Thumbnail Generation
- **Auto Generation**
  - 6 thumbnails at equal intervals
  - Preview in horizontal scroll
  - Manual selection
  - Quality: 70% JPEG compression

### Metadata Input
- **Required Fields**
  - Title (1-100 characters)
  - Description (optional, 0-500 characters)
  - Tags (comma-separated)
  - Privacy setting (public/private)
  - Comments enabled/disabled

### Upload Process
- **Progress Tracking**
  - Upload percentage
  - Status messages
  - Cancel capability
  - Error handling
  - Auto-retry on failure

## State Management
- **Upload Progress**
  ```swift
  let _ = try await videoRef.putFileAsync(from: videoURL) { progress in
      let percentComplete = Double(progress.completedUnitCount) / 
          Double(progress.totalUnitCount)
      self.uploadProgress = percentComplete
  }
  ```

## Performance Requirements
- **Video Processing**
  - Thumbnail generation < 2 seconds
  - Upload start < 1 second
  - Progress updates every 100ms

## Security Requirements
- **Authentication**
  - Valid user session
  - Storage permissions
  - Rate limiting
  
- **Validation**
  - File scanning
  - Content verification
  - Metadata sanitization

## Dependencies
- SwiftUI
- PhotosUI
- AVFoundation
- Firebase Storage
- Firebase Firestore

## Future Enhancements
- Video trimming
- Filters and effects
- Multiple file upload
- Background upload
- Draft saving

## Notes
- Consider implementing upload queue
- Add retry mechanism
- Cache temporary files
- Implement upload resume
- Add progress notifications
