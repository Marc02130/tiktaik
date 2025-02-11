import Foundation
import CoreGraphics

protocol VideoTrimming {
    /// Trims video to specified time range
    /// - Parameters:
    ///   - url: Video URL
    ///   - timeRange: Start and end time
    ///   - progress: Progress callback
    /// - Returns: Trimmed video URL
    func trimVideo(url: URL, timeRange: ClosedRange<TimeInterval>, progress: @escaping (Double) -> Void) async throws -> URL
}

protocol VideoCropping {
    /// Crops video to specified rect
    /// - Parameters:
    ///   - url: Video URL
    ///   - rect: Crop rectangle (normalized coordinates 0-1)
    ///   - progress: Progress callback
    /// - Returns: Cropped video URL
    func cropVideo(url: URL, rect: CGRect, progress: @escaping (Double) -> Void) async throws -> URL
}

struct CropConfig {
    static let aspectRatio: CGFloat = 9/16  // Portrait video
    static let minWidth: CGFloat = 0.3      // Minimum 30% of original width
} 