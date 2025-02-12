//
// SubtitleGenerationService.swift
// TIKtAIk
//
// Created: 2024-02-14
// Last modified: 2024-02-14
//
// Purpose: Service for generating video subtitles using speech recognition
// Author: Assistant
// Copyright © 2024 TIKtAIk. All rights reserved.

// Framework: Foundation - Basic functionality
import Foundation
// Framework: Speech - Speech Recognition
import Speech
// Framework: AVFoundation - Media handling
import AVFoundation
// Framework: FirebaseFirestore - Cloud Database
import FirebaseFirestore
// Use existing WhisperSubtitleService
private let whisperService = WhisperSubtitleService()

/// Service for generating and managing video subtitles
@preconcurrency
final class SubtitleGenerationService {
    
    /// Progress callback type
    typealias ProgressHandler = (Double) -> Void
    
    /// Errors that can occur during subtitle generation
    enum GenerationError: LocalizedError {
        case audioExtractionFailed
        case recognitionFailed(String)
        case invalidVideoURL
        case permissionDenied
        
        var errorDescription: String? {
            switch self {
            case .audioExtractionFailed:
                return "Failed to extract audio from video"
            case .recognitionFailed(let message):
                return "Speech recognition failed: \(message)"
            case .invalidVideoURL:
                return "Invalid video URL"
            case .permissionDenied:
                return "Speech recognition permission denied"
            }
        }
    }
    
    private let db = Firestore.firestore()
    
    /// Generates subtitles for a video using Whisper API
    func generateSubtitles(
        for videoURL: URL,
        videoId: String,
        progress: @escaping (Double) -> Void
    ) async throws -> [VideoSubtitle] {
        print("DEBUG: Starting subtitle generation process")
        
        // Create initial metadata
        let metadata = SubtitleMetadata(
            videoId: videoId,
            state: .generating,
            startedAt: Date(),
            preferences: .default
        )
        
        print("DEBUG: Saving initial metadata")
        try await updateMetadata(metadata)
        
        do {
            print("DEBUG: Calling WhisperSubtitleService")
            let subtitles = try await whisperService.generateSubtitles(
                for: videoURL,
                videoId: videoId,
                progress: progress
            )
            
            print("DEBUG: Generated \(subtitles.count) subtitles")
            
            // Update metadata on completion
            var updatedMetadata = metadata
            updatedMetadata.state = .complete
            updatedMetadata.completedAt = Date()
            try await updateMetadata(updatedMetadata)
            
            return subtitles
            
        } catch {
            print("ERROR: Subtitle generation failed - \(error.localizedDescription)")
            
            // Update metadata on failure
            var failedMetadata = metadata
            failedMetadata.state = .failed
            failedMetadata.error = error.localizedDescription
            try await updateMetadata(failedMetadata)
            throw error
        }
    }
    
    /// Updates subtitle metadata in Firestore
    func updateMetadata(_ metadata: SubtitleMetadata) async throws {
        try await db.collection(SubtitleMetadata.collectionName)
            .document(metadata.videoId)
            .setData(metadata.asDictionary)
    }
    
    /// Checks speech recognition permission
    private func checkSpeechRecognitionPermission() async -> Bool {
        let status = SFSpeechRecognizer.authorizationStatus()
        
        if status == .notDetermined {
            return await withCheckedContinuation { continuation in
                SFSpeechRecognizer.requestAuthorization { status in
                    continuation.resume(returning: status == .authorized)
                }
            }
        }
        
        return status == .authorized
    }
    
    // Add WhisperConfig struct
    private struct WhisperConfig {
        let apiKey: String
        let baseURL: URL
        let format: String = "vtt"
        let model: String = "whisper-2"
        let language: String = "en"
    }
    
    // Add WhisperError enum
    private enum WhisperError: LocalizedError {
        case audioExtractionFailed
        case apiError(String)
        case invalidResponse
        case processingFailed
        
        var errorDescription: String? {
            switch self {
            case .audioExtractionFailed: return "Failed to extract audio"
            case .apiError(let message): return message
            case .invalidResponse: return "Invalid API response"
            case .processingFailed: return "Failed to process subtitles"
            }
        }
    }
    
    // Add VTT parsing function
    private func parseVTT(_ vtt: String, videoId: String) throws -> [VideoSubtitle] {
        let lines = vtt.components(separatedBy: .newlines)
        var subtitles: [VideoSubtitle] = []
        var currentText = ""
        var startTime: TimeInterval = 0
        var endTime: TimeInterval = 0
        
        for line in lines {
            if line.contains("-->") {
                let times = line.components(separatedBy: "-->")
                guard times.count == 2,
                      let start = parseTimestamp(times[0].trimmingCharacters(in: .whitespaces)),
                      let end = parseTimestamp(times[1].trimmingCharacters(in: .whitespaces)) else {
                    continue
                }
                startTime = start
                endTime = end
            } else if !line.isEmpty && !line.contains("WEBVTT") {
                currentText = line
                let subtitle = VideoSubtitle(
                    id: UUID().uuidString,
                    videoId: videoId,
                    startTime: startTime,
                    endTime: endTime,
                    text: currentText,
                    isEdited: false,
                    createdAt: Date()
                )
                subtitles.append(subtitle)
            }
        }
        return subtitles
    }
    
    // Add timestamp parsing helper
    private func parseTimestamp(_ timestamp: String) -> TimeInterval? {
        let components = timestamp.components(separatedBy: ":")
        guard components.count == 2,
              let minutes = Double(components[0]),
              let secondsAndMillis = Double(components[1]) else {
            return nil
        }
        return minutes * 60 + secondsAndMillis
    }
    
    // Add subtitle saving function
    private func saveSubtitles(_ subtitles: [VideoSubtitle]) async throws {
        let batch = db.batch()
        
        for subtitle in subtitles {
            let ref = db.collection(VideoSubtitle.collectionName).document(subtitle.id)
            batch.setData(subtitle.asDictionary, forDocument: ref)
        }
        
        try await batch.commit()
    }
} 