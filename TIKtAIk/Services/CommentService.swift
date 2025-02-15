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
    let limit = 20
    
    /// Fetches comments for a video
    /// - Parameters:
    ///   - videoId: Video ID to fetch comments for
    ///   - limit: Maximum number of comments to fetch
    ///   - lastComment: Last comment from previous fetch for pagination
    func fetchComments(
        videoId: String, 
        limit: Int = 20,
        lastComment: Comment? = nil
    ) async throws -> (parents: [Comment], repliesByParent: [String: [Comment]]) {
        // First fetch parent comments with pagination
        var parentQuery = db.collection(Comment.collectionName)
            .whereField("videoId", isEqualTo: videoId)
            .whereField("parentId", isEqualTo: NSNull())
            .order(by: "createdAt", descending: true)
            .order(by: "id")
            .limit(to: limit)
        
        if let lastComment = lastComment {
            parentQuery = parentQuery.start(after: [
                lastComment.createdAt,
                lastComment.id
            ])
        }
        
        let parentResults = try await parentQuery.getDocuments()
        let parentComments = try parentResults.documents.map { try Comment.from($0) }
        
        // Then fetch replies for displayed parents
        if !parentComments.isEmpty {
            let parentIds = parentComments.map { $0.id }
            let repliesQuery = db.collection(Comment.collectionName)
                .whereField("parentId", in: parentIds)
                .order(by: "createdAt", descending: true)
            
            let repliesSnapshot = try await repliesQuery.getDocuments()
            let replies = try repliesSnapshot.documents.map { try Comment.from($0) }
            
            let repliesByParent = Dictionary(grouping: replies) { $0.parentId! }
            return (parentComments, repliesByParent)
        }
        
        return (parentComments, [:])
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
            parentId: nil,
            content: content,
            likesCount: 0,
            replyCount: 0,
            createdAt: Date(),
            updatedAt: Date(),
            analyzed: false
        )
        
        batch.setData(comment.asDictionary, forDocument: commentRef)
        
        // Don't update video stats here - getAllComments will handle it
        try await batch.commit()
        
        // Update total count
        let allComments = try await getAllComments(videoId: videoId)
        try await updateVideoCommentCount(videoId: videoId, count: allComments.count)
        
        return comment
    }
    
    /// Adds a reply to a comment
    /// - Parameters:
    ///   - parentComment: Comment being replied to
    ///   - content: Reply text content
    func addReply(to parentComment: Comment, content: String) async throws -> Comment {
        guard let userId = auth.currentUser?.uid else {
            throw CommentError.notAuthenticated
        }
        
        let batch = db.batch()
        
        // Create reply comment
        let replyRef = db.collection(Comment.collectionName).document()
        let reply = Comment(
            id: replyRef.documentID,
            userId: userId,
            videoId: parentComment.videoId,
            parentId: parentComment.id,
            content: content,
            likesCount: 0,
            replyCount: 0,
            createdAt: Date(),
            updatedAt: Date(),
            analyzed: false
        )
        
        batch.setData(reply.asDictionary, forDocument: replyRef)
        
        // Update parent comment's reply count
        let parentRef = db.collection(Comment.collectionName).document(parentComment.id)
        batch.updateData([
            "replyCount": FieldValue.increment(Int64(1))
        ], forDocument: parentRef)
        
        // Don't update video stats here - getAllComments will handle it
        try await batch.commit()
        
        // Update total count
        let allComments = try await getAllComments(videoId: parentComment.videoId)
        try await updateVideoCommentCount(videoId: parentComment.videoId, count: allComments.count)
        
        return reply
    }
    
    /// Update video's total comment count
    private func updateVideoCommentCount(videoId: String, count: Int) async throws {
        let videoRef = db.collection(Video.collectionName).document(videoId)
        try await videoRef.updateData([
            "stats.commentsCount": count
        ])
    }
    
    /// Get all comments for a video
    func getAllComments(videoId: String) async throws -> [Comment] {
        let query = db.collection(Comment.collectionName)
            .whereField("videoId", isEqualTo: videoId)
            .order(by: "createdAt", descending: true)
        
        let snapshot = try await query.getDocuments()
        let comments = try snapshot.documents.map { try Comment.from($0) }
        
        print("DEBUG: getAllComments found \(comments.count) total comments for video \(videoId)")
        
        // Update the video's total comment count
        try await updateVideoCommentCount(videoId: videoId, count: comments.count)
        
        return comments
    }
    
    /// Delete a comment and update related counts
    func deleteComment(_ comment: Comment) async throws {
        let batch = db.batch()
        
        // Delete the comment document
        let commentRef = db.collection(Comment.collectionName).document(comment.id)
        batch.deleteDocument(commentRef)
        
        // If this is a reply, update parent's reply count
        if let parentId = comment.parentId {
            let parentRef = db.collection(Comment.collectionName).document(parentId)
            batch.updateData([
                "replyCount": FieldValue.increment(Int64(-1))
            ], forDocument: parentRef)
        }
        
        // Update video's total comment count
        let videoRef = db.collection(Video.collectionName).document(comment.videoId)
        batch.updateData([
            "stats.commentsCount": FieldValue.increment(Int64(-1))
        ], forDocument: videoRef)
        
        try await batch.commit()
    }
}