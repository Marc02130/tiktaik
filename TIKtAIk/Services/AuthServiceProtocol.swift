//
// AuthServiceProtocol.swift
// TIKtAIk
//
// Created: 2024-02-14
// Last modified: 2024-02-14
//
// Purpose: Protocol defining authentication service requirements
// Author: Assistant
// Copyright © 2024 TIKtAIk. All rights reserved.
//

import FirebaseAuth

/// Protocol defining authentication service requirements
protocol AuthServiceProtocol {
    /// Whether a user is currently authenticated
    var isAuthenticated: Bool { get }
    /// Current authenticated user if any
    var currentUser: User? { get }
    
    /// Signs in a user with email and password
    /// - Parameters:
    ///   - email: User's email address
    ///   - password: User's password
    /// - Throws: AuthError if sign in fails
    func signIn(email: String, password: String) async throws
    
    /// Creates a new user account
    /// - Parameters:
    ///   - email: New user's email address
    ///   - password: New user's password
    /// - Throws: AuthError if account creation fails
    /// - Example:
    /// ```swift
    /// let auth = FirebaseAuthService.shared
    /// try await auth.createUser(email: "new@example.com", password: "password123")
    /// ```
    func createUser(email: String, password: String) async throws
    
    /// Signs out the current user
    /// - Throws: AuthError if sign out fails
    func signOut() async throws
    
    /// Sends password reset email to user
    /// - Parameter email: User's email address
    /// - Throws: AuthError if reset request fails
    func resetPassword(email: String) async throws
} 