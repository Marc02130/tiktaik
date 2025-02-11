//
// VideoDeleteService.swift
// TIKtAIk
//
// Created: 2024-02-14
// Last modified: 2024-02-14
//
// Purpose: Service for managing video deletion
// Author: Assistant
// Copyright © 2024 TIKtAIk. All rights reserved.
//

import Foundation
import FirebaseFirestore
import FirebaseStorage
import FirebaseAuth

@Observable final class VideoDeleteService {
    private let db = Firestore.firestore()
    private let storage = Storage.storage()
    private let auth = Auth.auth()
    
    /// Deletes a video and all associated data
    /// - Parameter video: Video to delete
    /// - Throws: VideoDeleteError if deletion fails
    func deleteVideo(_ video: Video) async throws {
        // Verify ownership
        guard let currentUserId = auth.currentUser?.uid else {
            throw VideoDeleteError.notAuthenticated
        }
        
        guard video.userId == currentUserId else {
            throw VideoDeleteError.notAuthorized
        }
        
        // Delete video file from storage first
        do {
            // Extract filename from storageUrl (e.g. "videos/25D24EAF-07D0-4DFB-86E6-48C66F14BCE4.mp4")
            let storageRef = storage.reference().child(video.storageUrl)
            try await storageRef.delete()
            
            // Delete thumbnail if exists
            if let thumbnailUrl = video.thumbnailUrl {
                let thumbnailRef = storage.reference().child(thumbnailUrl)
                try? await thumbnailRef.delete()
            }
            
            // Start batch operation for Firestore cleanup
            let batch = db.batch()
            
            // Delete video document
            let videoRef = db.collection(Video.collectionName).document(video.id)
            batch.deleteDocument(videoRef)
            
            // Delete associated data
            let collections = ["videoLikes", "videoComments", "videoShares"]
            for collection in collections {
                let querySnapshot = try await db.collection(collection)
                    .whereField("videoId", isEqualTo: video.id)
                    .getDocuments()
                
                for doc in querySnapshot.documents {
                    batch.deleteDocument(doc.reference)
                }
            }
            
            // Commit all Firestore changes
            try await batch.commit()
            
        } catch let error as StorageError {
            print("Storage error deleting video:", error)
            throw VideoDeleteError.deleteFailed(error.localizedDescription)
        } catch {
            print("Error deleting video:", error)
            throw VideoDeleteError.deleteFailed(error.localizedDescription)
        }
    }
}

enum VideoDeleteError: LocalizedError {
    case notAuthenticated
    case notAuthorized
    case deleteFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "You must be signed in to delete videos"
        case .notAuthorized:
            return "You can only delete your own videos"
        case .deleteFailed(let reason):
            return "Failed to delete video: \(reason)"
        }
    }
} 