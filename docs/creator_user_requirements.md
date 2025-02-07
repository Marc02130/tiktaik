# User Requirements - Week 1 Minimum

## Common Video Requirements

### Video Upload
- **Video Specifications**
  - Format: MP4, MOV
  - Resolution: Up to 1080p
  - Duration: 15s - 3min
  - Size: Up to 500MB

## Creator Type Requirements

### 1. Chef/Food Creator
```swift
struct RecipeMetadata {
    let title: String
    let ingredients: [String]
    let cookingTime: TimeInterval
    let cuisineType: String
}
```

### 2. Fitness Creator
```swift
struct WorkoutMetadata {
    let title: String
    let muscleGroups: [String]
    let equipment: [String]
    let duration: TimeInterval
}
```

### 3. Educational Creator
```swift
struct LearningMetadata {
    let title: String
    let subject: String
    let level: String
    let keyPoints: [String]
}
```

### 4. Comedy Creator
```swift
struct SkitMetadata {
    let title: String
    let genre: String
    let contentRating: String
    let tags: [String]
}
```

### 5. Beauty/Makeup Creator
```swift
struct BeautyMetadata {
    let title: String
    let skillLevel: String
    let products: [String]
    let techniques: [String]
}
```

### 6. Music Creator
```swift
struct MusicMetadata {
    let title: String
    let genre: String
    let instruments: [String]
    let isOriginal: Bool
}
```

## Common Requirements

### Authentication
```swift
protocol CreatorAuthentication {
    func signUp(email: String, password: String) async throws
    func signIn(email: String, password: String) async throws
}
```

### Profile
```swift
struct CreatorProfile {
    let userId: String
    let creatorType: CreatorType
    var displayName: String
}
```

### Basic Analytics
```swift
protocol BasicAnalytics {
    func getViewCount() async -> Int
}
```

## Performance Requirements

### Video Processing
- Upload time: < 3 minutes
- Playback start: < 2 seconds

### UI Response
- Action feedback: < 100ms

## Error Handling
```swift
enum CreatorError: Error {
    case uploadFailed(String)
    case processingFailed(String)
    case storageError(String)
}
```

## Testing Requirements
- Basic error scenarios covered
- Core functionality tested