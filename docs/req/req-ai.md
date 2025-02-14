# AI Requirements - Week 1 (OpenAI Implementation)

## Overview
OpenAI-based implementation for auto-classification and metadata generation for exercise and recipe content.

## Import Requirements
```swift
// OpenAI - Core AI processing
import OpenAI
// AVFoundation - Video frame extraction
import AVFoundation
// SwiftUI - UI components
import SwiftUI
```

## Data Models

### Exercise Classification
```swift
@Observable final class ExerciseClassification: Codable {
    let id: String
    var muscleGroups: Set<MuscleGroup>
    var difficulty: DifficultyLevel
    var equipment: Set<Equipment>
    var estimatedCalories: Int
    var confidence: Double
    
    /// Example:
    /// ```swift
    /// let classification = ExerciseClassification(
    ///     muscleGroups: [.core, .upperBody],
    ///     difficulty: .intermediate,
    ///     equipment: [.dumbbells],
    ///     estimatedCalories: 150,
    ///     confidence: 0.85
    /// )
    /// ```
}

enum MuscleGroup: String, Codable {
    case core, upperBody, lowerBody, fullBody
}

enum DifficultyLevel: String, Codable {
    case beginner, intermediate, advanced
}
```

### Recipe Metadata
```swift
@Observable final class RecipeMetadata: Codable {
    let id: String
    var tags: Set<String>
    var cuisineType: CuisineType
    var dietary: Set<DietaryTag>
    var difficulty: DifficultyLevel
    var confidence: Double
    
    /// Example:
    /// ```swift
    /// let metadata = RecipeMetadata(
    ///     tags: ["pasta", "quick"],
    ///     cuisineType: .italian,
    ///     dietary: [.vegetarian],
    ///     difficulty: .beginner,
    ///     confidence: 0.92
    /// )
    /// ```
}
```

## AI Service
```swift
final class OpenAIContentService {
    private let openAI: OpenAI
    private let frameExtractor: VideoFrameExtractor
    
    /// Analyzes exercise video for classification
    /// - Parameters:
    ///   - url: Video file URL
    /// - Returns: ExerciseClassification
    /// - Throws: AIError
    func analyzeExercise(url: URL) async throws -> ExerciseClassification {
        let frames = try await frameExtractor.extractKeyFrames(from: url)
        let prompt = ExercisePrompt.classification(frames: frames)
        return try await processExerciseAnalysis(prompt: prompt)
    }
    
    /// Generates recipe metadata from video
    /// - Parameters:
    ///   - url: Video file URL
    /// - Returns: RecipeMetadata
    /// - Throws: AIError
    func generateRecipeMetadata(url: URL) async throws -> RecipeMetadata {
        let frames = try await frameExtractor.extractKeyFrames(from: url)
        let prompt = RecipePrompt.metadata(frames: frames)
        return try await processRecipeAnalysis(prompt: prompt)
    }
}
```

## Prompts
```swift
enum ExercisePrompt {
    static func classification(frames: [UIImage]) -> String {
        """
        Analyze these exercise video frames and provide:
        1. Primary muscle groups targeted (core, upperBody, lowerBody, fullBody)
        2. Difficulty level (beginner, intermediate, advanced)
        3. Required equipment
        4. Estimated calories burned
        Provide response in JSON format with confidence scores.
        """
    }
}

enum RecipePrompt {
    static func metadata(frames: [UIImage]) -> String {
        """
        Analyze these cooking video frames and provide:
        1. Relevant tags
        2. Cuisine type
        3. Dietary considerations
        4. Difficulty level
        Provide response in JSON format with confidence scores.
        """
    }
}
```

## Error Handling
```swift
enum AIError: Error {
    case apiError(String)
    case rateLimitExceeded
    case lowConfidence
    case invalidResponse
    case frameExtractionFailed
    
    var userMessage: String {
        switch self {
        case .apiError: "Analysis failed"
        case .rateLimitExceeded: "Please try again later"
        case .lowConfidence: "Unable to determine classification"
        case .invalidResponse: "Invalid response from AI"
        case .frameExtractionFailed: "Unable to process video"
        }
    }
}
```

## Performance Requirements
- Analysis time: < 3 seconds per video
- Frame extraction: < 1 second
- API response time: < 2 seconds
- Minimum confidence: 70%
- Maximum frames per analysis: 5

## Cost Management
```swift
struct AIConfig {
    static let maxRequestsPerMinute = 50
    static let maxRequestsPerDay = 1000
    static let costPerRequest = 0.01
    static let confidenceThreshold = 0.7
    
    static func isWithinLimits(requestCount: Int) -> Bool {
        requestCount < maxRequestsPerDay
    }
}
```

## Testing Requirements
```swift
final class OpenAIServiceTests: XCTestCase {
    /// Tests exercise classification accuracy
    func testExerciseClassification() async throws {
        let result = try await service.analyzeExercise(mockVideoURL)
        XCTAssertGreaterThan(result.confidence, AIConfig.confidenceThreshold)
    }
    
    /// Tests recipe metadata generation
    func testRecipeMetadataGeneration() async throws {
        let result = try await service.generateRecipeMetadata(mockVideoURL)
        XCTAssertGreaterThan(result.confidence, AIConfig.confidenceThreshold)
    }
    
    /// Tests performance metrics
    func testAIPerformance() async throws {
        measure {
            // Test response times and memory usage
        }
    }
}
```

## File Organization
/Features/AI/
├── Services/
│   ├── OpenAIContentService.swift
│   └── VideoFrameExtractor.swift
├── Models/
│   ├── ExerciseClassification.swift
│   └── RecipeMetadata.swift
├── Utils/
│   ├── Prompts.swift
│   └── AIConfig.swift
└── Tests/
    └── OpenAIServiceTests.swift

## Week 1 Success Criteria
1. OpenAI Integration
   - API setup
   - Error handling
   - Rate limiting
   - Cost monitoring

2. Basic Analysis
   - Exercise classification
   - Recipe metadata
   - Confidence scoring

3. Performance
   - Meet response times
   - Stay within rate limits
   - Maintain confidence threshold

4. Testing
   - Unit test coverage
   - Performance metrics
   - Error scenarios

## Notes
- Monitor API costs
- Cache responses when possible
- Implement rate limiting
- Log confidence scores
- Handle API outages 