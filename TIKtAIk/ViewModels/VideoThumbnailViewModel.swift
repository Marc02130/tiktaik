//
// VideoThumbnailViewModel.swift
// TIKtAIk
//
// Created: 2024-02-14
// Last modified: 2024-02-14
//

import SwiftUI
import AVKit
import FirebaseStorage
import FirebaseFirestore

@MainActor
final class VideoThumbnailViewModel: ObservableObject {
    let videoId: String
    
    @Published private(set) var thumbnails: [UIImage] = []
    @Published private(set) var isLoading = true
    @Published var selectedThumbnailIndex: Int?
    
    private let storage = Storage.storage()
    private let db = Firestore.firestore()
    
    init(videoId: String) {
        self.videoId = videoId
        Task {
            await loadThumbnails()
        }
    }
    
    private func loadThumbnails() async {
        do {
            // Get video URL from Firestore
            let doc = try await db.collection(Video.collectionName)
                .document(videoId)
                .getDocument()
            
            guard let videoData = doc.data(),
                  let storageUrl = videoData["storageUrl"] as? String else {
                throw VideoEditError.invalidVideo
            }
            
            // Get download URL
            let storageRef = storage.reference().child(storageUrl)
            let videoURL = try await storageRef.downloadURL()
            
            // Generate thumbnails
            let asset = AVURLAsset(url: videoURL)
            let duration = try await asset.load(.duration)
            let generator = AVAssetImageGenerator(asset: asset)
            generator.appliesPreferredTrackTransform = true
            
            // Generate 6 thumbnails evenly spaced
            let totalSeconds = CMTimeGetSeconds(duration)
            let timePoints = stride(from: 0.0, to: totalSeconds, by: totalSeconds/6)
            
            var newThumbnails: [UIImage] = []
            for time in timePoints {
                let cmTime = CMTime(seconds: time, preferredTimescale: 600)
                let imageResult = try await generator.image(at: cmTime)
                
                // Both CGImage and UIImage are non-optional here, but we'll handle potential failures
                let cgImage = imageResult.image
                let thumbnail = UIImage(cgImage: cgImage)
                newThumbnails.append(thumbnail)
            }
            
            self.thumbnails = newThumbnails
            self.isLoading = false
            
        } catch {
            print("Error loading thumbnails:", error)
            self.isLoading = false
        }
    }
    
    func saveThumbnail() async throws {
        guard let selectedIndex = selectedThumbnailIndex,
              thumbnails.indices.contains(selectedIndex),
              let thumbnailData = thumbnails[selectedIndex].jpegData(compressionQuality: 0.7) else {
            throw VideoEditError.invalidVideo
        }
        
        // Upload thumbnail
        let thumbnailRef = storage.reference().child("thumbnails/\(videoId).jpg")
        _ = try await thumbnailRef.putDataAsync(thumbnailData)
        let thumbnailUrl = try await thumbnailRef.downloadURL()
        
        // Update video document with Sendable dictionary
        let updateData: [String: Any] = [
            "thumbnailUrl": thumbnailUrl.absoluteString,
            "updatedAt": Timestamp(date: Date())
        ]
        
        // Ensure Firestore update runs on main actor
        try await db.collection(Video.collectionName)
            .document(videoId)
            .updateData(updateData)
    }
} 