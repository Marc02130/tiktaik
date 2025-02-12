# AI Video Subtitles - MVP

## Technical Requirements

### Speech Recognition
- Use OpenAI's Whisper API as primary service
- English language support only
- 95% accuracy rate (Whisper's base capability)
- Process in background (max 3x video duration)
- Audio extraction and format handling

### Subtitle Generation
- Generate VTT format from Whisper API
- Basic timing sync
- 2 lines max per subtitle
- 40 characters per line
- Display duration: 1-7 seconds

### Performance
- Processing time < 3x video length
- Memory usage < 300MB per video
- Basic subtitle caching
- Background processing
- Audio file cleanup after processing

### Error Handling
- API error messages
- Processing status updates
- Network error handling
- Audio extraction errors
- Retry on failure

## User Requirements

### Basic Controls
- Generate subtitles button
- Show/hide subtitles
- Progress indicator
- Basic edit capability
- Cancel generation option

### Editing Interface
- Simple text editor
- Timing adjustments
- Save/cancel changes
- VTT preview

### Customization
- Font size (S/M/L)
- Basic color options (White/Yellow)
- Position (Top/Bottom)

## Implementation Notes

### Data Structure
```swift
struct VideoSubtitle: Codable, Identifiable {
    let id: String
    let videoId: String
    let startTime: TimeInterval
    let endTime: TimeInterval
    let text: String
    var isEdited: Bool
    let createdAt: Date
}

struct SubtitleMetadata: Codable {
    let videoId: String
    var state: SubtitleState
    var error: String?
    let startedAt: Date?
    var completedAt: Date?
    var preferences: SubtitlePreferences
}
```

### Processing States
```swift
enum SubtitleState {
    case notStarted
    case generating
    case complete
    case failed
}

enum WhisperError: LocalizedError {
    case audioExtractionFailed
    case apiError(String)
    case invalidResponse
    case processingFailed
}
```

### API Configuration
```swift
struct WhisperConfig {
    let apiKey: String
    let baseURL: URL
    let format: String = "vtt"
    let model: String = "whisper-2"
    let language: String = "en"
}
```

### Integration Points
- Video upload flow
- Player controls
- Basic edit interface
- Progress tracking
- Error handling

### Performance Targets
- Audio extraction: < 5s
- API request: < 10s per minute of video
- VTT parsing: < 1s
- Memory peak: < 300MB
- Cache hit ratio: > 80%
