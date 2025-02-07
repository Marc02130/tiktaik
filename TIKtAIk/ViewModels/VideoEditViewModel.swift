//
// VideoEditViewModel.swift
// TIKtAIk
//
// Created: 2024-02-14
// Last modified: 2024-02-14
//
// Purpose: View model for managing video editing operations
// Author: Assistant
// Copyright © 2024 TIKtAIk. All rights reserved.
//

// Framework: SwiftUI - UI Framework
import SwiftUI
// Framework: AVKit - Video Playback
import AVKit
// Framework: FirebaseFirestore - Cloud Database
import FirebaseFirestore
// Framework: FirebaseStorage - Cloud Storage
import FirebaseStorage

/// View model managing video editing operations
///
/// Handles:
/// - Loading video data
/// - Managing edit state
/// - Saving changes to Firestore
@MainActor
final class VideoEditViewModel: ObservableObject {
    /// ID of video being edited
    let videoId: String
    /// Video title
    @Published var title = ""
    /// Video description
    @Published var description = ""
    /// Comma-separated tags
    @Published var tags = ""
    /// Whether video is private
    @Published var isPrivate = false
    /// Whether comments are allowed
    @Published var allowComments = true
    /// Video URL for playback
    @Published var videoURL: String?
    /// Video player instance
    @Published var player: AVPlayer?
    /// Whether changes are being saved
    @Published private(set) var isSaving = false
    /// Whether the video is being loaded
    @Published private(set) var isLoading = false
    /// Generated video thumbnails
    @Published private(set) var thumbnails: [UIImage]?
    /// Selected thumbnail index
    @Published var selectedThumbnailIndex = 0
    private let refreshTrigger: RefreshTrigger
    
    /// Current error message if any
    @Published private(set) var error: String?
    
    /// Clears the current error message
    func clearError() {
        error = nil
    }
    
    /// Initializes view model with video ID
    /// - Parameter videoId: Unique identifier of video to edit
    init(videoId: String, refreshTrigger: RefreshTrigger) {
        self.videoId = videoId
        self.refreshTrigger = refreshTrigger
    }
    
    /// Loads video data from Firestore
    func loadVideo() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let documentRef = Firestore.firestore()
                .collection(Video.collectionName)
                .document(videoId)
            
            let document = try await documentRef.getDocument()
            guard document.exists else {
                throw NSError(domain: "VideoEdit", code: -1, userInfo: [
                    NSLocalizedDescriptionKey: "Video not found"
                ])
            }
            
            // Use Firestore's built-in decoder
            let video = try document.data(as: Video.self, decoder: Firestore.Decoder())
            
            self.title = video.title
            self.description = video.description ?? ""
            self.tags = video.tags.joined(separator: ", ")
            self.isPrivate = video.isPrivate
            self.allowComments = video.allowComments
            self.videoURL = video.storageUrl
            
            if let url = URL(string: video.storageUrl) {
                self.player = AVPlayer(url: url)
            }
        } catch {
            self.error = error.localizedDescription
            print("Failed to load video:", error)
        }
    }
    
    /// Generates thumbnails from video
    func generateThumbnails() async {
        guard let player = player,
              let asset = player.currentItem?.asset as? AVURLAsset else { return }
        
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        
        // Get video duration
        let duration = try? await asset.load(.duration)
        let durationSeconds = duration.map { CMTimeGetSeconds($0) } ?? 0
        
        // Generate 5 thumbnails evenly spaced
        let timestamps = stride(from: 0, to: durationSeconds, by: durationSeconds/5)
            .map { CMTime(seconds: $0, preferredTimescale: 600) }
        
        do {
            var generatedThumbnails: [UIImage] = []
            
            for time in timestamps {
                let imageResult = try await generator.image(at: time)
                let thumbnail = UIImage(cgImage: imageResult.image)
                generatedThumbnails.append(thumbnail)
            }
            
            self.thumbnails = generatedThumbnails
            
        } catch {
            print("Failed to generate thumbnails:", error)
        }
    }
    
    /// Updates video with selected thumbnail
    @MainActor
    private func updateThumbnail() async throws {
        guard let thumbnailImage = thumbnails?[selectedThumbnailIndex],
              let thumbnailData = thumbnailImage.jpegData(compressionQuality: 0.8) else { return }
        
        let thumbnailRef = Storage.storage().reference()
            .child("thumbnails/\(videoId).jpg")
        
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        
        _ = try await thumbnailRef.putDataAsync(thumbnailData, metadata: metadata)
        let thumbnailURL = try await thumbnailRef.downloadURL()
        
        let updateData: [String: Any] = ["thumbnailUrl": thumbnailURL.absoluteString as String]
        
        try await Firestore.firestore()
            .collection(Video.collectionName)
            .document(videoId)
            .updateData(updateData)
    }
    
    /// Saves video changes to Firestore
    func saveChanges() async {
        isSaving = true
        defer { isSaving = false }
        
        do {
            // First try thumbnail update
            do {
                try await updateThumbnail()
            } catch {
                print("Failed to update thumbnail:", error)
                // Continue with metadata update even if thumbnail fails
            }
            
            // Update metadata
            let updateData: [String: Any] = [
                "title": title,
                "description": description,
                "isPrivate": isPrivate,
                "allowComments": allowComments,
                "updatedAt": Timestamp(date: Date()),
                "tags": Set(tags.split(separator: ",").map { String($0).trimmingCharacters(in: .whitespaces) }),
                "metadata": [
                    "lastModified": Timestamp(date: Date())
                ]
            ]
            
            print("Updating video with data:", updateData)
            
            try await Firestore.firestore()
                .collection(Video.collectionName)
                .document(videoId)
                .updateData(updateData)
            
            print("Video update successful")
            refreshTrigger.triggerRefresh()
            
        } catch {
            print("Failed to save changes:", error.localizedDescription)
            await MainActor.run {
                self.error = "Failed to save changes: \(error.localizedDescription)"
            }
        }
    }
}

enum VideoEditError: LocalizedError {
    case invalidVideo
    case updateFailed
    
    var errorDescription: String? {
        switch self {
        case .invalidVideo:
            return "Invalid video data"
        case .updateFailed:
            return "Failed to update video"
        }
    }
} 