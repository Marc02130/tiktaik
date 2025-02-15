import Foundation
import FirebaseFirestore

@MainActor
class CommentAnalysisViewModel: ObservableObject {
    @Published var analytics: VideoAnalytics?
    @Published var isAnalyzing: Bool = false
    
    private let videoId: String
    private let firestore = Firestore.firestore()
    private var listener: ListenerRegistration?
    
    init(videoId: String) {
        self.videoId = videoId
    }
    
    func loadAnalytics() async {
        do {
            let snapshot = try await firestore
                .collection("videoAnalytics")
                .document(videoId)
                .getDocument()
            
            if let data = snapshot.data() {
                self.analytics = try VideoAnalytics.from(data)
            } else {
                // Create initial analytics for video with no comments
                let initialAnalytics = VideoAnalytics(
                    videoId: videoId,
                    lastProcessedAt: Date(),
                    commentCount: 0,
                    batchStatus: .completed,
                    aggregateMetrics: .empty
                )
                
                try await firestore
                    .collection("videoAnalytics")
                    .document(videoId)
                    .setData(initialAnalytics.asDictionary)
                
                self.analytics = initialAnalytics
            }
        } catch {
            print("ERROR: Failed to load analytics:", error)
        }
    }
    
    func observeAnalytics() {
        listener = firestore
            .collection("videoAnalytics")
            .document(videoId)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self,
                      let data = snapshot?.data() else { return }
                
                do {
                    self.analytics = try VideoAnalytics.from(data)
                } catch {
                    print("ERROR: Failed to parse analytics:", error)
                }
            }
    }
    
    deinit {
        listener?.remove()
    }
} 