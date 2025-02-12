import SwiftUI
import FirebaseFirestore

struct VideoControlsOverlay: View {
    let video: Video
    let stats: Video.Stats
    let onLike: () -> Void
    let onComment: () -> Void
    let onShare: () -> Void
    
    @State private var username: String = ""
    
    var body: some View {
        VStack {
            Spacer()  // Push everything to bottom
            
            HStack(alignment: .bottom) {
                // Video info
                VStack(alignment: .leading) {
                    Text(video.title)
                        .font(.headline)
                    Text("@\(username)")
                        .font(.subheadline)
                        .onAppear {
                            Task {
                                // Get username from Firestore
                                if let userData = try? await Firestore.firestore()
                                    .collection("users")
                                    .document(video.userId)
                                    .getDocument()
                                    .data(),
                                   let username = userData["username"] as? String {
                                    await MainActor.run {
                                        self.username = username
                                    }
                                }
                            }
                        }
                }
                .foregroundColor(.white)
                .shadow(radius: 2)
                
                Spacer()
                
                // Interaction buttons
                VStack(spacing: 16) {
                    InteractionButton(
                        icon: "heart.fill",
                        count: stats.likes,
                        action: onLike
                    )
                    
                    InteractionButton(
                        icon: "message.fill",
                        count: stats.commentsCount,
                        action: onComment
                    )
                    
                    InteractionButton(
                        icon: "square.and.arrow.up.fill",
                        count: stats.shares,
                        action: onShare
                    )
                }
            }
            .padding()
            .padding(.bottom, 70) // Account for tab bar
        }
    }
} 