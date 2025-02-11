import AVFoundation
import UIKit
import FirebaseStorage

@preconcurrency
final class VideoEditService: VideoTrimming, VideoCropping {
    
    /// Progress callback type for video operations
    typealias ProgressHandler = (Double) -> Void
    
    private func exportVideo(asset: AVAsset, to outputURL: URL, progress: @escaping ProgressHandler) async throws {
        // Get input file type from output URL
        let inputExtension = outputURL.pathExtension.lowercased()
        let inputFileType: AVFileType = {
            switch inputExtension {
            case "mov":
                return .mov
            case "mp4":
                return .mp4
            case "m4v":
                return .m4v
            default:
                print("DEBUG: Unknown input format, defaulting to input extension")
                return AVFileType(rawValue: inputExtension)
            }
        }()
        print("DEBUG: Using file type:", inputFileType)
        
        guard let exporter = AVAssetExportSession(
            asset: asset,
            presetName: AVAssetExportPresetPassthrough // Use passthrough to maintain quality
        ) else {
            throw VideoEditingError.exportFailed("Failed to create export session")
        }
        
        exporter.outputURL = outputURL
        exporter.outputFileType = inputFileType // Use input file type
        exporter.shouldOptimizeForNetworkUse = false // Don't compress
        
        print("DEBUG: Output file type:", inputFileType)
        
        for try await state in exporter.states(updateInterval: 0.1) {
            switch state {
            case .pending:
                continue
                
            case .waiting:
                continue
                
            case .exporting(let exportProgress):
                progress(exportProgress.fractionCompleted)
                
            default:
                // Export completed or failed - check file exists
                guard FileManager.default.fileExists(atPath: outputURL.path) else {
                    throw VideoEditingError.exportFailed("Export completed but file not found")
                }
                return
            }
        }
    }
    
