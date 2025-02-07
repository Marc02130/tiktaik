//
// UserProfileTests.swift
// TIKtAIk
//
// Created: 2024-02-14
// Last modified: 2024-02-14
//
// Purpose: Unit tests for UserProfile model
// Author: Assistant
// Copyright © 2024 TIKtAIk. All rights reserved.
//

import XCTest
@testable import TIKtAIk
import FirebaseFirestore

final class UserProfileTests: XCTestCase {
    
    func testUserProfileInitialization() {
        let profile = UserProfile(
            id: "test123",
            username: "testuser",
            displayName: "Test User",
            email: "test@example.com",
            profileType: .creator
        )
        
        XCTAssertEqual(profile.id, "test123")
        XCTAssertEqual(profile.username, "testuser")
        XCTAssertEqual(profile.displayName, "Test User")
        XCTAssertEqual(profile.email, "test@example.com")
        XCTAssertEqual(profile.profileType, .creator)
        XCTAssertNil(profile.avatarUrl)
        XCTAssertNil(profile.bio)
        XCTAssertEqual(profile.stats.followersCount, 0)
        XCTAssertFalse(profile.settings.isPrivate)
    }
    
    func testUserProfileCoding() throws {
        let original = UserProfile(
            id: "test123",
            username: "testuser",
            displayName: "Test User",
            email: "test@example.com",
            profileType: .creator,
            avatarUrl: "https://example.com/avatar.jpg",
            bio: "Test bio"
        )
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(original)
        
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(UserProfile.self, from: data)
        
        XCTAssertEqual(decoded.id, original.id)
        XCTAssertEqual(decoded.username, original.username)
        XCTAssertEqual(decoded.displayName, original.displayName)
        XCTAssertEqual(decoded.email, original.email)
        XCTAssertEqual(decoded.profileType, original.profileType)
        XCTAssertEqual(decoded.avatarUrl, original.avatarUrl)
        XCTAssertEqual(decoded.bio, original.bio)
    }
    
    func testUserProfileFirestoreConversion() throws {
        let profile = UserProfile(
            id: "test123",
            username: "testuser",
            displayName: "Test User",
            email: "test@example.com",
            profileType: .creator
        )
        
        // Convert to Firestore data
        let firestoreData = try profile.toFirestore()
        
        // Verify data
        XCTAssertEqual(firestoreData["username"] as? String, profile.username)
        XCTAssertEqual(firestoreData["displayName"] as? String, profile.displayName)
        XCTAssertEqual(firestoreData["email"] as? String, profile.email)
        XCTAssertEqual(firestoreData["profileType"] as? String, profile.profileType.rawValue)
    }
    
    func testUserStatsInitialization() {
        let stats = UserStats(
            followersCount: 100,
            followingCount: 50,
            videosCount: 10,
            likesCount: 1000
        )
        
        XCTAssertEqual(stats.followersCount, 100)
        XCTAssertEqual(stats.followingCount, 50)
        XCTAssertEqual(stats.videosCount, 10)
        XCTAssertEqual(stats.likesCount, 1000)
    }
    
    func testUserSettingsInitialization() {
        let settings = UserSettings(
            isPrivate: true,
            notificationsEnabled: false,
            allowComments: true
        )
        
        XCTAssertTrue(settings.isPrivate)
        XCTAssertFalse(settings.notificationsEnabled)
        XCTAssertTrue(settings.allowComments)
    }
    
    func testProfileCreation() {
        let profile = UserProfile(
            id: "test-id",
            email: "test@example.com",
            username: "testuser",
            userType: .creator,
            createdAt: Date(),
            updatedAt: Date()
        )
        
        XCTAssertEqual(profile.id, "test-id")
        XCTAssertEqual(profile.email, "test@example.com")
        XCTAssertEqual(profile.username, "testuser")
        XCTAssertEqual(profile.userType, .creator)
    }
    
    func testDictionaryConversion() {
        let date = Date()
        let profile = UserProfile(
            id: "test-id",
            email: "test@example.com",
            username: "testuser",
            userType: .creator,
            createdAt: date,
            updatedAt: date
        )
        
        let dict = profile.asDictionary
        
        XCTAssertEqual(dict["id"] as? String, "test-id")
        XCTAssertEqual(dict["email"] as? String, "test@example.com")
        XCTAssertEqual(dict["username"] as? String, "testuser")
        XCTAssertEqual(dict["userType"] as? String, "creator")
    }
} 