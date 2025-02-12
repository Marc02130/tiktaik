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
    @Published var title: String = ""
    /// Video description
    @Published var description: String = ""
    /// Comma-separated tags
    @Published private(set) var selectedTags: Set<String> = []
    /// Whether video is private
    @Published var isPrivate: Bool = false
    /// Whether comments are allowed
    @Published var allowComments: Bool = true
    /// Video URL for playback
    @Published var videoURL: String?
    /// Video player instance
    @Published var player: AVPlayer?
    /// Whether changes are being saved
    @Published private(set) var isSaving = false
    /// Whether the video is being loaded
    @Published private(set) var isLoading = false
    /// Generated video thumbnails
    @Published private(set) var thumbnails: [UIImage]? = nil
    /// Selected thumbnail index
    @Published var selectedThumbnailIndex = 0
    private let refreshTrigger: RefreshTrigger
    
    /// Current error message if any
    @Published private(set) var error: String?
    
    /// Clears the current error message
    func clearError() {
        error = nil
    }
    
    @Published var duration: TimeInterval = 0  // Will be set to actual video duration
    @Published var timeRange: ClosedRange<TimeInterval>
    @Published var cropRect: CGRect
    
    private let editService = VideoEditService()
    private let storage = Storage.storage()
    
    // Add progress tracking
    private(set) var progress: Double = 0
    private let videoEditService: VideoEditService
    
    private var loadTask: Task<Void, Never>?  // Track current load task
    private var currentDownloadTask: StorageDownloadTask?
    
    // Add missing properties
    private let video: Video
    @Published private(set) var shouldDismiss = false
    
    @Published private(set) var videoWasEdited = false
    @Published private(set) var editedVideoURL: URL?
    
    // Add subtitle support
    @Published private(set) var subtitleViewModel: VideoSubtitleViewModel?
    
    // Add save state
    @Published private(set) var isSavingSubtitles = false
    
    /// Initializes view model with video ID
    /// - Parameter videoId: Unique identifier of video to edit
    init(videoId: String, refreshTrigger: RefreshTrigger, video: Video) {
        self.videoId = videoId
        self.refreshTrigger = refreshTrigger
        self._timeRange = Published(initialValue: 0...0)  // Will be set to full video range
        self._cropRect = Published(initialValue: CGRect(x: 0, y: 0, width: 1, height: CropConfig.aspectRatio))
        self.videoEditService = VideoEditService()
        self.video = video
        
        // Initialize subtitle view model
        if let videoURL = videoURL,
           let url = URL(string: videoURL) {
            self.subtitleViewModel = VideoSubtitleViewModel.getViewModel(
                for: videoId,
                videoURL: url
            )
        }
    }
    
    /// Loads video data from Firestore
    func loadVideo() async {
        guard !isLoading else { return }
        isLoading = true
        
        do {
            // Check temp directory permissions first
            let tempDir = FileManager.default.temporaryDirectory
            print("DEBUG: Temp directory exists:", FileManager.default.fileExists(atPath: tempDir.path))
            if let attrs = try? FileManager.default.attributesOfItem(atPath: tempDir.path) {
                print("DEBUG: Temp directory permissions:", String(format: "%o", attrs[.posixPermissions] as? Int ?? 0))
                print("DEBUG: Temp directory owner:", attrs[.ownerAccountName] ?? "unknown")
            }
            
            // 1. Set basic data first
            await MainActor.run {
                self.title = video.title
                self.description = video.description ?? ""
                self.isPrivate = video.isPrivate
                self.allowComments = video.allowComments
                self.selectedTags = Set(video.tags)
            }
            
            print("DEBUG: Loading video from storage path:", video.storageUrl)
            
            // Create storage reference using full path
            let storageRef = Storage.storage().reference(withPath: video.storageUrl)
            print("DEBUG: Storage bucket:", storageRef.bucket)
            print("DEBUG: Storage full path:", storageRef.fullPath)
            print("DEBUG: Storage name:", storageRef.name)
            
            // Extract file extension from storage path
            let fileExtension = (video.storageUrl as NSString).pathExtension
            print("DEBUG: File extension from path:", fileExtension)
            
            // Create local URL with proper extension
            let sessionDir = FileManager.default.temporaryDirectory
                .appendingPathComponent("videoEdit-\(UUID().uuidString)")
            let localURL = sessionDir.appendingPathComponent("video.\(fileExtension)")
            
            // Create directory
            try FileManager.default.createDirectory(at: sessionDir,
                                                 withIntermediateDirectories: true)
            
            print("DEBUG: Starting video download to:", localURL.path)
            
            // Use download task instead of direct write
            let downloadTask = storageRef.write(toFile: localURL)
            
            // Create continuation to properly wait for download
            try await withCheckedThrowingContinuation { continuation in
                // Wait for actual completion
                downloadTask.observe(.success) { _ in
                    print("DEBUG: Download actually completed")
                    continuation.resume()
                }
                
                // Check for errors
                downloadTask.observe(.failure) { snapshot in
                    print("DEBUG: Download failed:", snapshot.error ?? "unknown error")
                    if let error = snapshot.error {
                        continuation.resume(throwing: error)
                    }
                }
            }
            
            print("DEBUG: Download task finished")
            
            // Verify downloaded file
            do {
                if let fileType = try localURL.resourceValues(forKeys: [.typeIdentifierKey]).typeIdentifier {
                    print("DEBUG: Downloaded file type:", fileType)
                } else {
                    print("DEBUG: Could not determine file type")
                }
            } catch {
                print("DEBUG: Error getting file type:", error)
            }
            
            do {
                let attrs = try FileManager.default.attributesOfItem(atPath: localURL.path)
                print("DEBUG: File size:", attrs[.size] ?? "unknown")
                print("DEBUG: File permissions:", String(format: "%o", attrs[.posixPermissions] as? Int ?? 0))
                print("DEBUG: File type:", attrs[.type] ?? "unknown")
                print("DEBUG: File creation date:", attrs[.creationDate] ?? "unknown")
            } catch {
                print("DEBUG: Error getting file attributes:", error)
            }
            
            // Verify file exists and is readable
            let fileManager = FileManager.default
            print("DEBUG: File exists:", fileManager.fileExists(atPath: localURL.path))
            print("DEBUG: File is readable:", fileManager.isReadableFile(atPath: localURL.path))
            
            // 4. Set up player with proper options
            let asset = AVURLAsset(url: localURL, options: [
                AVURLAssetPreferPreciseDurationAndTimingKey: true
            ])
            
            // Load duration with retry
            var duration: CMTime?
            for attempt in 1...3 {
                print("DEBUG: Loading duration attempt \(attempt)")
                do {
                    duration = try await asset.load(.duration)
                    break
                } catch {
                    print("DEBUG: Duration load attempt \(attempt) failed:", error)
                    if attempt == 3 { throw error }
                    try await Task.sleep(for: .milliseconds(500))
                }
            }
            
            guard let duration = duration else {
                throw VideoEditError.invalidVideo
            }
            
            let durationSeconds = CMTimeGetSeconds(duration)
            guard durationSeconds > 0 else {
                throw VideoEditError.invalidVideo
            }
            
            print("DEBUG: Video duration loaded:", durationSeconds)
            
            // Set up player with downloaded video
            let player = AVPlayer(url: localURL)
            player.automaticallyWaitsToMinimizeStalling = true
            
            // Generate thumbnails for trim/crop views
            let generator = AVAssetImageGenerator(asset: asset)
            generator.appliesPreferredTrackTransform = true
            generator.maximumSize = CGSize(width: 200, height: 200)
            
            // Generate 6 thumbnails evenly spaced
            let timePoints = stride(from: 0.0, to: durationSeconds, by: durationSeconds/6)
            var newThumbnails: [UIImage] = []
            
            for time in timePoints {
                let cmTime = CMTime(seconds: time, preferredTimescale: 600)
                let imageResult = try await generator.image(at: cmTime)
                let thumbnail = UIImage(cgImage: imageResult.image)
                newThumbnails.append(thumbnail)
            }
            
            await MainActor.run {
                self.videoURL = localURL.path
                self.duration = durationSeconds
                self.timeRange = 0...durationSeconds
                self.player = player
                self.thumbnails = newThumbnails
            }
            
        } catch {
            print("DEBUG: Load error:", error)
            await MainActor.run {
                self.error = error.localizedDescription
            }
        }
        
        isLoading = false
    }
    
    /// Updates video with new URL and metadata
    private func updateVideo(_ trimmedURL: URL) async throws {
        // Generate a new unique filename for the trimmed video
        let filename = "\(UUID().uuidString).mp4"
        let storageRef = Storage.storage().reference().child("videos/\(filename)")
        
        // Upload the trimmed video
        let videoData = try Data(contentsOf: trimmedURL)
        let metadata = StorageMetadata()
        metadata.contentType = "video/mp4"
        
        _ = try await storageRef.putDataAsync(videoData, metadata: metadata)
        
        // Get the HTTP URL for the uploaded video
        let httpURL = try await storageRef.downloadURL()
        
        // Update the video document with the new URL
        let updateData: [String: Any] = [
            "storageUrl": storageRef.fullPath,
            "videoUrl": httpURL.absoluteString,
            "metadata.edited": true,
            "metadata.lastModified": Timestamp(date: Date()),
            "updatedAt": Timestamp(date: Date())
        ]
        
        try await Firestore.firestore()
            .collection(Video.collectionName)
            .document(videoId)
            .updateData(updateData)
        
        // Update local video URL
        self.videoURL = httpURL.absoluteString
    }
    
    /// Saves metadata changes (title, description, tags, thumbnail)
    @MainActor
    func saveChanges() async throws {
        isLoading = true
        
        do {
            var updateData: [String: Any] = [
                "title": title,
                "description": description,
                "tags": Array(selectedTags),
                "isPrivate": isPrivate,
                "allowComments": allowComments,
                "updatedAt": Timestamp(date: Date())
            ]
            
            // If video was edited (trimmed/cropped), handle video changes
            if videoWasEdited, let editedVideoURL = editedVideoURL {
                // 1. Upload edited video
                let storageRef = Storage.storage().reference()
                    .child("videos/\(videoId).mov")
                
                let metadata = StorageMetadata()
                metadata.contentType = "video/quicktime"
                
                _ = try await storageRef.putFileAsync(from: editedVideoURL, metadata: metadata)
                
                // 2. Clear thumbnails since video was modified
                updateData["thumbnailUrl"] = NSNull()
                
                // 3. Clean up temporary files
                try? FileManager.default.removeItem(at: editedVideoURL)
                self.editedVideoURL = nil
                self.videoWasEdited = false
            }
            
            // Update Firestore document with all changes
            try await Firestore.firestore()
                .collection(Video.collectionName)
                .document(videoId)
                .updateData(updateData)
            
            // Trigger refresh after successful save
            refreshTrigger.triggerRefresh()
            
            isLoading = false
        } catch {
            isLoading = false
            throw error
        }
    }
    
    func updateTags(_ newTags: Set<String>) {
        selectedTags = newTags
    }
    
    func previewTime(_ time: TimeInterval) {
        player?.seek(to: CMTime(seconds: time, preferredTimescale: 600))
    }
    
    // Update the validation function to use local constraints
    private func validateTimeRange(_ range: ClosedRange<TimeInterval>) -> Bool {
        // Only validate that range is within video bounds
        return range.lowerBound >= 0 && range.upperBound <= duration
    }
    
    // Update any functions that were using TrimConfig
    func updateTimeRange(_ range: ClosedRange<TimeInterval>) {
        if validateTimeRange(range) {
            timeRange = range
            videoWasEdited = true  // Mark video as edited when trim range changes
        }
    }
    
    @MainActor
    func trimVideo() async {
        guard !isLoading else { return }
        isLoading = true
        
        do {
            guard let videoURL = URL(string: videoURL ?? "") else {
                throw VideoEditError.invalidVideo
            }
            
            // Pause current player
            player?.pause()
            
            // Use VideoEditService to trim video
            let trimmedURL = try await videoEditService.trimVideo(
                url: videoURL,
                timeRange: timeRange,
                progress: { [weak self] progress in
                    Task { @MainActor in
                        self?.progress = progress
                    }
                }
            )
            
            // Update state after successful trim
            self.editedVideoURL = trimmedURL
            self.videoWasEdited = true
            
            // Create new player with trimmed video
            let newPlayer = AVPlayer(url: trimmedURL)
            newPlayer.automaticallyWaitsToMinimizeStalling = false
            self.player = newPlayer
            
            isLoading = false
        } catch {
            isLoading = false
            self.error = error.localizedDescription
            print("DEBUG: Trim error:", error)
        }
    }
    
    @MainActor
    func cropVideo() async {
        do {
            guard let videoURL = videoURL else {
                error = "No video URL available"
                return
            }
            
            print("DEBUG: Starting crop operation")
            print("DEBUG: Crop rect:", cropRect)
            print("DEBUG: Video URL:", videoURL)
            
            progress = 0.2
            let url = URL(string: videoURL)!
            
            // Crop video using new State API
            let croppedURL = try await videoEditService.cropVideo(
                url: url,
                rect: cropRect,
                progress: { [weak self] progress in
                    print("DEBUG: Crop progress:", progress)
                    self?.progress = 0.2 + (progress * 0.6)
                }
            )
            
            print("DEBUG: Crop completed")
            print("DEBUG: Output URL:", croppedURL)
            progress = 0.8
            
            // Set these properties
            self.videoWasEdited = true
            self.editedVideoURL = croppedURL
            
            // Update video metadata
            try await updateVideo(croppedURL)
            
            progress = 1.0
            refreshTrigger.triggerRefresh()
            
        } catch {
            print("DEBUG: Crop failed with error:", error)
            print("DEBUG: Error description:", error.localizedDescription)
            self.error = error.localizedDescription
        }
    }
    
    /// Extracts metadata from video file
    private func extractVideoMetadata(from url: URL) async throws -> [String: Any] {
        let asset = AVURLAsset(url: url)
        let duration = try await asset.load(.duration)
        let tracks = try await asset.loadTracks(withMediaType: .video)
        
        guard let videoTrack = tracks.first else {
            throw VideoEditError.invalidVideo
        }
        
        let size = try await videoTrack.load(.naturalSize)
        
        return [
            "duration": CMTimeGetSeconds(duration),
            "width": Int(size.width),
            "height": Int(size.height),
            "lastModified": Timestamp(date: Date())
        ]
    }
    
    private func getVideoMetadata(from url: URL) async throws -> [String: Any] {
        let asset = AVURLAsset(url: url)
        let duration = try await asset.load(.duration)
        let tracks = try await asset.loadTracks(withMediaType: .video)
        
        guard let videoTrack = tracks.first else {
            throw VideoEditingError.invalidVideo
        }
        
        let size = try await videoTrack.load(.naturalSize)
        
        return [
            "metadata": [
                "duration": CMTimeGetSeconds(duration),
                "width": Int(size.width),
                "height": Int(size.height),
                "lastModified": Timestamp(date: Date())
            ]
        ]
    }
    
    var selectedTagsBinding: Binding<Set<String>> {
        Binding(
            get: { self.selectedTags },
            set: { self.updateTags($0) }
        )
    }
    
    // Add save method
    func saveSubtitles(_ subtitles: [VideoSubtitle]) async throws {
        isSavingSubtitles = true
        
        defer { isSavingSubtitles = false }
        
        // Update subtitles in Firestore
        let db = Firestore.firestore()
        let batch = db.batch()
        
        // Delete existing subtitles
        let subtitlesRef = db.collection(VideoSubtitle.collectionName)
        let existingQuery = subtitlesRef.whereField("videoId", isEqualTo: video.id)
        let existing = try await existingQuery.getDocuments()
        existing.documents.forEach { doc in
            batch.deleteDocument(doc.reference)
        }
        
        // Add new subtitles
        subtitles.forEach { subtitle in
            let newRef = subtitlesRef.document()
            // Create new subtitle with updated id and videoId
            let newSubtitle = VideoSubtitle(
                id: newRef.documentID,
                videoId: video.id,
                startTime: subtitle.startTime,
                endTime: subtitle.endTime,
                text: subtitle.text,
                isEdited: subtitle.isEdited,
                createdAt: subtitle.createdAt
            )
            batch.setData(newSubtitle.asDictionary, forDocument: newRef)
        }
        
        try await batch.commit()
    }
    
    private func setupSubtitleViewModel() {
        if let videoURL = videoURL,
           let url = URL(string: videoURL) {
            subtitleViewModel = VideoSubtitleViewModel.getViewModel(
                for: videoId,
                videoURL: url
            )
        }
    }
}

// Helper for timeouts
func withTimeout<T>(seconds: TimeInterval, operation: @escaping () async throws -> T) async throws -> T {
    try await withThrowingTaskGroup(of: T.self) { group in
        group.addTask {
            try await operation()
        }
        
        group.addTask {
            try await Task.sleep(for: .seconds(seconds))
            throw VideoEditError.timeout
        }
        
        let result = try await group.next()!
        group.cancelAll()
        return result
    }
}

enum VideoEditError: LocalizedError {
    case invalidVideo
    case updateFailed
    case timeout
    case exportFailed
    case invalidURL
    
    var errorDescription: String? {
        switch self {
        case .invalidVideo:
            return "Invalid video data"
        case .updateFailed:
            return "Failed to update video"
        case .timeout:
            return "Operation timed out"
        case .exportFailed:
            return "Failed to export video"
        case .invalidURL:
            return "Invalid video URL format"
        }
    }
}
