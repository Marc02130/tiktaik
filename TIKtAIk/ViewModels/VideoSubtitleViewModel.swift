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
        do {
            let snapshot = try await db.collection("videoSubtitles")
                .whereField("videoId", isEqualTo: videoId)
                .getDocuments()
            
            subtitles = snapshot.documents.compactMap { doc -> VideoSubtitle? in
                try? doc.data(as: VideoSubtitle.self)
            }.sorted { $0.startTime < $1.startTime }
        } catch {
            print("Error loading subtitles:", error)
            self.error = error
        }
    }
    
    func generateSubtitles(with preferences: SubtitlePreferences) async throws {
        isGenerating = true
        progress = 0
        defer { isGenerating = false }
        
        do {
            let service = SubtitleGenerationService()
            try await service.generateSubtitles(
                for: videoURL,
                videoId: videoId
            ) { [weak self] progress in
                self?.progress = progress
            }
            self.preferences = preferences
            await loadSubtitles()
        } catch {
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
            try await db.collection("videoSubtitles")
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
    
    func updateSubtitles(_ subtitles: [VideoSubtitle]) async throws {
        let batch = db.batch()
        
        for subtitle in subtitles {
            let ref = db.collection("videoSubtitles").document(subtitle.id)
            batch.setData(subtitle.asDictionary, forDocument: ref)
        }
        
        try await batch.commit()
        await loadSubtitles() // Reload to get updated data
    }
    
    func deleteSubtitle(for id: String) async throws {
        let ref = db.collection("videoSubtitles").document(id)
        try await ref.delete()
        await loadSubtitles() // Reload to get updated data
    }
    
    @MainActor
    func updateVideoURL(_ url: URL) {
        // Only update if URL has changed
        guard url != videoURL else { return }
        // Update the URL and reload subtitles
        self.videoURL = url
        Task {
            await loadSubtitles()
        }
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