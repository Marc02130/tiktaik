//
// LoginView.swift
// TIKtAIk
//
// Created: 2024-02-14
// Last modified: 2024-02-14
//
// Purpose: Login view with email/password authentication
// Author: Assistant
// Copyright © 2024 TIKtAIk. All rights reserved.
//

import SwiftUI
import UIKit

/// Login view with email/password authentication
struct LoginView: View {
    /// Authentication view model
    @EnvironmentObject private var authViewModel: AuthViewModel
    /// Currently focused form field
    @FocusState private var focusedField: Field?
    /// Whether to show password reset sheet
    @State private var showingPasswordReset = false
    
    /// Enum defining focusable form fields
    private enum Field: Hashable {
        case email, password
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Form fields container
                VStack(spacing: 16) {
                    formFields
                    forgotPasswordButton
                    signInButton
                }
                .padding(.horizontal, 24)
                .padding(.top, 24)
                
                // Create account navigation
                NavigationLink("Create Account") {
                    SignUpView()
                }
                .padding(.vertical, 16)
                .accessibilityIdentifier("createAccountButton")
            }
            .frame(maxWidth: .infinity)
            .background(Color(.systemBackground))
            .navigationTitle("Sign In")
            .navigationBarTitleDisplayMode(.large)
            .alert("Error", isPresented: .constant(authViewModel.showError)) {
                Button("OK") {
                    // Error is cleared in view model
                }
            } message: {
                Text(authViewModel.errorMessage ?? "An error occurred")
            }
        }
        .onAppear {
            // Debug view hierarchy
            print("\n=== View Hierarchy Structure ===")
            debugPrint(self)
            
            // Debug accessibility
            print("\n=== Accessibility Check ===")
            print("Is accessibility enabled:", UIAccessibility.isVoiceOverRunning)
            print("Is testing enabled:", ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil)
        }
    }
    
    /// Form fields for email and password
    private var formFields: some View {
        VStack(spacing: 16) {
            TextField("Email", text: $authViewModel.email)
                .textContentType(.emailAddress)
                .keyboardType(.emailAddress)
                .autocapitalization(.none)
                .focused($focusedField, equals: .email)
                .textFieldStyle(.customRounded)
                .accessibilityIdentifier("emailField")
            
            SecureField("Password", text: $authViewModel.password)
                .textContentType(.password)
                .focused($focusedField, equals: .password)
                .textFieldStyle(.customRounded)
                .accessibilityIdentifier("passwordField")
        }
    }
    
    /// Forgot password button
    private var forgotPasswordButton: some View {
        Button("Forgot Password?") {
            showingPasswordReset = true
        }
        .accessibilityIdentifier("forgotPasswordButton")
        .sheet(isPresented: $showingPasswordReset) {
            PasswordResetView()
        }
    }
    
    /// Sign in button
    private var signInButton: some View {
        Button {
            Task {
                await authViewModel.signIn(
                    email: authViewModel.email,
                    password: authViewModel.password
                )
            }
        } label: {
            if authViewModel.isLoading {
                ProgressView()
                    .tint(.white)
            } else {
                Text("Sign In")
            }
        }
        .buttonStyle(.customPrimary)
        .disabled(authViewModel.isLoading)
        .accessibilityIdentifier("signInButton")
    }
}

#Preview {
    LoginView()
        .environmentObject(AuthViewModel())
} 