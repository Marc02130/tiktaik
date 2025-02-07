//
// FirebaseAuthService.swift
// TIKtAIk
//
// Created: 2024-02-14
// Last modified: 2024-02-14
//
// Purpose: Firebase authentication service implementation
// Author: Assistant
// Copyright © 2024 TIKtAIk. All rights reserved.
//

import FirebaseAuth

/// Firebase implementation of authentication service
final class FirebaseAuthService: AuthServiceProtocol {
    /// Shared instance
    static let shared = FirebaseAuthService()
    
    private init() {}
    
    var isAuthenticated: Bool {
        Auth.auth().currentUser != nil
    }
    
    var currentUser: User? {
        Auth.auth().currentUser
    }
    
    /// Signs in a user with email and password
    /// - Parameters:
    ///   - email: User's email address
    ///   - password: User's password
    /// - Throws: AuthError if sign in fails
    func signIn(email: String, password: String) async throws {
        try await Auth.auth().signIn(withEmail: email, password: password)
    }
    
    /// Creates a new user account
    /// - Parameters:
    ///   - email: New user's email address
    ///   - password: New user's password
    /// - Throws: AuthError if account creation fails
    func createUser(email: String, password: String) async throws {
        try await Auth.auth().createUser(withEmail: email, password: password)
    }
    
    /// Signs out the current user
    /// - Throws: AuthError if sign out fails
    func signOut() async throws {
        try Auth.auth().signOut()
    }
    
    /// Sends password reset email to user
    /// - Parameter email: User's email address
    /// - Throws: AuthError if reset request fails
    func resetPassword(email: String) async throws {
        try await Auth.auth().sendPasswordReset(withEmail: email)
    }
} 