# AI Video Subtitles - MVP

## Technical Requirements

### Speech Recognition
- English language support only
- 90% accuracy rate
- Process in background (max 3x video duration)
- Basic noise handling

### Subtitle Generation
- Generate VTT format
- Basic timing sync
- 2 lines max per subtitle
- 40 characters per line
- Display duration: 1-7 seconds

### Performance
- Processing time < 3x video length
- Memory usage < 300MB per video
- Basic subtitle caching
- Background processing

### Error Handling
- Basic error messages
- Processing status updates
- Retry on failure

## User Requirements

### Basic Controls
- Generate subtitles button
- Show/hide subtitles
- Progress indicator
- Basic edit capability

### Editing Interface
- Simple text editor
- Timing adjustments
- Save/cancel changes

### Customization
- Font size (S/M/L)
- Basic color options (White/Yellow)
- Position (Top/Bottom)

## Implementation Notes

### Data Structure
```swift
struct Subtitle: Codable {
    let id: String
    let videoId: String
    let startTime: TimeInterval
    let endTime: TimeInterval
    let text: String
    var isEdited: Bool
    let createdAt: Date
}
```

### Processing States
```swift
enum SubtitleState {
    case generating
    case complete
    case failed
}
```

### Integration Points
- Video upload
- Player controls
- Basic edit interface
