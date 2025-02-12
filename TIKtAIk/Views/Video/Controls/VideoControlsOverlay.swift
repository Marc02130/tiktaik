import SwiftUI

struct VideoControlsOverlay: View {
    let video: Video
    let stats: Video.Stats
    let onLike: () -> Void
    let onComment: () -> Void
    let onShare: () -> Void
    
    var body: some View {
        VStack {
            Spacer()
            HStack {
                // Video info
                VStack(alignment: .leading) {
                    Text(video.title)
                        .font(.headline)
                    Text("@\(video.userId)")
                        .font(.subheadline)
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
        }
    }
} 