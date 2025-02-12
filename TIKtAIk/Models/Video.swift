import Foundation
import FirebaseFirestore
import FirebaseStorage

/// Video content model
struct Video: Identifiable, Codable, Equatable {
    /// Unique video identifier
    let id: String
    /// Creator's user ID
    let userId: String
    /// Video title
    let title: String
    /// Optional video description
    let description: String?
    /// Video metadata
    let metadata: VideoMetadata
    /// Video statistics
    var stats: Stats
    /// Processing status
    let status: Status
    /// Storage URL for video file
    let storageUrl: String
    /// Optional thumbnail URL
    let thumbnailUrl: String?
    /// Creation timestamp
    let createdAt: Date
    /// Last update timestamp
    var updatedAt: Date
    /// Video tags
    let tags: Set<String>
    /// Whether video is private
    let isPrivate: Bool
    /// Whether comments are allowed
    let allowComments: Bool
    /// Cached download URL
    private(set) var downloadUrl: String?
    
    /// Get video URL for playback
    /// - Returns: Download URL for the video
    func getVideoURL() async throws -> URL {
        // Get download URL from storage
        let storage = Storage.storage()
        let ref = storage.reference(withPath: storageUrl)
        return try await ref.downloadURL()
    }
    
    /// Video metadata information
    struct VideoMetadata: Codable {
        let duration: Double
        let width: Int
        let height: Int
        let size: Int
        let format: String?
        let resolution: String?
        let uploadDate: Date?
        let lastModified: Date?
        
        enum CodingKeys: String, CodingKey {
            case duration
            case width
            case height
            case size
            case format
            case resolution
            case uploadDate
            case lastModified
        }
        
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            
            // Try to decode width/height from resolution if direct fields are missing
            if let width = try? container.decode(Int.self, forKey: .width) {
                self.width = width
            } else if let resolution = try? container.decode(String.self, forKey: .resolution) {
                let dimensions = resolution.split(separator: "x")
                if dimensions.count == 2, let width = Int(String(dimensions[0])) {
                    self.width = width
                } else {
                    self.width = 0
                }
            } else {
                self.width = 0
            }
            
            if let height = try? container.decode(Int.self, forKey: .height) {
                self.height = height
            } else if let resolution = try? container.decode(String.self, forKey: .resolution) {
                let dimensions = resolution.split(separator: "x")
                if dimensions.count == 2, let height = Int(String(dimensions[1])) {
                    self.height = height
                } else {
                    self.height = 0
                }
            } else {
                self.height = 0
            }
            
            duration = try container.decodeIfPresent(Double.self, forKey: .duration) ?? 0
            size = try container.decodeIfPresent(Int.self, forKey: .size) ?? 0
            format = try container.decodeIfPresent(String.self, forKey: .format)
            resolution = try container.decodeIfPresent(String.self, forKey: .resolution)
            uploadDate = try container.decodeIfPresent(Date.self, forKey: .uploadDate)
            lastModified = try container.decodeIfPresent(Date.self, forKey: .lastModified)
        }
        
        init(
            duration: Double,
            width: Int,
            height: Int,
            size: Int = 0,
            format: String? = nil,
            resolution: String? = nil,
            uploadDate: Date? = nil,
            lastModified: Date? = nil
        ) {
            self.duration = duration
            self.width = width
            self.height = height
            self.size = size
            self.format = format
            self.resolution = resolution
            self.uploadDate = uploadDate
            self.lastModified = lastModified
        }
        
