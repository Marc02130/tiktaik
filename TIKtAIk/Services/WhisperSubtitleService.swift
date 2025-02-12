// Framework: Foundation - Basic functionality
import Foundation
// Framework: AVFoundation - Audio processing
import AVFoundation

/// Service for generating subtitles using OpenAI's Whisper API
final class WhisperSubtitleService {
    
    /// Errors that can occur during subtitle generation
    enum WhisperError: LocalizedError {
        case audioExtractionFailed
        case apiError(String)
        case invalidResponse
        case processingFailed
        
        var errorDescription: String? {
            switch self {
            case .audioExtractionFailed:
                return "Failed to extract audio from video"
            case .apiError(let message):
                return "Whisper API error: \(message)"
            case .invalidResponse:
                return "Invalid response from Whisper API"
            case .processingFailed:
                return "Failed to process subtitles"
            }
        }
    }
    
    private let apiKey: String
    private let baseURL = URL(string: "\(Secrets.openAIBaseURL)/audio/transcriptions")!
    
    init(apiKey: String = Secrets.openAIKey) {
        self.apiKey = apiKey
    }
    
    /// Generates subtitles for a video using Whisper API
    /// - Parameters:
    ///   - videoURL: URL of the video file
    ///   - videoId: ID of the video
    ///   - progress: Progress callback
    /// - Returns: Array of generated subtitles
    func generateSubtitles(
        for videoURL: URL,
        videoId: String,
        progress: @escaping (Double) -> Void
    ) async throws -> [VideoSubtitle] {
        print("DEBUG: Starting subtitle generation for video at \(videoURL)")
        
        // Run diagnostics (keep this for debugging)
        do {
            // Check if file exists
            let exists = FileManager.default.fileExists(atPath: videoURL.path)
            print("DEBUG: Video file exists: \(exists)")
            
            // Check file attributes
            if exists {
                let attributes = try FileManager.default.attributesOfItem(atPath: videoURL.path)
                print("DEBUG: File attributes:")
                print("- Size: \(attributes[.size] ?? 0) bytes")
                print("- Created: \(attributes[.creationDate] ?? Date())")
                print("- Modified: \(attributes[.modificationDate] ?? Date())")
                print("- Permissions: \(attributes[.posixPermissions] ?? 0)")
                print("- Owner: \(attributes[.ownerAccountName] ?? "unknown")")
            }
            
            // Check if file is readable
            let isReadable = FileManager.default.isReadableFile(atPath: videoURL.path)
            print("DEBUG: File is readable: \(isReadable)")
            
            // Try to get file handle
            if let handle = try? FileHandle(forReadingFrom: videoURL) {
                print("DEBUG: Successfully opened file handle")
                if let length = try? handle.seekToEnd() {
                    print("DEBUG: File length from handle: \(length) bytes")
                }
                try? handle.close()
            } else {
                print("ERROR: Could not open file handle")
            }
            
            // List temp directory contents
            let tempContents = try FileManager.default.contentsOfDirectory(atPath: videoURL.deletingLastPathComponent().path)
            print("DEBUG: Temp directory contents: \(tempContents)")
            
        } catch {
            print("ERROR: File diagnostics failed - \(error.localizedDescription)")
        }
        
        do {
            // Create asset with explicit file URL
            let fileURL = URL(fileURLWithPath: videoURL.path)
            print("DEBUG: Created file URL: \(fileURL)")
            print("DEBUG: File URL scheme: \(fileURL.scheme ?? "none")")

            let asset = AVURLAsset(url: fileURL, options: [
                AVURLAssetPreferPreciseDurationAndTimingKey: true
            ])
            print("DEBUG: Created AVURLAsset")
            
            // Get audio tracks with detailed error handling
            let audioTracks: [AVAssetTrack]
            do {
                audioTracks = try await asset.loadTracks(withMediaType: .audio)
                print("DEBUG: audioTracks loaded")
            } catch let error as NSError {
                print("ERROR: Failed to load audio tracks")
                print("- Error domain: \(error.domain)")
                print("- Error code: \(error.code)")
                print("- Description: \(error.localizedDescription)")
                print("- Debug description: \(error.debugDescription)")
                print("- Failure reason: \(error.localizedFailureReason ?? "none")")
                print("- Recovery suggestion: \(error.localizedRecoverySuggestion ?? "none")")
                print("- Underlying error: \(error.underlyingErrors)")
                print("- User info: \(error.userInfo)")
                throw WhisperError.audioExtractionFailed
            }
            
            guard let audioTrack = audioTracks.first else {
                print("ERROR: No audio tracks found in video")
                throw WhisperError.audioExtractionFailed
            }
            
            // Setup output path for audio
            let outputURL = FileManager.default.temporaryDirectory
                .appendingPathComponent(UUID().uuidString)
                .appendingPathExtension("m4a")
            print("DEBUG: Output audio path: \(outputURL)")
            
            // Create export session
            guard let session = AVAssetExportSession(
                asset: asset,
                presetName: AVAssetExportPresetAppleM4A
            ) else {
                print("ERROR: Failed to create export session")
                throw WhisperError.audioExtractionFailed
            }
            
            // Configure and run export
            session.outputURL = outputURL
            session.outputFileType = .m4a
            print("DEBUG: Export session configured")

            // Export directly
            await session.export()

            // Check result
            guard FileManager.default.fileExists(atPath: outputURL.path) else {
                print("ERROR: Audio file not found at path")
                throw WhisperError.audioExtractionFailed
            }

            print("DEBUG: Audio extracted to \(outputURL)")
            progress(0.3)
            
            // Create and send request
            print("DEBUG: Creating Whisper API request...")
            let request = try createWhisperRequest(audioURL: outputURL)
            print("DEBUG: Sending request to Whisper API...")
            let (data, response) = try await URLSession.shared.data(for: request)
            progress(0.7)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw WhisperError.invalidResponse
            }
            
            print("DEBUG: Received response with status: \(httpResponse.statusCode)")
            
            if httpResponse.statusCode != 200 {
                if let errorJson = try? JSONDecoder().decode([String: String].self, from: data),
                   let errorMessage = errorJson["error"] {
                    throw WhisperError.apiError(errorMessage)
                }
                throw WhisperError.apiError("Status code: \(httpResponse.statusCode)")
            }
            
            guard let vtt = String(data: data, encoding: .utf8) else {
                throw WhisperError.invalidResponse
            }
            
            print("DEBUG: Successfully received VTT response")
            progress(0.9)
            
            // 3. Parse response
            let subtitles = try parseVTT(vtt, videoId: videoId)
            print("DEBUG: Generated \(subtitles.count) subtitles")
            
            return subtitles
            
        } catch {
            print("ERROR: Subtitle generation failed - \(error.localizedDescription)")
            throw error
        }
    }
    
    /// Creates multipart form data with audio file
    private func createFormData(
        audioURL: URL,
        boundary: String,
        format: String
    ) throws -> Data {
        var data = Data()
        
        // Add audio file
        guard let audioData = try? Data(contentsOf: audioURL) else {
            print("ERROR: Failed to read audio file data")
            throw WhisperError.audioExtractionFailed
        }
        
        data.append("--\(boundary)\r\n")
        data.append("Content-Disposition: form-data; name=\"file\"; filename=\"audio.m4a\"\r\n")
        data.append("Content-Type: audio/m4a\r\n\r\n")
        data.append(audioData)
        data.append("\r\n")
        
        // Add required parameters
        data.append("--\(boundary)\r\n")
        data.append("Content-Disposition: form-data; name=\"model\"\r\n\r\n")
        data.append("whisper-1\r\n")
        
        data.append("--\(boundary)\r\n")
        data.append("Content-Disposition: form-data; name=\"response_format\"\r\n\r\n")
        data.append("\(format)\r\n")
        
        data.append("--\(boundary)--\r\n")
        return data
    }
    
    /// Creates request for Whisper API
    private func createWhisperRequest(audioURL: URL) throws -> URLRequest {
        var request = URLRequest(url: baseURL)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        
        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        let formData = try createFormData(
            audioURL: audioURL,
            boundary: boundary,
            format: "vtt"
        )
        request.httpBody = formData
        
        return request
    }
    
    /// Parses VTT response into subtitles
    private func parseVTT(_ vtt: String, videoId: String) throws -> [VideoSubtitle] {
        print("DEBUG: Parsing VTT response")
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
        
        print("DEBUG: Parsed \(subtitles.count) subtitles")
        return subtitles
    }
    
    /// Parses VTT timestamp into TimeInterval
    private func parseTimestamp(_ timestamp: String) -> TimeInterval? {
        // Split hours:minutes:seconds.milliseconds
        let parts = timestamp.components(separatedBy: ":")
        guard parts.count >= 2 else { return nil }
        
        let hours = parts.count == 3 ? (Double(parts[0]) ?? 0) : 0
        let minutes = Double(parts[parts.count == 3 ? 1 : 0] ?? "0") ?? 0
        
        // Handle seconds.milliseconds
        let secondParts = (parts.last ?? "").components(separatedBy: ".")
        let seconds = Double(secondParts[0]) ?? 0
        let milliseconds = Double("0." + (secondParts.last ?? "0")) ?? 0
        
        return hours * 3600 + minutes * 60 + seconds + milliseconds
    }
}

// MARK: - Data Extensions
private extension Data {
    mutating func append(_ string: String) {
        append(string.data(using: .utf8)!)
    }
} 