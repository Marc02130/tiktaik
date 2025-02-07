//
// ShareService.swift
// TIKtAIk
//
// Created: 2024-02-14
// Last modified: 2024-02-14
//
// Purpose: Manages video sharing and activity
// Author: Assistant
// Copyright © 2024 TIKtAIk. All rights reserved.
//

import SwiftUI
import FirebaseFirestore
import FirebaseAuth

@MainActor
final class ShareService: ObservableObject {
    private let db = Firestore.firestore()
    private let auth = Auth.auth()
    
    /// Shares video and records activity
    /// - Parameter video: Video to share
    func shareVideo(_ video: Video) async throws {
        let activityVC = try await createShareSheet(for: video)
        try await presentShareSheet(activityVC)
        try await recordShare(videoId: video.id)
    }
    
    /// Creates and configures share sheet
    private func createShareSheet(for video: Video) async throws -> UIActivityViewController {
        let shareURL = URL(string: "tiktaik://video/\(video.id)")!
        
        return UIActivityViewController(
            activityItems: [
                video.title,
                shareURL
            ],
            applicationActivities: nil
        )
    }
    
    /// Presents share sheet on main thread
    @MainActor
    private func presentShareSheet(_ activityVC: UIActivityViewController) async throws {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first,
              let rootVC = window.rootViewController else {
            throw ShareError.presentationFailed
        }
        
        await withCheckedContinuation { continuation in
            rootVC.present(activityVC, animated: true) {
                continuation.resume()
            }
        }
    }
    
    /// Records share activity in Firestore
    private func recordShare(videoId: String) async throws {
        guard let userId = auth.currentUser?.uid else { return }
        
        let batch = db.batch()
        
        // Update video stats
        let videoRef = db.collection(Video.collectionName).document(videoId)
        batch.updateData([
            "stats.shares": FieldValue.increment(Int64(1))
        ], forDocument: videoRef)
        
        // Record share activity
        let shareRef = db.collection("videoShares").document()
        batch.setData([
            "userId": userId,
            "videoId": videoId,
            "timestamp": Timestamp(date: Date())
        ], forDocument: shareRef)
        
        try await batch.commit()
    }
}

enum ShareError: LocalizedError {
    case presentationFailed
    
    var errorDescription: String? {
        switch self {
        case .presentationFailed:
            return "Failed to present share sheet"
        }
    }
} 