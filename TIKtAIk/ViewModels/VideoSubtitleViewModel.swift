//
// VideoSubtitleViewModel.swift
// TIKtAIk
//
// Created: 2024-02-14
// Last modified: 2024-02-14
//
// Purpose: View model for managing video subtitle generation and display
// Author: Assistant
// Copyright © 2024 TIKtAIk. All rights reserved.

import Foundation
import FirebaseFirestore
import SwiftUI
import Combine

@MainActor
class VideoSubtitleViewModel: ObservableObject {
    @Published private(set) var subtitles: [VideoSubtitle] = []
    @Published var preferences: SubtitlePreferences = .default
    @Published private(set) var isGenerating = false
    @Published private(set) var progress: Double = 0
    @Published private(set) var error: Error?
    
    private let videoId: String
    private var videoURL: URL
    private static var cache: [String: VideoSubtitleViewModel] = [:]
    private let db = Firestore.firestore()
    private let collectionName = "subtitles"
    
    var currentVideoURL: URL {
        videoURL
    }
    
    init(videoId: String, videoURL: URL) {
        self.videoId = videoId
        self.videoURL = videoURL
        Task {
            await loadSubtitles()
        }
    }
    
    static func getViewModel(for videoId: String, videoURL: URL) -> VideoSubtitleViewModel {
        if let cached = cache[videoId] {
            return cached
        }
        let viewModel = VideoSubtitleViewModel(videoId: videoId, videoURL: videoURL)
        cache[videoId] = viewModel
        return viewModel
    }
    
    func loadSubtitles() async {
        print("DEBUG: [SUBTITLES] Loading subtitles for video \(videoId)")
        do {
            let snapshot = try await db.collection(collectionName)
                .whereField("videoId", isEqualTo: videoId)
                .getDocuments()
            
            print("DEBUG: [SUBTITLES] Found \(snapshot.documents.count) subtitles for video \(videoId)")
            
            subtitles = snapshot.documents.compactMap { doc -> VideoSubtitle? in
                if let subtitle = try? VideoSubtitle.from(doc) {
                    print("DEBUG: [SUBTITLES] Loaded subtitle: \(subtitle)")
                    return subtitle
                }
                return nil
            }.sorted { $0.startTime < $1.startTime }
            
            print("DEBUG: [SUBTITLES] Loaded \(subtitles.count) subtitles for video \(videoId)")
        } catch {
            print("ERROR: [SUBTITLES] Failed to load subtitles for \(videoId): \(error)")
            self.error = error
        }
    }
    
    func generateSubtitles(with preferences: SubtitlePreferences) async throws {
        isGenerating = true
        progress = 0
        defer { isGenerating = false }
        
        do {
            let service = SubtitleGenerationService()
            let generatedSubtitles = try await service.generateSubtitles(
                for: videoURL,
                videoId: videoId
            ) { [weak self] newProgress in
                Task { @MainActor in
                    self?.progress = newProgress
                }
            }
            
            // Save to Firestore first
            let batch = db.batch()
            
            for subtitle in generatedSubtitles {
                let ref = db.collection(collectionName).document(subtitle.id)
                batch.setData(subtitle.asDictionary, forDocument: ref)
            }
            
            try await batch.commit()
            print("DEBUG: Saved \(generatedSubtitles.count) subtitles to Firestore")
            
            // Then update local state
            self.subtitles = generatedSubtitles
            self.preferences = preferences
            
            print("DEBUG: Updated local state with generated subtitles")
            
        } catch {
            print("ERROR: Failed to generate/save subtitles:", error)
            self.error = error
            throw error
        }
    }
    
    @MainActor
    func updateTiming(for subtitle: VideoSubtitle, startTime: TimeInterval, endTime: TimeInterval) async throws {
        guard startTime < endTime else {
            throw SubtitleError.invalidTiming
        }
        
        let data: [String: Any] = [
            "startTime": startTime,
            "endTime": endTime,
            "isEdited": true
        ]
        
        do {
            try await db.collection(collectionName)
                .document(subtitle.id)
                .updateData(data)
            
            await loadSubtitles()
        } catch {
            throw SubtitleError.updateFailed(error.localizedDescription)
        }
    }
    
    func updatePreferences(_ newPreferences: SubtitlePreferences) async {
        // Add preferences update logic
        preferences = newPreferences
        // Save to user defaults or backend if needed
    }
    
    @MainActor
    func updateSubtitles(_ newSubtitles: [VideoSubtitle]) async throws {
        let batch = db.batch()
        
        for subtitle in newSubtitles {
            let ref = db.collection(collectionName).document(subtitle.id)
            batch.setData(subtitle.asDictionary, forDocument: ref)
        }
        
        try await batch.commit()
        
        // Update local state after successful save
        self.subtitles = newSubtitles
    }
    
    func deleteSubtitle(for id: String) async throws {
        let ref = db.collection(collectionName).document(id)
        try await ref.delete()
        await loadSubtitles() // Reload to get updated data
    }
    
    @MainActor
    func updateVideoURL(_ url: URL) {
        print("DEBUG: [SUBTITLES] Updating video URL for \(videoId): \(url)")
        // Only update if URL has changed
        guard url != videoURL else {
            print("DEBUG: [SUBTITLES] URL unchanged for \(videoId)")
            return
        }
        // Update the URL and reload subtitles
        self.videoURL = url
        Task {
            await loadSubtitles()
        }
    }
    
    func saveChanges() async throws {
        print("DEBUG: Saving \(subtitles.count) subtitles")
        let batch = db.batch()
        
        for subtitle in subtitles {
            let ref = db.collection(collectionName).document(subtitle.id)
            batch.setData(subtitle.asDictionary, forDocument: ref)
        }
        
        try await batch.commit()
        print("DEBUG: Successfully saved subtitles to Firestore")
        
        // Reload to ensure we have latest data
        await loadSubtitles()
    }
}

enum SubtitleError: LocalizedError {
    case notFound
    case updateFailed(String)
    case invalidTiming
    
    var errorDescription: String? {
        switch self {
        case .notFound:
            return "Subtitle not found"
        case .updateFailed(let message):
            return "Failed to update subtitle: \(message)"
        case .invalidTiming:
            return "Invalid subtitle timing"
        }
    }
} 