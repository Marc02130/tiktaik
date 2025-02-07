//
// SignUpView.swift
// TIKtAIk
//
// Created: 2024-02-14
// Last modified: 2024-02-14
//
// Purpose: User registration view with form and validation
// Author: Assistant
// Copyright © 2024 TIKtAIk. All rights reserved.
//

// Framework: SwiftUI - UI Framework
import SwiftUI

/// View for new user registration
///
/// Provides a form for user registration with:
/// - Email/password fields
/// - Username input
/// - Profile type selection (Creator/Consumer)
/// - Terms acceptance
/// - Error handling
///
/// Example:
/// ```swift
/// NavigationStack {
///     SignUpView()
/// }
/// ```
struct SignUpView: View {
    /// View model handling registration logic
    @StateObject private var viewModel = SignUpViewModel()
    /// Environment dismiss action for navigation
    @Environment(\.dismiss) private var dismiss
    /// Currently focused form field
    @FocusState private var focusedField: Field?
    
    /// Enum defining focusable form fields
    private enum Field: Hashable {
        case email, username, password, confirmPassword
    }
    
    /// Main view body containing the registration form
    /// - Returns: A scrollable view with registration form elements
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Form container with input fields and controls
                VStack(spacing: 16) {
                    formFields
                    profileTypeSelection
                    termsSection
                    signUpButton
                }
                .padding(.horizontal, 24)
                .padding(.top, 24)
                .background(Color(.systemBackground))
                .accessibilityElement(children: .contain)
                .accessibilityIdentifier("signUpFormContainer")
                
                // Navigation back to login
                Button("Already have an account? Sign In") {
                    dismiss()
                }
                .padding(.vertical, 16)
                .accessibilityIdentifier("backToLoginButton")
            }
            .frame(maxWidth: .infinity)
            .padding(.bottom, 24)
        }
        .navigationBarTitleDisplayMode(.large)
        .navigationTitle("Create Account")
        .alert("Error", isPresented: $viewModel.showError) {
            Button("OK") {}
        } message: {
            Text(viewModel.errorMessage ?? "An error occurred")
        }
        .fullScreenCover(isPresented: $viewModel.isAuthenticated) {
            Text("Welcome to TIKtAIk!")
                .accessibilityIdentifier("welcomeText")
        }
    }
    
    /// Form fields section containing email, username, and password inputs
    /// - Returns: A view containing the registration form fields
    private var formFields: some View {
        VStack(spacing: 16) {
            TextField("Email", text: $viewModel.email)
                .textContentType(.emailAddress)
                .keyboardType(.emailAddress)
                .autocapitalization(.none)
                .focused($focusedField, equals: .email)
                .textFieldStyle(.customRounded)
                .accessibilityIdentifier("emailTextField")
            
            TextField("Username", text: $viewModel.username)
                .textContentType(.username)
                .autocapitalization(.none)
                .focused($focusedField, equals: .username)
                .textFieldStyle(.customRounded)
                .accessibilityIdentifier("usernameTextField")
            
            SecureField("Password", text: $viewModel.password)
                .textContentType(.newPassword)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .accessibilityIdentifier("passwordTextField")
                .onChange(of: viewModel.password) { oldValue, newValue in
                    Task { @MainActor in
                        viewModel.passwordDidChange()
                    }
                }
            
            SecureField("Confirm Password", text: $viewModel.confirmPassword)
                .textContentType(.newPassword)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .accessibilityIdentifier("confirmPasswordTextField")
                .onChange(of: viewModel.confirmPassword) { oldValue, newValue in
                    Task { @MainActor in
                        viewModel.passwordDidChange()
                    }
                }
        }
    }
    
    /// Profile type selection section with Creator/Consumer options
    /// - Returns: A view containing the profile type picker
    private var profileTypeSelection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("I want to...")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            Picker("Profile Type", selection: $viewModel.profileType) {
                ForEach(ProfileType.allCases, id: \.self) { type in
                    Text(type.rawValue)
                        .tag(type)
                        .accessibilityIdentifier("profileType\(type.rawValue)")
                }
            }
            .pickerStyle(.segmented)
            .accessibilityIdentifier("profileTypePicker")
            .accessibilityElement(children: .contain)
        }
        .accessibilityIdentifier("profileTypeContainer")
    }
    
    /// Terms and conditions acceptance section
    /// - Returns: A view containing the terms toggle and links
    private var termsSection: some View {
        Toggle(isOn: $viewModel.acceptedTerms) {
            HStack {
                Text("I accept the")
                Button("Terms") {
                    // TODO: Show terms
                }
                Text("and")
                Button("Privacy Policy") {
                    // TODO: Show privacy policy
                }
            }
            .font(.footnote)
        }
        .accessibilityIdentifier("termsToggle")
    }
    
    /// Sign up button that triggers registration
    /// - Returns: A button view that handles the sign up action
    private var signUpButton: some View {
        Button {
            Task {
                await viewModel.signUp()
            }
        } label: {
            if viewModel.isLoading {
                ProgressView()
                    .tint(.white)
            } else {
                Text("Create Account")
            }
        }
        .buttonStyle(.customPrimary)
        .disabled(!viewModel.acceptedTerms || viewModel.isLoading)
        .accessibilityIdentifier("signUpButton")
    }
}

#Preview {
    NavigationStack {
        SignUpView()
    }
} 