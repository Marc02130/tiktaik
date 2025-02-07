//
// UserProfile.swift
// TIKtAIk
//
// Created: 2024-02-14
// Last modified: 2024-02-14
//
// Purpose: Model representing a user's profile data, matching Firestore schema
// Author: Assistant
// Copyright © 2024 TIKtAIk. All rights reserved.
//

import Foundation
import FirebaseFirestore

/// User profile data model
struct UserProfile: Codable, Identifiable {
    /// Firebase user ID
    let id: String
    /// User's email address
    let email: String
    /// Display username
    var username: String
    /// User type (creator/consumer)
    let userType: UserType
    /// Optional user bio
    var bio: String?
    /// Optional avatar URL
    var avatarUrl: String?
    /// User statistics
    var stats: UserStats
    /// User settings
    var settings: UserSettings
    /// Account creation timestamp
    let createdAt: Date
    /// Last update timestamp
    var updatedAt: Date
    /// User's content interests/tags
    var interests: Set<String>
    
    /// Types of user accounts
    enum UserType: String, Codable, CaseIterable {
        case creator
        case consumer
    }
    
    /// User statistics
    struct UserStats: Codable {
        var followersCount: Int
        var followingCount: Int
        var videosCount: Int
        var likesCount: Int
        
        init(followersCount: Int = 0, followingCount: Int = 0, videosCount: Int = 0, likesCount: Int = 0) {
            self.followersCount = followersCount
            self.followingCount = followingCount
            self.videosCount = videosCount
            self.likesCount = likesCount
        }
    }
    
    /// User settings
    struct UserSettings: Codable {
        var isPrivate: Bool
        var notificationsEnabled: Bool
        var allowComments: Bool
        
        init(isPrivate: Bool = false, notificationsEnabled: Bool = true, allowComments: Bool = true) {
            self.isPrivate = isPrivate
            self.notificationsEnabled = notificationsEnabled
            self.allowComments = allowComments
        }
    }
    
    /// Firestore collection name
    static let collectionName = "users"
    
    /// Creates Firestore data dictionary
    var asDictionary: [String: Any] {
        [
            "id": id,
            "email": email,
            "username": username,
            "userType": userType.rawValue,
            "bio": bio as Any,
            "avatarUrl": avatarUrl as Any,
            "stats": [
                "followersCount": stats.followersCount,
                "followingCount": stats.followingCount,
                "videosCount": stats.videosCount,
                "likesCount": stats.likesCount
            ],
            "settings": [
                "isPrivate": settings.isPrivate,
                "notificationsEnabled": settings.notificationsEnabled,
                "allowComments": settings.allowComments
            ],
            "createdAt": Timestamp(date: createdAt),
            "updatedAt": Timestamp(date: updatedAt),
            "interests": Array(interests)
        ]
    }
    
    /// Creates UserProfile from Firestore document
    static func from(_ document: DocumentSnapshot) throws -> UserProfile {
        guard let data = document.data() else {
            throw NSError(domain: "UserProfile", code: -1, 
                         userInfo: [NSLocalizedDescriptionKey: "Document data was empty"])
        }
        
        let stats = data["stats"] as? [String: Any] ?? [:]
        let settings = data["settings"] as? [String: Any] ?? [:]
        
        return UserProfile(
            id: document.documentID,
            email: data["email"] as? String ?? "",
            username: data["username"] as? String ?? "",
            userType: UserType(rawValue: data["userType"] as? String ?? "consumer") ?? .consumer,
            bio: data["bio"] as? String,
            avatarUrl: data["avatarUrl"] as? String,
            stats: UserStats(
                followersCount: stats["followersCount"] as? Int ?? 0,
                followingCount: stats["followingCount"] as? Int ?? 0,
                videosCount: stats["videosCount"] as? Int ?? 0,
                likesCount: stats["likesCount"] as? Int ?? 0
            ),
            settings: UserSettings(
                isPrivate: settings["isPrivate"] as? Bool ?? false,
                notificationsEnabled: settings["notificationsEnabled"] as? Bool ?? true,
                allowComments: settings["allowComments"] as? Bool ?? true
            ),
            createdAt: (data["createdAt"] as? Timestamp)?.dateValue() ?? Date(),
            updatedAt: (data["updatedAt"] as? Timestamp)?.dateValue() ?? Date(),
            interests: Set((data["interests"] as? [String]) ?? [])
        )
    }
} 