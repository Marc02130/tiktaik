import SwiftUI
import Combine
import FirebaseFirestore

@MainActor
class VideoStatsViewModel: ObservableObject {
    @Published private(set) var stats: Video.Stats
    @Published var isLiked = false
    
    private let video: Video
    private let db = Firestore.firestore()
    
    init(video: Video) {
        self.video = video
        self.stats = video.stats
    }
    
    func toggleLike() {
        isLiked.toggle()
        Task {
            do {
                try await db.collection(Video.collectionName)
                    .document(video.id)
                    .updateData([
                        "stats.likes": FieldValue.increment(Int64(isLiked ? 1 : -1))
                    ] as [String: Any])
                
                // Update local stats
                stats.likes += isLiked ? 1 : -1
            } catch {
                print("Error updating like:", error)
                isLiked.toggle() // Revert on error
            }
        }
    }
    
    func showComments() {
        // Comments logic - will be implemented later
    }
    
    func shareVideo() {
        // Share logic - will be implemented later
    }
    
    func incrementViews() {
        Task {
            do {
                try await db.collection(Video.collectionName)
                    .document(video.id)
                    .updateData([
                        "stats.views": FieldValue.increment(Int64(1))
                    ] as [String: Any])
                
                // Update local stats
                stats.views += 1
            } catch {
                print("Error incrementing views:", error)
            }
        }
    }
} 