    func trimVideo(url: URL, timeRange: ClosedRange<TimeInterval>, progress: @escaping ProgressHandler) async throws -> URL {
        print("DEBUG: Starting video trim operation")
        print("DEBUG: Input URL:", url)
        print("DEBUG: Time range:", timeRange)
        
        // Create a session directory
        let sessionDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("videoEdit-\(UUID().uuidString)")
        
        do {
            // Create session directory
            try FileManager.default.createDirectory(at: sessionDir, withIntermediateDirectories: true)
            print("DEBUG: Created session directory at:", sessionDir.path)
            
            // Create local copy path
            let localURL = sessionDir.appendingPathComponent("input.\(url.pathExtension)")
            
            // Verify source file exists and is readable
            guard FileManager.default.fileExists(atPath: url.path),
                  FileManager.default.isReadableFile(atPath: url.path) else {
                print("DEBUG: Source file does not exist or is not readable at:", url.path)
                throw VideoEditingError.trimFailed("Source video file not found or not readable")
            }
            
            // Get source file size
            let sourceAttributes = try FileManager.default.attributesOfItem(atPath: url.path)
            let sourceSize = (sourceAttributes[.size] as? Int64) ?? 0
            print("DEBUG: Source file size:", sourceSize)
            
            // Copy file using FileHandle
            do {
                // Create empty destination file
                FileManager.default.createFile(atPath: localURL.path, contents: nil)
                
                // Open source file for reading
                let sourceHandle = try FileHandle(forReadingFrom: url)
                defer { try? sourceHandle.close() }
                
                // Open destination file for writing
                let destinationHandle = try FileHandle(forWritingTo: localURL)
                defer { try? destinationHandle.close() }
                
                // Copy in chunks
                let chunkSize = 1024 * 1024 // 1MB chunks
                var bytesWritten: Int64 = 0
                
                while true {
                    let data = try sourceHandle.read(upToCount: chunkSize)
                    guard let data = data, !data.isEmpty else { break }
                    
                    try destinationHandle.write(contentsOf: data)
                    bytesWritten += Int64(data.count)
                    
                    print("DEBUG: Copied \(bytesWritten) of \(sourceSize) bytes")
                }
                
                // Verify file size matches
                let destAttributes = try FileManager.default.attributesOfItem(atPath: localURL.path)
                let destSize = (destAttributes[.size] as? Int64) ?? 0
                
                guard destSize == sourceSize else {
                    print("DEBUG: Size mismatch - source: \(sourceSize), destination: \(destSize)")
                    throw VideoEditingError.trimFailed("File copy size mismatch")
                }
                
                print("DEBUG: Successfully copied file to:", localURL.path)
                
            } catch {
                print("DEBUG: Failed to copy file:", error)
                throw VideoEditingError.trimFailed("Failed to create local copy: \(error.localizedDescription)")
            }
            
            // Create asset using AVURLAsset
            let asset = AVURLAsset(url: localURL)
            print("DEBUG: Created AVURLAsset")
            
            // Load duration synchronously first to validate asset
            do {
                let duration = try await asset.load(.duration)
                print("DEBUG: Successfully loaded duration:", CMTimeGetSeconds(duration))
            } catch {
                print("DEBUG: Failed to load duration:", error)
                try? FileManager.default.removeItem(at: sessionDir)
                throw VideoEditingError.trimFailed("Failed to validate video file")
            }
            
            // Load video track
            let videoTrack: AVAssetTrack
            do {
                let tracks = try await asset.loadTracks(withMediaType: .video)
                guard let track = tracks.first else {
                    throw VideoEditingError.trimFailed("No video track found")
                }
                videoTrack = track
                print("DEBUG: Successfully loaded video track")
            } catch {
                print("DEBUG: Failed to load video track:", error)
                try? FileManager.default.removeItem(at: sessionDir)
                throw VideoEditingError.trimFailed("Failed to load video track: \(error.localizedDescription)")
            }
            
            // Create composition
            let composition = AVMutableComposition()
            guard let compositionTrack = composition.addMutableTrack(
                withMediaType: .video,
                preferredTrackID: kCMPersistentTrackID_Invalid
            ) else {
                // Cleanup
                try? FileManager.default.removeItem(at: sessionDir)
                throw VideoEditingError.trimFailed("Failed to create composition track")
            }
            
            // Create time range
            let cmTimeRange = CMTimeRange(
                start: CMTime(seconds: timeRange.lowerBound, preferredTimescale: 600),
                end: CMTime(seconds: timeRange.upperBound, preferredTimescale: 600)
            )
            
            // Get original transform
            let originalTransform = try await videoTrack.load(.preferredTransform)
            
            // Insert video segment
            do {
                try compositionTrack.insertTimeRange(cmTimeRange, of: videoTrack, at: .zero)
                
                // Apply original transform to maintain orientation
                compositionTrack.preferredTransform = originalTransform
                
                print("DEBUG: Inserted video segment and preserved orientation")
            } catch {
                print("DEBUG: Failed to insert time range:", error)
                // Cleanup
                try? FileManager.default.removeItem(at: sessionDir)
                throw VideoEditingError.trimFailed("Failed to create trimmed video segment")
            }
            
            // Add audio if present
            if let audioTrack = try? await asset.loadTracks(withMediaType: .audio).first,
               let compositionAudioTrack = composition.addMutableTrack(
                withMediaType: .audio,
                preferredTrackID: kCMPersistentTrackID_Invalid
               ) {
                try? compositionAudioTrack.insertTimeRange(cmTimeRange, of: audioTrack, at: .zero)
                print("DEBUG: Added audio track")
            }
            
            // Create export session
            guard let exportSession = AVAssetExportSession(
                asset: composition,
                presetName: AVAssetExportPresetHighestQuality
            ) else {
                // Cleanup
                try? FileManager.default.removeItem(at: sessionDir)
                throw VideoEditingError.exportFailed("Failed to create export session")
            }
            
            print("DEBUG: let outputURL = sessionDir.appendingPathComponent")
            // Setup export
            let outputURL = sessionDir.appendingPathComponent("output.\(url.pathExtension)")
            print("DEBUG: Output URL:", outputURL.path)
            
            // Determine correct file type
            let outputFileType: AVFileType = {
                switch url.pathExtension.lowercased() {
                case "mov":
                    return .mov
                case "mp4":
                    return .mp4
                case "m4v":
                    return .m4v
                default:
                    print("DEBUG: Unknown extension, defaulting to MOV")
                    return .mov
                }
            }()
            print("DEBUG: Using output file type:", outputFileType)
            
            // Calculate duration from time range
            let duration = CMTime(seconds: timeRange.upperBound - timeRange.lowerBound, preferredTimescale: 600)
            print("DEBUG: Calculated duration:", CMTimeGetSeconds(duration))

            exportSession.outputURL = outputURL
            exportSession.outputFileType = outputFileType
            exportSession.timeRange = CMTimeRange(start: .zero, duration: duration)
            exportSession.shouldOptimizeForNetworkUse = true
            
            print("DEBUG: Starting export to:", outputURL.path)
            
            // Monitor progress
            let progressTask = Task {
                for await state in exportSession.states(updateInterval: 0.1) {
                    if case .exporting(let exportProgress) = state {
                        await MainActor.run {
                            progress(exportProgress.fractionCompleted)
                        }
                    }
                }
            }
            
            do {
                try await exportSession.export(to: outputURL, as: outputFileType)
                print("DEBUG: Export completed")
                
                // 1. Upload trimmed video in same format to replace original
                let storageRef = Storage.storage().reference()
                let videoPath = url.lastPathComponent // Get original video path
                let videoRef = storageRef.child("videos/\(videoPath)") // Use same path to replace
                
                print("DEBUG: Uploading trimmed video to replace:", videoPath)
                
                let metadata = StorageMetadata()
                metadata.contentType = "video/quicktime"
                
                _ = try await videoRef.putFileAsync(from: outputURL, metadata: metadata) { progress in
                    if let progress = progress {
                        let percentComplete = Double(progress.completedUnitCount) / Double(progress.totalUnitCount)
                        print("DEBUG: Upload progress:", percentComplete)
                    }
                }
                
                print("DEBUG: Upload completed")
                
                // 2. Set thumbnails to null in video document
                // Note: This should be handled by the calling code since we don't have access to Firestore here
                
                // 3. Delete old video from storage is not needed since we replaced it
                
                // Return the URL for the trimmed video
                return outputURL
            } catch {
                print("DEBUG: Export/upload failed:", error)
                // Cleanup
                try? FileManager.default.removeItem(at: sessionDir)
                throw VideoEditingError.exportFailed(error.localizedDescription)
            }
        } catch {
            print("DEBUG: Operation failed:", error)
            // Cleanup
            try? FileManager.default.removeItem(at: sessionDir)
            throw error
        }
    }
    
