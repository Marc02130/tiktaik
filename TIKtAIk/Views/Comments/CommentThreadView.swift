import SwiftUI
import FirebaseAuth

struct CommentThreadView: View {
    let thread: CommentThread
    let onReply: (Comment) -> Void
    let onToggle: () -> Void
    let onDelete: (Comment) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Parent comment
            CommentRow(
                comment: thread.comment,
                onReply: { onReply(thread.comment) },
                onDelete: { onDelete(thread.comment) },
                onToggle: onToggle
            )
            
            // Replies
            if thread.isExpanded && !thread.replies.isEmpty {
                ForEach(thread.replies) { reply in
                    CommentRow(
                        comment: reply,
                        onReply: { onReply(reply) },
                        onDelete: { onDelete(reply) },
                        onToggle: nil
                    )
                    .padding(.leading)
                }
            }
        }
    }
} 