        /// Creates Firestore data dictionary
        var asDictionary: [String: Any] {
            let dict: [String: Any] = [
                "duration": duration,
                "width": width,
                "height": height,
                "size": size,
                "format": format as Any,
                "resolution": resolution as Any,
                "uploadDate": uploadDate as Any,
                "lastModified": lastModified as Any
            ]
            return dict
        }
    }
    
    /// Video engagement statistics
    struct Stats: Codable {
        var views: Int
        var likes: Int
        var shares: Int
        var commentsCount: Int
        
        /// Creates empty stats
        init() {
            self.views = 0
            self.likes = 0
            self.shares = 0
            self.commentsCount = 0
        }
        
        /// Creates stats with values
        init(views: Int, likes: Int, shares: Int, commentsCount: Int) {
            self.views = views
            self.likes = likes
            self.shares = shares
            self.commentsCount = commentsCount
        }
        
        /// Creates Firestore data dictionary
        var asDictionary: [String: Any] {
            let dict: [String: Any] = [
                "views": views,
                "likes": likes,
                "shares": shares,
                "commentsCount": commentsCount
            ]
            return dict
        }
    }
    
    /// Video processing status
    enum Status: String, Codable {
        case processing
        case ready
        case failed
    }
    
    /// Firestore collection name
    static let collectionName = "videos"
    
    /// Creates Firestore data dictionary
    var asDictionary: [String: Any] {
        [
            "id": id,
            "userId": userId,
            "title": title,
            "description": description as Any,
            "metadata": [
                "duration": metadata.duration,
                "width": metadata.width,
                "height": metadata.height,
                "size": metadata.size,
                "format": metadata.format as Any,
                "resolution": metadata.resolution as Any,
                "uploadDate": metadata.uploadDate.map { Timestamp(date: $0) } as Any,
                "lastModified": metadata.lastModified.map { Timestamp(date: $0) } as Any
            ],
            "stats": [
                "views": stats.views,
                "likes": stats.likes,
                "shares": stats.shares,
                "commentsCount": stats.commentsCount
            ],
            "status": status.rawValue,
            "storageUrl": storageUrl,
            "thumbnailUrl": thumbnailUrl as Any,
            "createdAt": Timestamp(date: createdAt),
            "updatedAt": Timestamp(date: updatedAt),
            "tags": Array(tags),
            "isPrivate": isPrivate,
            "allowComments": allowComments
        ]
    }
    
    /// Creates Video from Firestore document
    static func from(_ document: QueryDocumentSnapshot) throws -> Video {
        let data = document.data()
        
        let metadata = data["metadata"] as? [String: Any] ?? [:]
        let stats = data["stats"] as? [String: Any] ?? [:]
        
        return Video(
            id: document.documentID,
            userId: data["userId"] as? String ?? "",
            title: data["title"] as? String ?? "",
            description: data["description"] as? String,
            metadata: VideoMetadata(
                duration: metadata["duration"] as? Double ?? 0,
                width: metadata["width"] as? Int ?? 0,
                height: metadata["height"] as? Int ?? 0,
                size: metadata["size"] as? Int ?? 0,
                format: metadata["format"] as? String,
                resolution: metadata["resolution"] as? String,
                uploadDate: (metadata["uploadDate"] as? Timestamp)?.dateValue(),
                lastModified: (metadata["lastModified"] as? Timestamp)?.dateValue()
            ),
            stats: Stats(
                views: stats["views"] as? Int ?? 0,
                likes: stats["likes"] as? Int ?? 0,
                shares: stats["shares"] as? Int ?? 0,
                commentsCount: stats["commentsCount"] as? Int ?? 0
            ),
            status: Status(rawValue: data["status"] as? String ?? "") ?? .ready,
            storageUrl: data["storageUrl"] as? String ?? "",
            thumbnailUrl: data["thumbnailUrl"] as? String,
            createdAt: (data["createdAt"] as? Timestamp)?.dateValue() ?? Date(),
            updatedAt: (data["updatedAt"] as? Timestamp)?.dateValue() ?? Date(),
            tags: Set(data["tags"] as? [String] ?? []),
            isPrivate: data["isPrivate"] as? Bool ?? false,
            allowComments: data["allowComments"] as? Bool ?? true
        )
    }
    
    /// Add overload for DocumentSnapshot
    static func from(_ document: DocumentSnapshot) throws -> Video {
        guard let data = document.data() else {
            throw VideoError.invalidData
        }
        
        let metadata = data["metadata"] as? [String: Any] ?? [:]
        let stats = data["stats"] as? [String: Any] ?? [:]
        
        return Video(
            id: document.documentID,
            userId: data["userId"] as? String ?? "",
            title: data["title"] as? String ?? "",
            description: data["description"] as? String,
            metadata: VideoMetadata(
                duration: metadata["duration"] as? Double ?? 0,
                width: metadata["width"] as? Int ?? 0,
                height: metadata["height"] as? Int ?? 0,
                size: metadata["size"] as? Int ?? 0,
                format: metadata["format"] as? String,
                resolution: metadata["resolution"] as? String,
                uploadDate: (metadata["uploadDate"] as? Timestamp)?.dateValue(),
                lastModified: (metadata["lastModified"] as? Timestamp)?.dateValue()
            ),
            stats: Stats(
                views: stats["views"] as? Int ?? 0,
                likes: stats["likes"] as? Int ?? 0,
                shares: stats["shares"] as? Int ?? 0,
                commentsCount: stats["commentsCount"] as? Int ?? 0
            ),
            status: Status(rawValue: data["status"] as? String ?? "") ?? .ready,
            storageUrl: data["storageUrl"] as? String ?? "",
            thumbnailUrl: data["thumbnailUrl"] as? String,
            createdAt: (data["createdAt"] as? Timestamp)?.dateValue() ?? Date(),
            updatedAt: (data["updatedAt"] as? Timestamp)?.dateValue() ?? Date(),
            tags: Set(data["tags"] as? [String] ?? []),
            isPrivate: data["isPrivate"] as? Bool ?? false,
            allowComments: data["allowComments"] as? Bool ?? true
        )
    }
    
    static func == (lhs: Video, rhs: Video) -> Bool {
        lhs.id == rhs.id &&
        lhs.updatedAt == rhs.updatedAt
    }
}

// Add at the top of the file with other enums
enum VideoError: LocalizedError {
    case invalidData
    case notFound
    case uploadFailed
    case updateFailed
    
    var errorDescription: String? {
        switch self {
        case .invalidData:
            return "Invalid video data"
        case .notFound:
            return "Video not found"
        case .uploadFailed:
            return "Failed to upload video"
        case .updateFailed:
            return "Failed to update video"
        }
    }
} 