//
// VideoUploadViewModel.swift
// TIKtAIk
//
// Created: 2024-02-14
// Last modified: 2024-02-14
//
// Purpose: View model for handling video upload operations
// Author: Assistant
// Copyright © 2024 TIKtAIk. All rights reserved.
//

// Framework: SwiftUI - UI Framework
import SwiftUI
// Framework: PhotosUI - Photo Library Access
import PhotosUI
// Framework: FirebaseStorage - Cloud Storage
import FirebaseStorage
// Framework: FirebaseFirestore - Cloud Database
import FirebaseFirestore
// Framework: FirebaseAuth - Authentication
import FirebaseAuth
// Framework: AVFoundation - Video Processing
import AVFoundation
// Framework: Combine - Reactive Programming
import Combine

/// View model managing video upload operations
///
/// Handles:
/// - Video selection and validation
/// - Upload progress tracking
/// - Metadata extraction
/// - Error handling
@MainActor
final class VideoUploadViewModel: ObservableObject {
    // MARK: - Published Properties
    
    /// Selected video item from PhotosPicker
    @Published var selectedItem: PhotosPickerItem?
    /// Local URL of the selected video file
    @Published private(set) var selectedVideoURL: URL?
    /// Whether a video is currently being uploaded
    @Published private(set) var isUploading = false
    /// Upload progress from 0 to 1
    @Published private(set) var uploadProgress: Double = 0
    /// Current upload status message
    @Published private(set) var uploadStatus = ""
    /// Current error message if any
    @Published private(set) var error: String?
    /// Whether the view should be dismissed
    @Published private(set) var shouldDismiss = false
    
    // Metadata properties
    @Published var title = ""
    @Published var description = ""
    @Published var tags = ""
    @Published var isPrivate = false
    @Published var allowComments = true
    
    @Published private(set) var thumbnails: [UIImage]?
    @Published var selectedThumbnailIndex: Int = 0
    
    @Published private(set) var uploadComplete = false
    
    /// ID of the current video being edited
    @Published private(set) var currentVideoId: String?
    
    // Update selectedTags to be a Set
    @Published private(set) var selectedTags: Set<String> = []
    
    var isValidForm: Bool {
        !title.isEmpty && selectedVideoURL != nil
    }
    
    // MARK: - Private Properties
    
    /// Maximum allowed file size (500MB)
    private let maxFileSize: Int64 = 500 * 1024 * 1024
    /// Allowed video file formats
    private let allowedTypes = ["mp4", "mov"]
    /// Cancellables for managing subscriptions
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    init() {
        setupVideoSelection()
    }
    
    /// Initializes view model for editing an existing video
    convenience init(videoId: String) {
        self.init()
        self.currentVideoId = videoId
        // Load existing video data
        Task {
            await loadVideoData()
        }
    }
    
    // MARK: - Video Selection
    
    /// Sets up subscription to handle video selection from PhotosPicker
    private func setupVideoSelection() {
        $selectedItem
            .compactMap { $0 }  // Filter out nil values
            .sink { [weak self] item in
                Task {
                    await self?.loadVideo(from: item)
                }
            }
            .store(in: &cancellables)
    }
    
    /// Loads and validates a selected video
    /// - Parameter item: Selected PhotosPickerItem
    private func loadVideo(from item: PhotosPickerItem) async {
        do {
            // Load video data
            guard let videoData = try await item.loadTransferable(type: Data.self) else {
                throw UploadError.invalidVideo
            }
            
            // Create temporary file
            let tempURL = FileManager.default.temporaryDirectory
                .appendingPathComponent(UUID().uuidString)
                .appendingPathExtension("mov")
            
            // Save video data
            try videoData.write(to: tempURL)
            
            // Validate size and format
            try await validateVideo(at: tempURL)
            
            await MainActor.run {
                self.selectedVideoURL = tempURL
                self.error = nil
            }
            
        } catch {
            await MainActor.run {
                self.error = error.localizedDescription
                self.selectedVideoURL = nil
            }
        }
    }
    
    /// Loads existing video data for editing
    private func loadVideoData() async {
        guard let videoId = currentVideoId else { return }
        
        do {
            let snapshot = try await Firestore.firestore()
                .collection(Video.collectionName)
                .document(videoId)
                .getDocument()
            
            if let data = snapshot.data() {
                await MainActor.run {
                    self.title = data["title"] as? String ?? ""
                    self.description = data["description"] as? String ?? ""
                    self.tags = (data["tags"] as? [String] ?? []).joined(separator: ",")
                    self.isPrivate = data["isPrivate"] as? Bool ?? false
                    self.allowComments = data["allowComments"] as? Bool ?? true
                }
            }
        } catch {
            await MainActor.run {
                self.error = "Failed to load video data"
            }
        }
    }
    
