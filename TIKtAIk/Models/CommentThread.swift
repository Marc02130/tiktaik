struct CommentThread: Identifiable, Equatable {
    var comment: Comment
    var replies: [Comment]
    var isExpanded: Bool = false
    
    var id: String { comment.id }
    
    static func == (lhs: CommentThread, rhs: CommentThread) -> Bool {
        lhs.id == rhs.id &&
        lhs.comment == rhs.comment &&
        lhs.replies == rhs.replies &&
        lhs.isExpanded == rhs.isExpanded
    }
} 