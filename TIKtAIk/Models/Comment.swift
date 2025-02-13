//
// Comment.swift
// TIKtAIk
//
// Created: 2024-02-14
// Last modified: 2024-02-14
//
// Purpose: Model for video comments
// Author: Assistant
// Copyright © 2024 TIKtAIk. All rights reserved.
//

import Foundation
import FirebaseFirestore

/// Comment model for videos
struct Comment: Identifiable, Codable, Equatable {
    /// Unique comment identifier
    let id: String
    /// Associated video ID
    let videoId: String
    /// Commenter's user ID
    let userId: String
    /// Parent comment ID for replies
    let parentId: String?
    /// Comment text content
    let content: String
    /// Number of likes
    var likesCount: Int
    /// Number of replies
    var replyCount: Int
    /// Creation timestamp
    let createdAt: Date
    /// Last update timestamp
    var updatedAt: Date
    
    /// Firestore collection name
    static let collectionName = "videoComments"
    
    /// Creates Firestore data dictionary
    var asDictionary: [String: Any] {
        let dict: [String: Any] = [
            "id": id,
            "userId": userId,
            "videoId": videoId,
            "parentId": parentId as Any,
            "content": content,
            "likesCount": likesCount,
            "replyCount": replyCount,
            "createdAt": Timestamp(date: createdAt),
            "updatedAt": Timestamp(date: updatedAt)
        ]
        return dict
    }
    
    init(
        id: String,
        userId: String,
        videoId: String,
        parentId: String? = nil,
        content: String,
        likesCount: Int,
        replyCount: Int,
        createdAt: Date,
        updatedAt: Date
    ) {
        self.id = id
        self.userId = userId
        self.videoId = videoId
        self.parentId = parentId
        self.content = content
        self.likesCount = likesCount
        self.replyCount = replyCount
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    static func from(_ document: QueryDocumentSnapshot) throws -> Comment {
        let data = document.data()
        
        guard let userId = data["userId"] as? String,
              let videoId = data["videoId"] as? String,
              let content = data["content"] as? String,
              let likesCount = data["likesCount"] as? Int,
              let replyCount = data["replyCount"] as? Int,
              let createdTimestamp = data["createdAt"] as? Timestamp,
              let updatedTimestamp = data["updatedAt"] as? Timestamp
        else {
            throw CommentError.invalidData
        }
        
        return Comment(
            id: document.documentID,
            userId: userId,
            videoId: videoId,
            parentId: data["parentId"] as? String,
            content: content,
            likesCount: likesCount,
            replyCount: replyCount,
            createdAt: createdTimestamp.dateValue(),
            updatedAt: updatedTimestamp.dateValue()
        )
    }
    
    static func == (lhs: Comment, rhs: Comment) -> Bool {
        lhs.id == rhs.id &&
        lhs.userId == rhs.userId &&
        lhs.videoId == rhs.videoId &&
        lhs.parentId == rhs.parentId &&
        lhs.content == rhs.content &&
        lhs.likesCount == rhs.likesCount &&
        lhs.replyCount == rhs.replyCount &&
        lhs.createdAt == rhs.createdAt &&
        lhs.updatedAt == rhs.updatedAt
    }
}

/// Errors related to comment operations
enum CommentError: LocalizedError {
    case notAuthenticated
    case invalidComment
    case operationFailed
    case invalidData
    case failedToLoad
    case failedToAdd
    case networkError
    case invalidContent
    
    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "User must be authenticated"
        case .invalidComment:
            return "Invalid comment"
        case .operationFailed:
            return "Operation failed"
        case .invalidData:
            return "Invalid comment data"
        case .failedToLoad:
            return "Unable to load comments"
        case .failedToAdd:
            return "Failed to add comment"
        case .networkError:
            return "Network connection error"
        case .invalidContent:
            return "Invalid comment content"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .notAuthenticated:
            return "Please sign in to continue"
        case .invalidComment, .invalidData:
            return "Please try again with valid content"
        case .operationFailed:
            return "Please try again"
        case .failedToLoad:
            return "Pull down to try again"
        case .failedToAdd:
            return "Please try again"
        case .networkError:
            return "Check your internet connection"
        case .invalidContent:
            return "Comment cannot be empty"
        }
    }
} 