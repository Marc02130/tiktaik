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
struct Comment: Identifiable, Codable {
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
}

/// Errors related to comment operations
enum CommentError: LocalizedError {
    case notAuthenticated
    case invalidComment
    case operationFailed
    case invalidData
    
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
        }
    }
} 