    private func exportVideo(composition: AVComposition, to outputURL: URL, progress: @escaping ProgressHandler) async throws {
        // Get input file type from output URL
        let inputExtension = outputURL.pathExtension.lowercased()
        let inputFileType: AVFileType = {
            switch inputExtension {
            case "mov":
                return .mov
            case "mp4":
                return .mp4
            case "m4v":
                return .m4v
            default:
                print("DEBUG: Unknown input format, defaulting to input extension")
                return AVFileType(rawValue: inputExtension)
            }
        }()
        print("DEBUG: Using file type:", inputFileType)
        
        guard let export = AVAssetExportSession(
            asset: composition,
            presetName: AVAssetExportPresetPassthrough // Use passthrough to maintain quality
        ) else {
            throw VideoEditingError.exportFailed("Could not create export session")
        }
        
        export.outputURL = outputURL
        export.outputFileType = inputFileType // Use input file type
        export.shouldOptimizeForNetworkUse = false // Don't compress
        
        print("DEBUG: Output file type:", inputFileType)
        
        // Monitor progress using async stream
        print("DEBUG: Starting progress monitoring")
        let progressTask = Task {
            for await state in export.states(updateInterval: 0.1) {
                if case .exporting(let exportProgress) = state {
                    print("DEBUG: Export progress:", exportProgress.fractionCompleted)
                    progress(exportProgress.fractionCompleted)
                }
            }
        }
        
        // Export using modern API with correct file type
        print("DEBUG: Starting export operation")
        do {
            try await export.export(to: outputURL, as: inputFileType)
            print("DEBUG: Export operation completed")
        } catch {
            print("DEBUG: Export failed:", error)
            throw error
        }
        progressTask.cancel()
        
        // Verify export succeeded
        print("DEBUG: Verifying exported file")
        guard FileManager.default.fileExists(atPath: outputURL.path) else {
            print("DEBUG: Export file not found at path:", outputURL.path)
            throw VideoEditingError.exportFailed("Export completed but file not found")
        }
        print("DEBUG: Export file verified at path:", outputURL.path)
    }
    