    // MARK: - Video Upload
    
    /// Generates thumbnail images from the selected video
    func generateThumbnails() async {
        guard let videoURL = selectedVideoURL else { return }
        
        do {
            let asset = AVURLAsset(url: videoURL)
            let duration = try await asset.load(.duration)
            let durationSeconds = CMTimeGetSeconds(duration)
            
            // Generate 6 thumbnails at different timestamps
            var images: [UIImage] = []
            for i in 0..<6 {
                let time = CMTime(seconds: durationSeconds * Double(i) / 5.0, preferredTimescale: 600)
                let generator = AVAssetImageGenerator(asset: asset)
                generator.appliesPreferredTrackTransform = true
                
                // Explicitly specify CGImage as the generic type
                let cgImage = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<CGImage, Error>) in
                    generator.generateCGImageAsynchronously(for: time) { cgImage, actualTime, error in
                        if let error = error {
                            continuation.resume(throwing: error)
                            return
                        }
                        
                        if let cgImage = cgImage {
                            continuation.resume(returning: cgImage)
                        } else {
                            continuation.resume(throwing: NSError(domain: "ThumbnailGeneration", code: -1, 
                                userInfo: [NSLocalizedDescriptionKey: "Failed to generate thumbnail"]))
                        }
                    }
                }
                
                let image = UIImage(cgImage: cgImage)
                images.append(image)
            }
            
