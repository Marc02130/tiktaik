//
// SignUpViewModel.swift
// TIKtAIk
//
// Created: 2024-02-14
// Last modified: 2024-02-14
//
// Purpose: View model for handling user registration
// Author: Assistant
// Copyright © 2024 TIKtAIk. All rights reserved.
//

// Framework: SwiftUI - UI Framework
import SwiftUI
// Framework: FirebaseAuth - Authentication
import FirebaseAuth
// Framework: Combine - Reactive Programming
import Combine

/// Profile type selection for new users
enum ProfileType: String, CaseIterable {
    case creator = "Creator"
    case consumer = "Consumer"
}

/// View model managing user registration flow
///
/// Handles:
/// - Email/password validation
/// - Profile type selection
/// - Terms acceptance
/// - Registration with Firebase
/// - Error handling
/// - Navigation state
@MainActor
final class SignUpViewModel: ObservableObject {
    /// Email input field
    @Published var email = ""
    /// Password input field
    @Published var password = ""
    /// Password confirmation field
    @Published var confirmPassword = ""
    /// Username field
    @Published var username = ""
    /// Selected profile type
    @Published var profileType = ProfileType.consumer
    /// Terms acceptance state
    @Published var acceptedTerms = false
    /// Loading state for async operations
    @Published var isLoading = false
    /// Error message if registration fails
    @Published var errorMessage: String?
    /// Whether to show error alert
    @Published var showError = false
    /// Current authentication state
    @Published var isAuthenticated = false
    
    /// Password validation state
    @Published private(set) var passwordValidation = PasswordValidation() {
        willSet {
            if isUITesting {
                print("\nPassword Validation Will Update:")
                print("- Current length valid:", passwordValidation.isLengthValid)
                print("- Current passwords match:", passwordValidation.passwordsMatch)
                print("- New length valid:", newValue.isLengthValid)
                print("- New passwords match:", newValue.passwordsMatch)
            }
        }
    }
    /// Debug mode for UI tests
    private let isUITesting: Bool
    
    private let authService: AuthServiceProtocol
    
    /// Initializes view model with auth service
    /// - Parameter authService: Service handling auth operations
    /// - Parameter isUITesting: Whether running in UI test mode
    init(authService: AuthServiceProtocol = FirebaseAuthService.shared,
         isUITesting: Bool = ProcessInfo.processInfo.arguments.contains("-ui_testing")) {
        self.authService = authService
        self.isUITesting = isUITesting
    }
    
    /// Updates password validation state when text changes
    func passwordDidChange() {
        if isUITesting {
            print("\nPassword Changed:")
            print("- Password text:", String(repeating: "•", count: password.count))
            print("- Password length:", password.count)
            print("- Confirm text:", String(repeating: "•", count: confirmPassword.count))
            print("- Confirm length:", confirmPassword.count)
        }
        
        // Ensure we're on the main thread for UI updates
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            // Update validation immediately
            let newValidation = PasswordValidation(
                isLengthValid: !self.password.isEmpty && self.password.count >= 8,
                passwordsMatch: !self.confirmPassword.isEmpty && self.password == self.confirmPassword
            )
            
            if self.isUITesting {
                print("Validation Updated:")
                print("- Length valid:", newValidation.isLengthValid)
                print("- Passwords match:", newValidation.passwordsMatch)
                print("- Overall valid:", newValidation.isValid)
            }
            
            self.passwordValidation = newValidation
        }
    }
    
    /// Validates form input and shows appropriate error messages
    /// - Returns: True if all fields are valid, false otherwise
    /// - Example:
    /// ```swift
    /// let viewModel = SignUpViewModel()
    /// viewModel.email = "test@example.com"
    /// viewModel.password = "password123"
    /// viewModel.confirmPassword = "password123"
    /// viewModel.username = "testuser"
    /// viewModel.acceptedTerms = true
    /// let isValid = viewModel.validateInput() // Returns true
    /// ```
    func validateInput() -> Bool {
        if isUITesting {
            print("\nValidating Form:")
            print("- Email:", email)
            print("- Username:", username)
            print("- Password length:", password.count)
            print("- Confirm length:", confirmPassword.count)
            print("- Current validation:", passwordValidation)
        }
        
        // Email validation
        guard !email.isEmpty, email.contains("@") else {
            errorMessage = "Please enter a valid email"
            showError = true
            return false
        }
        
        // Username validation
        guard !username.isEmpty, username.count >= 3 else {
            errorMessage = "Username must be at least 3 characters"
            showError = true
            return false
        }
        
        // Password validation - check actual length first
        guard password.count >= 8 else {
            errorMessage = "Password must be at least 8 characters"
            showError = true
            return false
        }
        
        // Password match validation
        guard password == confirmPassword else {
            errorMessage = "Passwords don't match"
            showError = true
            return false
        }
        
        // Terms acceptance
        guard acceptedTerms else {
            errorMessage = "Please accept the terms and conditions"
            showError = true
            return false
        }
        
        if isUITesting {
            print("\nValidation Passed:")
            print("- All checks successful")
        }
        
        return true
    }
    
    /// Attempts to register a new user with the provided credentials
    /// - Throws: AuthError if registration fails
    /// - Example:
    /// ```swift
    /// let viewModel = SignUpViewModel()
    /// // Set up user data...
    /// await viewModel.signUp()
    /// // Check viewModel.isAuthenticated for success
    /// ```
    func signUp() async {
        guard validateInput() else { return }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            try await authService.createUser(email: email, password: password)
            
            // Important: Update state on main actor
            await MainActor.run {
                self.isAuthenticated = true
            }
            
            // TODO: Save additional user data (username, profile type) to Firestore
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                self.showError = true
            }
        }
    }
}

struct PasswordValidation {
    var isLengthValid = false
    var passwordsMatch = false
    var isValid: Bool { isLengthValid && passwordsMatch }
} 