import Foundation
import FirebaseFirestore

struct VideoAnalytics: Codable {
    let videoId: String
    let lastProcessedAt: Date
    let commentCount: Int
    let batchStatus: BatchStatus
    let aggregateMetrics: AggregateMetrics
    
    enum BatchStatus: String, Codable {
        case pending
        case processing
        case completed
        case failed
    }
    
    struct AggregateMetrics: Codable {
        let averageSentiment: Double
        let topTopics: [String: Int]
        let engagementScore: Double
        let processedComments: Int
    }
}

extension VideoAnalytics {
    var asDictionary: [String: Any] {
        [
            "videoId": videoId,
            "lastProcessedAt": Timestamp(date: lastProcessedAt),
            "commentCount": commentCount,
            "batchStatus": batchStatus.rawValue,
            "metrics": [
                "sentiment": aggregateMetrics.averageSentiment,
                "topics": aggregateMetrics.topTopics,
                "engagement": aggregateMetrics.engagementScore,
                "processedCount": aggregateMetrics.processedComments
            ]
        ]
    }
}

extension VideoAnalytics {
    static func from(_ data: [String: Any]) throws -> VideoAnalytics {
        guard let videoId = data["videoId"] as? String,
              let lastProcessedTimestamp = data["lastProcessedAt"] as? Timestamp,
              let commentCount = data["commentCount"] as? Int,
              let statusString = data["batchStatus"] as? String,
              let metrics = data["metrics"] as? [String: Any]
        else {
            throw AnalyticsError.invalidData
        }
        
        let status = BatchStatus(rawValue: statusString) ?? .failed
        
        guard let sentiment = metrics["sentiment"] as? Double,
              let topics = metrics["topics"] as? [String: Int],
              let engagement = metrics["engagement"] as? Double,
              let processedCount = metrics["processedCount"] as? Int
        else {
            throw AnalyticsError.invalidData
        }
        
        return VideoAnalytics(
            videoId: videoId,
            lastProcessedAt: lastProcessedTimestamp.dateValue(),
            commentCount: commentCount,
            batchStatus: status,
            aggregateMetrics: AggregateMetrics(
                averageSentiment: sentiment,
                topTopics: topics,
                engagementScore: engagement,
                processedComments: processedCount
            )
        )
    }
}

enum AnalyticsError: Error {
    case invalidData
}

extension VideoAnalytics {
    var nextScheduledAnalysis: Date {
        lastProcessedAt.addingTimeInterval(600) // 10 minutes
    }
    
    var isScheduledSoon: Bool {
        nextScheduledAnalysis.timeIntervalSinceNow < 300 // 5 minutes
    }
} 

extension VideoAnalytics.AggregateMetrics {
    static var empty: Self {
        .init(
            averageSentiment: 0,
            topTopics: [:],
            engagementScore: 0,
            processedComments: 0
        )
    }
}