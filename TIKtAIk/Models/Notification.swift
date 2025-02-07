import Foundation
import FirebaseFirestore

/// User notification model
struct Notification: Identifiable, Codable {
    /// Unique notification identifier
    let id: String
    /// Recipient user ID
    let userId: String
    /// Notification type
    let type: NotificationType
    /// Source user ID (sender)
    let sourceUserId: String
    /// Reference ID (video/comment)
    let referenceId: String
    /// Notification content
    let content: String
    /// Read status
    var isRead: Bool
    /// Creation timestamp
    let createdAt: Date
    
    /// Types of notifications
    enum NotificationType: String, Codable {
        case like
        case comment
        case follow
    }
    
    /// Firestore collection name
    static let collectionName = "notifications"
    
    /// Creates Firestore data dictionary
    var asDictionary: [String: Any] {
        [
            "id": id,
            "userId": userId,
            "type": type.rawValue,
            "sourceUserId": sourceUserId,
            "referenceId": referenceId,
            "content": content,
            "isRead": isRead,
            "createdAt": Timestamp(date: createdAt)
        ]
    }
} 