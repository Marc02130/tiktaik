//
// VideoLibraryViewModel.swift
// TIKtAIk
//
// Created: 2024-02-14
// Last modified: 2024-02-14
//
// Purpose: View model for managing video library operations
// Author: Assistant
// Copyright © 2024 TIKtAIk. All rights reserved.
//

// Framework: SwiftUI - UI Framework
import SwiftUI
// Framework: FirebaseAuth - Authentication
import FirebaseAuth
// Framework: FirebaseFirestore - Cloud Database
import FirebaseFirestore

/// View model managing video library operations
///
/// Handles:
/// - Loading user's videos
/// - Managing video selection
/// - Error handling
@MainActor
final class VideoLibraryViewModel: ObservableObject {
    /// Currently loaded videos
    @Published private(set) var videos: [Video] = []
    /// Currently selected video for editing
    @Published var selectedVideo: Video?
    /// Current error message if any
    @Published private(set) var error: String?
    /// Whether videos are currently loading
    @Published private(set) var isLoading = false
    
    /// Loads user's videos from Firestore
    func loadVideos() async {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            // Use a simpler query until index is created
            let snapshot = try await Firestore.firestore()
                .collection(Video.collectionName)
                .whereField("userId", isEqualTo: userId)
                // Remove ordering until index is created
                //.order(by: "createdAt", descending: true)
                .getDocuments()
            
            self.videos = try snapshot.documents.map { try Video.from($0) }
            self.error = nil
            
        } catch {
            self.error = error.localizedDescription
            print("Error loading videos:", error)
            
            // If error is about missing index, provide guidance
            if error.localizedDescription.contains("requires an index") {
                self.error = "Database setup required. Please contact support."
            }
        }
    }
} 