# Video Edit Requirements - Week 1 Minimum

## Core Edit Features

### Video Trimming
```swift
protocol VideoTrimming {
    /// Trims video to specified time range
    /// - Parameters:
    ///   - url: Video URL
    ///   - timeRange: Start and end time
    /// - Returns: Trimmed video URL
    func trimVideo(url: URL, timeRange: ClosedRange<TimeInterval>) async throws -> URL
}

struct TrimConfig {
    static let minDuration: TimeInterval = 15.0  // 15 seconds
    static let maxDuration: TimeInterval = 180.0 // 3 minutes
}
```

### Video Cropping
```swift
protocol VideoCropping {
    /// Crops video to specified rect
    /// - Parameters:
    ///   - url: Video URL
    ///   - rect: Crop rectangle (normalized coordinates 0-1)
    /// - Returns: Cropped video URL
    func cropVideo(url: URL, rect: CGRect) async throws -> URL
}

struct CropConfig {
    static let aspectRatio: CGFloat = 9/16  // Portrait video
    static let minWidth: CGFloat = 0.3      // Minimum 30% of original width
}
```

## User Interface Requirements

### Trim Controls
- Start/end time selection
- Preview current selection
- Duration indicator
- Cancel/Save options

### Crop Controls
- Drag corners to crop
- Maintain aspect ratio
- Reset crop button
- Preview crop area

## Performance Requirements

### Processing Time
- Trim operation: < 30 seconds
- Crop operation: < 30 seconds
- Preview loading: < 1 second

## Error Handling
```swift
enum VideoEditError: Error {
    case trimFailed(String)
    case cropFailed(String)
    case invalidTimeRange
    case invalidCropRect
}
```

## Testing Requirements
- Basic trim functionality
- Basic crop functionality
- Error scenarios
- Performance metrics 