// Framework: Foundation - Basic functionality
import Foundation
// Framework: SwiftUI - UI Framework
import SwiftUI
// Framework: CoreGraphics - Graphics Types
import CoreGraphics
// Framework: FirebaseFirestore - Cloud Database
import FirebaseFirestore

/// Preferences for subtitle display in video player
struct SubtitlePreferences: Codable, Hashable {
    /// Font size options
    enum FontSize: String, Codable, CaseIterable {
        case small = "S"
        case medium = "M"
        case large = "L"
        
        var points: CGFloat {
            switch self {
            case .small: return 14
            case .medium: return 18
            case .large: return 24
            }
        }
        
        // Add font property
        var font: Font {
            Font.system(size: points, weight: .medium)
        }
    }
    
    /// Color options for subtitles
    enum TextColor: String, Codable, CaseIterable {
        case white
        case yellow
        
        var color: Color {
            switch self {
            case .white: return .white
            case .yellow: return .yellow
            }
        }
    }
    
    /// Position options for subtitles
    enum Position: String, Codable, CaseIterable {
        case top
        case bottom
    }
    
    /// Font size preference
    var fontSize: FontSize = .medium
    
    /// Text color preference
    var textColor: TextColor = .white
    
    /// Position preference
    var position: Position = .bottom
    
    /// Shadow radius for better visibility
    var shadowRadius: CGFloat = 2
    
    /// Default preferences
    static let `default` = SubtitlePreferences()
}

/// A single subtitle entry
struct VideoSubtitle: Codable, Identifiable, Hashable {
    /// Unique identifier
    let id: String
    /// Associated video ID
    let videoId: String
    /// Start time in seconds
    var startTime: TimeInterval  // Made mutable for timing adjustments
    /// End time in seconds
    var endTime: TimeInterval    // Made mutable for timing adjustments
    /// Subtitle text
    var text: String            // Made mutable for editing
    /// Whether subtitle has been edited
    var isEdited: Bool
    /// Creation timestamp
    let createdAt: Date
    
    /// Firestore collection name
    static let collectionName = "subtitles"
    
    /// Dictionary representation for Firestore
    var asDictionary: [String: Any] {
        [
            "id": id,
            "videoId": videoId,
            "startTime": startTime,
            "endTime": endTime,
            "text": text,
            "isEdited": isEdited,
            "createdAt": Timestamp(date: createdAt)
        ]
    }
    
    /// Create from Firestore document
    static func from(_ document: DocumentSnapshot) throws -> VideoSubtitle {
        guard let data = document.data() else {
            throw FirestoreError.invalidData
        }
        
        return VideoSubtitle(
            id: document.documentID,
            videoId: data["videoId"] as? String ?? "",
            startTime: data["startTime"] as? TimeInterval ?? 0,
            endTime: data["endTime"] as? TimeInterval ?? 0,
            text: data["text"] as? String ?? "",
            isEdited: data["isEdited"] as? Bool ?? false,
            createdAt: (data["createdAt"] as? Timestamp)?.dateValue() ?? Date()
        )
    }
}

/// Metadata for subtitle processing
struct SubtitleMetadata: Codable, Hashable {
    /// ID of the video
    let videoId: String
    /// Current generation state
    var state: SubtitleState
    /// Error message if failed
    var error: String?
    /// Processing start time
    let startedAt: Date?
    /// Processing completion time
    var completedAt: Date?
    /// Display preferences
    var preferences: SubtitlePreferences
    
    /// Firestore collection name
    static let collectionName = "subtitleMetadata"
    
    /// Dictionary representation for Firestore
    var asDictionary: [String: Any] {
        var dict: [String: Any] = [
            "videoId": videoId,
            "state": state.rawValue,
            "startedAt": startedAt.map { Timestamp(date: $0) } as Any,
            "completedAt": completedAt.map { Timestamp(date: $0) } as Any
        ]
        
        // Add optional values
        if let error = error {
            dict["error"] = error
        }
        if let preferencesData = try? JSONEncoder().encode(preferences) {
            dict["preferences"] = preferencesData
        }
        
        return dict
    }
    
    /// Create from Firestore document
    static func from(_ document: DocumentSnapshot) throws -> SubtitleMetadata {
        guard let data = document.data() else {
            throw FirestoreError.invalidData
        }
        
        return SubtitleMetadata(
            videoId: data["videoId"] as? String ?? "",
            state: SubtitleState(rawValue: data["state"] as? String ?? "") ?? .notStarted,
            error: data["error"] as? String,
            startedAt: (data["startedAt"] as? Timestamp)?.dateValue(),
            completedAt: (data["completedAt"] as? Timestamp)?.dateValue(),
            preferences: try data["preferences"].flatMap { 
                guard let data = $0 as? Data else { return .default }
                return try JSONDecoder().decode(SubtitlePreferences.self, from: data)
            } ?? .default
        )
    }
}

/// Status of subtitle generation
enum SubtitleState: String, Codable, Hashable {
    case notStarted
    case generating
    case complete
    case failed
}

/// Firestore related errors
enum FirestoreError: Error {
    case invalidData
    case decodingFailed
} 