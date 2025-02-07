//
// AuthViewModel.swift
// TIKtAIk
//
// Created: 2024-02-14
// Last modified: 2024-02-14
//
// Purpose: View model for handling authentication state and operations
// Author: Assistant
// Copyright © 2024 TIKtAIk. All rights reserved.
//

// Framework: SwiftUI - UI Framework
import SwiftUI
// Framework: FirebaseAuth - Authentication
import FirebaseAuth
// Framework: Combine - Reactive Programming
import Combine
// Framework: FirebaseFirestore - Cloud Firestore
import FirebaseFirestore

/// View model managing authentication state and operations
///
/// Handles user authentication flows including:
/// - Sign in/out
/// - Error presentation
/// - Authentication state monitoring
@MainActor
final class AuthViewModel: ObservableObject {
    /// Current authentication state
    @Published private(set) var isAuthenticated = false
    /// Loading state for async operations
    @Published private(set) var isLoading = true
    /// Email input field
    @Published var email = ""
    /// Password input field
    @Published var password = ""
    /// Current error message if any
    @Published private(set) var errorMessage: String?
    /// Whether to show error alert
    @Published private(set) var showError = false
    /// Current user profile
    @Published private(set) var userProfile: UserProfile?
    
    /// Whether to show edit profile sheet
    @Published var showEditProfile = false
    
    private var authStateHandler: AuthStateDidChangeListenerHandle?
    private let authService: AuthServiceProtocol
    
    /// Initializes the view model with an auth service
    /// - Parameter authService: Service handling auth operations
    init(authService: AuthServiceProtocol = FirebaseAuthService.shared) {
        self.authService = authService
        checkAuthState()
        setupAuthStateListener()
    }
    
    /// Sets up Firebase auth state listener
    private func setupAuthStateListener() {
        authStateHandler = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            Task { @MainActor in
                self?.isAuthenticated = user != nil
            }
        }
    }
    
    /// Signs in a user with email and password
    /// - Parameters:
    ///   - email: User's email
    ///   - password: User's password
    @MainActor
    func signIn(email: String, password: String) async {
        guard !isLoading else { return }
        
        isLoading = true
        errorMessage = nil
        showError = false
        
        do {
            try await authService.signIn(email: email, password: password)
            isAuthenticated = authService.isAuthenticated
        } catch {
            errorMessage = error.localizedDescription
            showError = true
            isAuthenticated = false
        }
        
        isLoading = false
    }
    
    /// Creates a new user account
    func createUser(email: String, password: String) async {
        guard !isLoading else { return }
        
        isLoading = true
        errorMessage = nil
        showError = false
        
        do {
            // 1. Create auth user
            try await authService.createUser(email: email, password: password)
            isAuthenticated = authService.isAuthenticated
            
            // 2. Get the new user's ID
            guard let userId = authService.currentUser?.uid else {
                throw NSError(domain: "AuthViewModel", code: -1, 
                            userInfo: [NSLocalizedDescriptionKey: "Failed to get user ID"])
            }
            
            // 3. Create and save user profile to Firestore
            try await createUserProfile(userId: userId, email: email)
            
        } catch {
            print("DEBUG: Error creating user: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
            showError = true
        }
        
        isLoading = false
    }
    
    /// Creates user profile in Firestore
    /// - Parameters:
    ///   - userId: Firebase user ID
    ///   - email: User's email address
    func createUserProfile(userId: String, email: String) async throws {
        let newProfile = UserProfile(
            id: userId,
            email: email,
            username: email.components(separatedBy: "@").first ?? "user",
            userType: .consumer,
            bio: nil,
            avatarUrl: nil,
            stats: UserProfile.UserStats(),
            settings: UserProfile.UserSettings(),
            createdAt: Date(),
            updatedAt: Date(),
            interests: []  // Add empty interests array
        )
        
        try await Firestore.firestore()
            .collection(UserProfile.collectionName)
            .document(userId)
            .setData(newProfile.asDictionary)
        
        self.userProfile = newProfile
    }
    
    /// Signs out the current user and updates auth state
    @MainActor
    func signOut() {
        do {
            try Auth.auth().signOut()
            self.userProfile = nil
            self.isAuthenticated = false
        } catch {
            self.errorMessage = error.localizedDescription
        }
    }
    
    /// Resets the user's password
    /// - Parameter email: User's email
    @MainActor
    func resetPassword(email: String) async {
        guard !isLoading else { return }
        
        isLoading = true
        errorMessage = nil
        showError = false
        
        do {
            try await authService.resetPassword(email: email)
            errorMessage = "Password reset email sent"
            showError = true
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
        
        isLoading = false
    }
    
    /// Cleans up resources when view model is deallocated
    deinit {
        if let handler = authStateHandler {
            Auth.auth().removeStateDidChangeListener(handler)
        }
    }
    
    /// Current Firebase user
    private var firebaseUser: User? {
        Auth.auth().currentUser
    }
    
    /// Updates an existing user profile
    /// - Parameter profile: Updated profile data
    func updateProfile(_ profile: UserProfile) async {
        do {
            var updatedProfile = profile
            updatedProfile.updatedAt = Date() // Update timestamp
            
            try await Firestore.firestore()
                .collection(UserProfile.collectionName)
                .document(profile.id)
                .setData(updatedProfile.asDictionary)
            
            self.userProfile = updatedProfile
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }
    
    @MainActor
    func checkAuthState() {
        isLoading = true
        defer { isLoading = false }
        
        if Auth.auth().currentUser != nil {
            self.isAuthenticated = true
            // Load user profile if needed
            Task {
                await loadUserProfile()
            }
        } else {
            self.isAuthenticated = false
            self.userProfile = nil
        }
    }
    
    /// Updates user interests
    /// - Parameter interests: New interests array
    func updateInterests(_ interests: [String]) async {
        guard var updatedProfile = userProfile else { return }
        updatedProfile.interests = Set(interests)
        await updateProfile(updatedProfile)
    }
    
    // Make loadUserProfile public
    func loadUserProfile() async {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        do {
            let snapshot = try await Firestore.firestore()
                .collection(UserProfile.collectionName)
                .document(userId)
                .getDocument()
            
            if snapshot.exists {
                self.userProfile = try UserProfile.from(snapshot)
            }
        } catch {
            print("Failed to load user profile:", error)
            errorMessage = "Failed to load user profile"
            showError = true
        }
    }
}

// Define notification name as a static extension
extension NSNotification.Name {
    /// Notification posted when auth state changes
    static let authStateDidChange = NSNotification.Name("authStateDidChange")
} 