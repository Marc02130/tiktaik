import Foundation
import FirebaseFirestore

/// Like engagement model
struct Like: Codable {
    /// User who liked
    let userId: String
    /// Video that was liked
    let videoId: String
    /// Creation timestamp
    let createdAt: Date
    
    /// Firestore collection name
    static let collectionName = "likes"
    
    /// Creates Firestore data dictionary
    var asDictionary: [String: Any] {
        [
            "userId": userId,
            "videoId": videoId,
            "createdAt": Timestamp(date: createdAt)
        ]
    }
}

/// Follow relationship model
struct Follow: Codable {
    /// User who is following
    let followerId: String
    /// User being followed
    let followedId: String
    /// Creation timestamp
    let createdAt: Date
    
    /// Firestore collection name
    static let collectionName = "follows"
    
    /// Creates Firestore data dictionary
    var asDictionary: [String: Any] {
        [
            "followerId": followerId,
            "followedId": followedId,
            "createdAt": Timestamp(date: createdAt)
        ]
    }
} 