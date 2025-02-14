1. Core Models:
    User model (profile, settings, stats)
    Video model (metadata, stats, status)
    Comment model (nested replies, likes)
    Like/Reaction model
    Follow/Following relationships
    Notification model

2. Required Classes
- UserModel
    - id: String (Firebase UID)
    - username: String (unique)
    - displayName: String
    - email: String
    - avatarUrl: String?
    - bio: String?
    - stats: {
        followersCount: int,
        followingCount: int,
        videosCount: int,
        likesCount: int
      }
    - settings: {
        isPrivate: bool,
        notificationsEnabled: bool,
        allowComments: bool
      }
    - createdAt: Timestamp
    - updatedAt: Timestamp

- VideoModel
  - id: String
  - userId: String (creator reference)
  - title: String
  - description: String?
  - metadata: {
      duration: int,
      size: int,
      format: String,
      resolution: String?
    }
  - stats: {
      views: int,
      likes: int,
      shares: int,
      commentsCount: int
    }
  - status: String (enum: processing, ready, failed)
  - storageUrl: String
  - thumbnailUrl: String?
  - createdAt: Timestamp
  - updatedAt: Timestamp

- CommentModel
  - id: String
  - videoId: String
  - userId: String
  - parentId: String? (for replies)
  - content: String
  - likesCount: int
  - replyCount: int
  - createdAt: Timestamp
  - updatedAt: Timestamp

- NotificationModel
    - id: String
    - userId: String (recipient)
    - type: String (enum: like, comment, follow)
    - sourceUserId: String (sender)
    - referenceId: String (video/comment id)
    - content: String
    - isRead: bool
    - createdAt: Timestamp

    Services:
    - UserService (auth, profile management)
    - VideoService (uploads, metadata)
    - StorageService (file handling)
    - CommentService (CRUD operations)
    - NotificationService
    - AnalyticsService

Relationships to consider:
    User -> Videos (one-to-many)
    User -> Followers (many-to-many)
    Video -> Comments (one-to-many)
    User -> Notifications (one-to-many)
    Video -> Likes (many-to-many)

Implementation priorities:
    Video upload/storage
    User authentication/profile
    Social connections
    Engagement features
    Notifications

2. Firestore Collections:
- /users
- /videos
- /comments
- /notifications
- /likes
- /follows

3. Indexes Required:
- videos: userId + createdAt (for user's video list)
- comments: videoId + createdAt (for video comments)
- notifications: userId + createdAt (for user notifications)
- likes: videoId + userId (for checking user likes)

4. Security Rules Considerations:
- Public read for videos/comments
- Authenticated writes
- Owner-only updates
- Profile privacy settings