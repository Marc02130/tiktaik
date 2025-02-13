# Technical Requirements - Week 1 Minimum

## Core Infrastructure
```swift
// Framework Dependencies
import SwiftUI          // UI Framework
import AVFoundation     // Video Processing
import Firebase        // Backend Services

struct VideoMetadata {
    let id: String
    let title: String              // Required
    let description: String        // Required
    let creatorType: CreatorType   // Required
    let group: String              // Required (genre/subject/cuisine/etc)
    let tags: [String]             // Optional
    let customFields: [String: Any] // Dynamic fields from Firestore
}

protocol VideoUploadService {
    /// Uploads video with metadata
    func uploadVideo(url: URL, metadata: VideoMetadata) async throws -> URL
}

struct VideoProcessingConfig {
    static let maxSize = 500 * 1024 * 1024  // 500MB
    static let supportedFormats = ["mp4", "mov"]
}
```

## Data Management
```swift
struct FirebaseConfig {
    static let videos = "videos"
    static let metadata = "metadata_configs"
}

protocol DataService {
    func saveMetadata(_ metadata: VideoMetadata, userId: String) async throws
    func getMetadata(contentId: String) async throws -> VideoMetadata
    func getCreatorTypeConfig(type: CreatorType) async throws -> [String: Any]
}

protocol AnalyticsService {
    /// Viewer Retention
    func getRetentionMetrics(videoId: String) async throws -> RetentionMetrics
    func getEngagementMetrics(videoId: String) async throws -> EngagementMetrics
    func getGeographicMetrics(videoId: String) async throws -> GeographicMetrics
    func getDeviceMetrics(videoId: String) async throws -> DeviceMetrics
}

struct RetentionMetrics {
    let averageWatchDuration: TimeInterval
    let watchCompletionRate: Double  // Percentage who finish the video
    let dropOffPoints: [TimeInterval: Int]  // Time points where viewers leave
    let replaySegments: [TimeInterval: Int] // Most replayed segments
}

struct EngagementMetrics {
    let viewCount: Int
    let uniqueViewers: Int
    let likes: Int
    let shares: Int
    let comments: Int
    let saveCount: Int
    let engagementRate: Double  // (likes + shares + comments) / views
}

struct GeographicMetrics {
    let viewsByCountry: [String: Int]  // Country code: view count
    let viewsByCity: [String: Int]     // City: view count
    let topLocations: [String]         // Top 10 locations
}

struct DeviceMetrics {
    let deviceTypes: [String: Int]     // iPhone, iPad, etc: count
    let osVersions: [String: Int]      // iOS version: count
    let appVersions: [String: Int]     // App version: count
    let networkTypes: [String: Int]    // WiFi, Cellular: count
}

struct CommentMetrics {
    let totalComments: Int
    let commentSentiment: SentimentScore
    let topComments: [Comment]        // Most liked/engaged comments
    let commentTimestamps: [TimeInterval: Int]  // Comment frequency over video duration
    let responseRate: Double          // Creator response rate to comments
    let averageResponseTime: TimeInterval
}

struct SentimentScore {
    let positive: Double  // 0-1 score
    let negative: Double  // 0-1 score
    let neutral: Double   // 0-1 score
    let keywords: [String: Int]  // Common keywords and their frequency
}

struct Comment {
    let id: String
    let text: String
    let timestamp: Date
    let likes: Int
    let replies: Int
    let hasCreatorResponse: Bool
    let sentiment: SentimentScore
}

extension AnalyticsService {
    /// Comment Analysis
    func getCommentMetrics(videoId: String) async throws -> CommentMetrics
    func getCommentSentiment(commentId: String) async throws -> SentimentScore
    func getTopComments(videoId: String, limit: Int) async throws -> [Comment]
}
```
