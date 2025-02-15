# AI Comment Analysis Requirements

## User Requirements

1. Comment Analysis
- Analyze comments in batches by video
- Show analysis status per video
- Display batch processing timestamp
- Provide video-level engagement metrics
+ Access comment analysis through VideoEditView
+ Show analysis results in dedicated section
+ Display next scheduled analysis time

## Technical Requirements

1. Firebase Cloud Functions
```typescript
// Cloud Function triggered every 10 minutes
exports.processCommentBatches = functions.pubsub
  .schedule('every 10 minutes')
  .onRun(async context => {
    // Process unanalyzed comments
  });
```

2. Data Structures
```swift
struct VideoAnalytics: Codable {
    let videoId: String
    let lastProcessedAt: Date
    let commentCount: Int
    let batchStatus: BatchStatus
    let aggregateMetrics: AggregateMetrics
    
    enum BatchStatus: String {
        case pending
        case processing
        case completed
        case failed
    }
    
    struct AggregateMetrics {
        let averageSentiment: Double
        let topTopics: [String: Int]
        let engagementScore: Double
        let processedComments: Int
    }
}
```

3. Firestore Schema
```swift
Collection: "videoAnalytics"
Document: {
    videoId: String
    lastProcessedAt: Timestamp
    batchStatus: String
    metrics: {
        sentiment: Double
        topics: Map<String, Int>
        engagement: Double
        processedCount: Int
    }
}
```

4. iOS Integration
```swift
struct CommentAnalysisSection: View {
    let videoId: String
    @StateObject var analysisViewModel: CommentAnalysisViewModel
    
    var body: some View {
        Section("Comment Analysis") {
            // Status display
            StatusView(status: analysisViewModel.analytics?.batchStatus)
            
            // Metrics display if available
            if let metrics = analysisViewModel.analytics?.aggregateMetrics {
                MetricsCard(metrics: metrics)
            }
            
            // Next scheduled analysis time
            Text("Next analysis: \(scheduler.getNextBatchTime(for: videoId))")
        }
    }
}

class CommentAnalysisViewModel: ObservableObject {
    @Published var analytics: VideoAnalytics?
    @Published var isAnalyzing: Bool = false
    
    func loadAnalytics() async
    func observeAnalytics()
}

extension VideoAnalytics {
    var nextScheduledAnalysis: Date {
        lastProcessedAt.addingTimeInterval(600) // 10 minutes
    }
    
    var isScheduledSoon: Bool {
        nextScheduledAnalysis.timeIntervalSinceNow < 300 // 5 minutes
    }
}
```

5. Performance Requirements
- Cloud Function timeout < 5 minutes
- Process up to 100 comments per batch
- Handle up to 5 concurrent video batches
- Maintain Firestore write limits

6. Error Handling
```swift
enum AnalysisError: Error {
    case analysisInProgress
    case noNewComments
    case fetchFailed
    case updateFailed
}
```

## Implementation Notes

1. Processing Flow
```
1. Cloud Function triggers every 10 minutes
2. Query videos with unprocessed comments
3. Process batches on server
4. Update Firestore
5. iOS app observes changes
```

2. iOS Responsibilities
- Display current analysis status
- Show analysis results
- Update UI on Firestore changes
- Cache results for performance

3. Cloud Function Responsibilities
- Schedule and run batches
- Process comments with LangChain
- Update Firestore documents
- Handle errors and retries