            await MainActor.run {
                self.thumbnails = images
            }
            
        } catch {
            print("Failed to generate thumbnails:", error)
            await MainActor.run {
                self.error = "Failed to generate thumbnails"
            }
        }
    }
    
    /// Resets view model state after successful upload
    private func resetState() {
        selectedItem = nil
        selectedVideoURL = nil
        isUploading = false
        uploadProgress = 0
        uploadStatus = ""
        error = nil
        uploadComplete = false
        currentVideoId = nil
        title = ""
        description = ""
        tags = ""
        isPrivate = false
        allowComments = true
        thumbnails = nil
        selectedThumbnailIndex = 0
        selectedTags.removeAll()
    }
    
    /// Uploads the video and selected thumbnail
    func uploadVideo() async {
        guard let videoURL = selectedVideoURL else { return }
        
        isUploading = true
        uploadProgress = 0
        error = nil
        
        do {
            let videoId = UUID().uuidString // Generate videoId once
            let storageRef = Storage.storage().reference()
            
            // 1. Upload video file
            let storagePath = "videos/\(videoId).\(videoURL.pathExtension)" // Use same videoId
            let videoRef = storageRef.child(storagePath)
            let metadata = StorageMetadata()
            metadata.contentType = "video/\(videoURL.pathExtension)" // Use actual file extension
            
            let _ = try await videoRef.putFileAsync(from: videoURL, metadata: metadata) { [weak self] progress in
                guard let progress = progress else { return }
                let percentComplete = Double(progress.completedUnitCount) / Double(progress.totalUnitCount)
                Task { @MainActor in
                    self?.uploadProgress = percentComplete
                    self?.uploadStatus = "Uploading video..."
                }
            }
            
            // 2. Upload thumbnail if selected
            var thumbnailURL: String?
            if let thumbnails = thumbnails, !thumbnails.isEmpty {
                let thumbnail = thumbnails[selectedThumbnailIndex]
                if let thumbnailData = thumbnail.jpegData(compressionQuality: 0.7) {
                    let thumbnailRef = storageRef.child("thumbnails/\(videoId).jpg")
                    let _ = try await thumbnailRef.putDataAsync(thumbnailData)
                    thumbnailURL = try await thumbnailRef.downloadURL().absoluteString
                }
            }
            
            // 3. Create video document with same videoId and storage path
            _ = try await createVideo(videoId: videoId, storagePath: storagePath, thumbnailURL: thumbnailURL)
            
            uploadComplete = true
            uploadStatus = "Upload complete!"
            
            // Reset state after short delay
            Task { @MainActor in
                try? await Task.sleep(for: .seconds(1.5))
                resetState()
            }
            
        } catch {
            self.error = error.localizedDescription
            isUploading = false
        }
    }
    
    private func createVideo(videoId: String, storagePath: String, thumbnailURL: String?) async throws -> Video {
        let userId = Auth.auth().currentUser?.uid ?? ""
        
        // Get the local video URL for metadata extraction
        guard let localVideoURL = selectedVideoURL else {
            throw UploadError.invalidVideo
        }
        
        let metadata = try await self.extractVideoMetadata(from: localVideoURL)
        
        let video = Video(
            id: videoId, // Use same videoId passed from upload
            userId: userId,
            title: title,
            description: description.isEmpty ? nil : description,
            metadata: metadata,
            stats: Video.Stats(
                views: 0,
                likes: 0,
                shares: 0,
                commentsCount: 0
            ),
            status: .ready,
            storageUrl: storagePath, // Use storage path passed from upload
            thumbnailUrl: thumbnailURL,
            createdAt: Date(),
            updatedAt: Date(),
            tags: Set(selectedTags),
            isPrivate: isPrivate,
            allowComments: allowComments
        )
        
        try await Firestore.firestore()
            .collection(Video.collectionName)
            .document(videoId)
            .setData(video.asDictionary)
        
        return video
    }
    
    func updateVideo() async {
        isUploading = true
        uploadStatus = "Saving changes..."
        
        do {
            guard let videoId = currentVideoId else {
                throw UploadError.invalidVideo
            }
            
            // Create the update data on the main actor
            let updateData: [String: Any] = [
                "title": title,
                "description": description,
                "tags": Array(selectedTags),
                "isPrivate": isPrivate,
                "allowComments": allowComments,
                "updatedAt": Timestamp(date: Date())
            ]
            
            // Update in Firestore
            try await Firestore.firestore()
                .collection(Video.collectionName)
                .document(videoId)
                .updateData(updateData)
            
            shouldDismiss = true
        } catch {
            self.error = error.localizedDescription
        }
        
        isUploading = false
    }
    
    // MARK: - Video Validation
    
    /// Validates video file size and format
    /// - Parameter url: Local URL of the video file
    /// - Throws: UploadError if validation fails
    private func validateVideo(at url: URL) async throws {
        // Check file size
        let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
        let fileSize = attributes[.size] as! Int64
        guard fileSize <= maxFileSize else {
            throw UploadError.fileTooLarge
        }
        
        // Check file type using AVURLAsset
        let asset = AVURLAsset(url: url)
        let isPlayable = try await asset.load(.isPlayable)
        guard isPlayable else {
            throw UploadError.invalidFormat
        }
    }
    
    // MARK: - Metadata Extraction
    
    /// Extracts video metadata from a file URL
    /// - Parameter url: Local URL of the video file
    /// - Returns: Video metadata including duration, size, format and resolution
    /// - Throws: File access or video processing errors
    private func extractVideoMetadata(from url: URL) async throws -> Video.VideoMetadata {
        let asset = AVURLAsset(url: url)
        let tracks = try await asset.loadTracks(withMediaType: .video)
        let duration = try await asset.load(.duration)
        let durationSeconds = Int(CMTimeGetSeconds(duration))
        
        // Get file size
        let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
        let fileSize = attributes[.size] as? Int ?? 0
        
        // Get dimensions
        var width = 0
        var height = 0
        if let videoTrack = tracks.first {
            let size = try await videoTrack.load(.naturalSize)
            width = Int(size.width)
            height = Int(size.height)
        }
        
        return createVideoMetadata(
            duration: durationSeconds,
            size: Int(fileSize),
            width: width,
            height: height,
            format: url.pathExtension,
            resolution: "\(width)x\(height)"
        )
    }
    
    // MARK: - Error Types
    
    /// Errors that can occur during video upload
    enum UploadError: LocalizedError {
        case invalidVideo
        case fileTooLarge
        case invalidFormat
        
        var errorDescription: String? {
            switch self {
            case .invalidVideo: return "Could not load video"
            case .fileTooLarge: return "Video must be under 500MB"
            case .invalidFormat: return "Unsupported video format"
            }
        }
    }
    
    // Update tag selection method
    func addTag(_ tag: String) {
        selectedTags.insert(tag)
    }
    
    func removeTag(_ tag: String) {
        selectedTags.remove(tag)
    }
    
    private func createVideoMetadata(duration: Int, size: Int, width: Int, height: Int, format: String, resolution: String?) -> Video.VideoMetadata {
        Video.VideoMetadata(
            duration: Double(duration),
            width: width,
            height: height,
            size: size,
            format: format,
            resolution: resolution,
            uploadDate: Date(),
            lastModified: Date()
        )
    }
    
    func updateTags(_ tags: Set<String>) {
        selectedTags = tags
    }
} 