    func cropVideo(url: URL, rect: CGRect, progress: @escaping ProgressHandler) async throws -> URL {
        // Get input file extension
        let inputExtension = url.pathExtension.lowercased()
        print("DEBUG: Input file extension:", inputExtension)
        
        let asset = AVURLAsset(url: url)
        let composition = AVMutableComposition()
        let videoComposition = AVMutableVideoComposition()
        
        guard let compositionTrack = composition.addMutableTrack(
            withMediaType: .video,
            preferredTrackID: kCMPersistentTrackID_Invalid
        ),
        let assetTrack = try? await asset.loadTracks(withMediaType: .video).first else {
            throw VideoEditingError.cropFailed("Failed to create composition track")
        }
        
        // Get video properties
        let naturalSize = try await assetTrack.load(.naturalSize)
        let transform = try await assetTrack.load(.preferredTransform)
        
        // Insert full video
        try compositionTrack.insertTimeRange(
            CMTimeRange(start: .zero, duration: try await asset.load(.duration)),
            of: assetTrack,
            at: .zero
        )
        
        // Setup video composition
        let instruction = AVMutableVideoCompositionInstruction()
        instruction.timeRange = CMTimeRange(
            start: .zero,
            duration: try await composition.load(.duration)
        )
        
        let layerInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: compositionTrack)
        
        // Keep original transform
        layerInstruction.setTransform(transform, at: .zero)
        
        // Apply crop in transformed coordinate space
        let cropRect = CGRect(
            x: naturalSize.height * rect.minX,  // Use height for x because video is rotated
            y: naturalSize.width * rect.minY,   // Use width for y because video is rotated
            width: naturalSize.height * rect.width,
            height: naturalSize.width * rect.height
        )
        layerInstruction.setCropRectangle(cropRect, at: .zero)
        
        instruction.layerInstructions = [layerInstruction]
        
        videoComposition.instructions = [instruction]
        videoComposition.frameDuration = CMTime(value: 1, timescale: 30)
        videoComposition.renderSize = CGSize(width: cropRect.width, height: cropRect.height)
        
        print("DEBUG: Video properties:")
        print("Natural size:", naturalSize)
        print("Transform:", transform)
        print("Crop rect:", cropRect)
        
        let outputURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension(inputExtension)
        
        try await exportVideo(asset: composition, to: outputURL, progress: progress)
        
        return outputURL
    }
    
    private func cleanupTemporaryFiles() {
        let tempDirectory = FileManager.default.temporaryDirectory
        do {
            let files = try FileManager.default.contentsOfDirectory(at: tempDirectory, includingPropertiesForKeys: nil)
            // Clean up all video files
            for file in files where ["mp4", "mov", "m4v"].contains(file.pathExtension.lowercased()) {
                try? FileManager.default.removeItem(at: file)
            }
        } catch {
            print("Failed to cleanup temporary files:", error)
        }
    }
} 