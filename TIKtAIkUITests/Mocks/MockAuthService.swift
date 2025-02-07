//
// MockAuthService.swift
// TIKtAIk
//
// Created: 2024-02-14
// Last modified: 2024-02-14
//
// Purpose: Mock auth service for testing
// Author: Assistant
// Copyright © 2024 TIKtAIk. All rights reserved.
//

import Foundation

/// Mock implementation of AuthServiceProtocol for testing
final class MockAuthService: AuthServiceProtocol {
    /// Shared instance for testing
    static let shared = MockAuthService()
    
    /// Simulated authentication state
    private(set) var isAuthenticated = false
    
    /// Mock current user
    private(set) var currentUser: MockUser?
    
    /// Whether mock should throw errors
    var shouldThrowError = false
    
    private init() {}
    
    /// Simulates sign in with optional error
    func signIn(email: String, password: String) async throws {
        if shouldThrowError {
            isAuthenticated = false
            currentUser = nil
            throw MockAuthError.invalidCredentials
        }
        isAuthenticated = true
        currentUser = MockUser(id: "mock-user-id", email: email)
    }
    
    /// Simulates user creation with optional error
    func createUser(email: String, password: String) async throws {
        if shouldThrowError {
            throw MockAuthError.accountCreationFailed
        }
        isAuthenticated = true
        currentUser = MockUser(id: "mock-user-id", email: email)
    }
    
    /// Simulates sign out
    func signOut() async throws {
        if shouldThrowError {
            throw MockAuthError.signOutFailed
        }
        isAuthenticated = false
        currentUser = nil
    }
    
    /// Simulates password reset with optional error
    func resetPassword(email: String) async throws {
        if shouldThrowError {
            throw MockAuthError.passwordResetFailed
        }
    }
}

/// Mock user for testing
struct MockUser {
    let id: String
    let email: String
}

/// Mock auth errors
enum MockAuthError: LocalizedError {
    case invalidCredentials
    case accountCreationFailed
    case signOutFailed
    case passwordResetFailed
    
    var errorDescription: String? {
        switch self {
        case .invalidCredentials: return "Invalid credentials"
        case .accountCreationFailed: return "Account creation failed"
        case .signOutFailed: return "Sign out failed"
        case .passwordResetFailed: return "Password reset failed"
        }
    }
} 