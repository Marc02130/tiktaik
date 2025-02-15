import SwiftUI

struct CommentAnalysisSection: View {
    let videoId: String
    @StateObject var viewModel: CommentAnalysisViewModel
    @EnvironmentObject var editViewModel: VideoEditViewModel
    
    init(videoId: String) {
        self.videoId = videoId
        self._viewModel = StateObject(wrappedValue: CommentAnalysisViewModel(videoId: videoId))
    }
    
    var body: some View {
        Section("Comment Analysis") {
            if let analytics = viewModel.analytics {
                // Status
                StatusView(status: analytics.batchStatus)
                
                if analytics.commentCount > 0 {
                    // Metrics
                    MetricsCard(metrics: analytics.aggregateMetrics)
                    
                    // Next analysis time
                    Text("Next analysis: \(analytics.nextScheduledAnalysis.formatted())")
                } else if editViewModel.allowComments {
                    Text("No comments to analyze")
                        .foregroundStyle(.secondary)
                } else {
                    Text("Comments are disabled")
                        .foregroundStyle(.secondary)
                }
            } else {
                ProgressView()
                    .frame(maxWidth: .infinity)
            }
        }
        .task {
            await viewModel.loadAnalytics()
        }
        .onAppear {
            viewModel.observeAnalytics()
        }
    }
}

private struct StatusView: View {
    let status: VideoAnalytics.BatchStatus
    
    var body: some View {
        HStack {
            Text("Status:")
            Spacer()
            switch status {
            case .pending:
                Text("Pending")
                    .foregroundColor(.secondary)
            case .processing:
                Text("Processing")
                    .foregroundColor(.blue)
            case .completed:
                Text("Completed")
                    .foregroundColor(.green)
            case .failed:
                Text("Failed")
                    .foregroundColor(.red)
            }
        }
    }
}

private struct MetricsCard: View {
    let metrics: VideoAnalytics.AggregateMetrics
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Sentiment
            HStack {
                Text("Sentiment:")
                Spacer()
                Text(String(format: "%.1f", metrics.averageSentiment))
            }
            
            // Engagement
            HStack {
                Text("Engagement:")
                Spacer()
                Text(String(format: "%.1f", metrics.engagementScore))
            }
            
            // Top topics
            if !metrics.topTopics.isEmpty {
                Text("Top Topics:")
                    .padding(.top, 4)
                ForEach(metrics.topTopics.sorted(by: { $0.value > $1.value }).prefix(3), id: \.key) { topic, count in
                    HStack {
                        Text("• \(topic)")
                        Spacer()
                        Text("\(count)")
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(10)
    }
} 