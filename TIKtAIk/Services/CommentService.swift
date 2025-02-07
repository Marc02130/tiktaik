//
// CommentService.swift
// TIKtAIk
//
// Created: 2024-02-14
// Last modified: 2024-02-14
//
// Purpose: Manages video comments and replies
// Author: Assistant
// Copyright © 2024 TIKtAIk. All rights reserved.
//

import Foundation
import FirebaseFirestore
import FirebaseAuth

@Observable final class CommentService {
    private let db = Firestore.firestore()
    private let auth = Auth.auth()
    
    /// Fetches comments for a video
    /// - Parameters:
    ///   - videoId: Video ID to fetch comments for
    ///   - limit: Maximum number of comments to fetch
    ///   - lastComment: Last comment from previous fetch for pagination
    func fetchComments(videoId: String, limit: Int = 20, lastComment: Comment? = nil) async throws -> [Comment] {
        var query = db.collection("videoComments")
            .whereField("videoId", isEqualTo: videoId)
            .order(by: "createdAt", descending: true)
            .limit(to: limit)
        
        if let lastComment = lastComment {
            query = query.start(after: [lastComment.createdAt])
        }
        
        let snapshot = try await query.getDocuments()
        return try snapshot.documents.map { try Comment.from($0) }
    }
    
    /// Adds a comment to a video
    /// - Parameters:
    ///   - videoId: Video to comment on
    ///   - content: Comment text
    func addComment(videoId: String, content: String) async throws -> Comment {
        guard let userId = auth.currentUser?.uid else {
            throw CommentError.notAuthenticated
        }
        
        let batch = db.batch()
        
        // Create comment
        let commentRef = db.collection(Comment.collectionName).document()
        let comment = Comment(
            id: commentRef.documentID,
            userId: userId,
            videoId: videoId,
            parentId: nil, // Top-level comment
            content: content,
            likesCount: 0,
            replyCount: 0,
            createdAt: Date(),
            updatedAt: Date()
        )
        
        batch.setData(comment.asDictionary, forDocument: commentRef)
        
        // Update video stats
        let videoRef = db.collection(Video.collectionName).document(videoId)
        batch.updateData([
            "stats.commentsCount": FieldValue.increment(Int64(1))
        ], forDocument: videoRef)
        
        try await batch.commit()
        return comment
    }
} 