//
// EngagementService.swift
// TIKtAIk
//
// Created: 2024-02-14
// Last modified: 2024-02-14
//
// Purpose: Manages video engagement (likes, views, shares)
// Author: Assistant
// Copyright © 2024 TIKtAIk. All rights reserved.
//

import Foundation
import FirebaseFirestore
import FirebaseAuth

@Observable final class EngagementService {
    private let db = Firestore.firestore()
    private let auth = Auth.auth()
    
    /// Records a video view
    /// - Parameter videoId: ID of viewed video
    func recordView(videoId: String) async throws {
        guard let userId = auth.currentUser?.uid else { return }
        
        let batch = db.batch()
        
        // Update video stats
        let videoRef = db.collection(Video.collectionName).document(videoId)
        batch.updateData([
            "stats.views": FieldValue.increment(Int64(1))
        ], forDocument: videoRef)
        
        // Record view in history
        let viewRef = db.collection("videoViews").document()
        batch.setData([
            "userId": userId,
            "videoId": videoId,
            "timestamp": Timestamp(date: Date())
        ], forDocument: viewRef)
        
        try await batch.commit()
    }
    
    /// Toggles like status for video
    /// - Parameter videoId: ID of video to like/unlike
    /// - Returns: New like status
    func toggleLike(videoId: String) async throws -> Bool {
        guard let userId = auth.currentUser?.uid else {
            throw EngagementError.notAuthenticated
        }
        
        let likeRef = db.collection("videoLikes")
            .whereField("userId", isEqualTo: userId)
            .whereField("videoId", isEqualTo: videoId)
        
        let snapshot = try await likeRef.getDocuments()
        let batch = db.batch()
        let videoRef = db.collection(Video.collectionName).document(videoId)
        
        // If like exists, remove it
        if let existingLike = snapshot.documents.first {
            batch.deleteDocument(existingLike.reference)
            batch.updateData([
                "stats.likes": FieldValue.increment(Int64(-1))
            ], forDocument: videoRef)
            try await batch.commit()
            return false
        }
        
        // Otherwise, add new like
        let newLikeRef = db.collection("videoLikes").document()
        batch.setData([
            "userId": userId,
            "videoId": videoId,
            "timestamp": Timestamp(date: Date())
        ], forDocument: newLikeRef)
        
        batch.updateData([
            "stats.likes": FieldValue.increment(Int64(1))
        ], forDocument: videoRef)
        
        try await batch.commit()
        return true
    }
    
    /// Records a video share
    /// - Parameter videoId: ID of shared video
    func recordShare(videoId: String) async throws {
        guard let userId = auth.currentUser?.uid else { return }
        
        let batch = db.batch()
        
        // Update video stats
        let videoRef = db.collection(Video.collectionName).document(videoId)
        batch.updateData([
            "stats.shares": FieldValue.increment(Int64(1))
        ], forDocument: videoRef)
        
        // Record share
        let shareRef = db.collection("videoShares").document()
        batch.setData([
            "userId": userId,
            "videoId": videoId,
            "timestamp": Timestamp(date: Date())
        ], forDocument: shareRef)
        
        try await batch.commit()
    }
}

enum EngagementError: LocalizedError {
    case notAuthenticated
    case operationFailed
    
    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "User must be authenticated"
        case .operationFailed:
            return "Operation failed"
        }
    }
} 