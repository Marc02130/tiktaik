//
// PasswordResetView.swift
// TIKtAIk
//
// Created: 2024-02-14
// Last modified: 2024-02-14
//
// Purpose: View for handling password reset requests
// Author: Assistant
// Copyright © 2024 TIKtAIk. All rights reserved.
//

import SwiftUI

/// View for handling password reset requests
struct PasswordResetView: View {
    /// Environment dismiss action
    @Environment(\.dismiss) private var dismiss
    /// Authentication view model
    @EnvironmentObject private var authViewModel: AuthViewModel
    /// Email input field
    @State private var email = ""
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Text("Enter your email address to receive a password reset link.")
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
                
                TextField("Email", text: $email)
                    .textContentType(.emailAddress)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                    .textFieldStyle(.customRounded)
                    .accessibilityIdentifier("resetEmailTextField")
                
                Button {
                    Task {
                        await authViewModel.resetPassword(email: email)
                        dismiss()
                    }
                } label: {
                    if authViewModel.isLoading {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Text("Send Reset Link")
                    }
                }
                .buttonStyle(.customPrimary)
                .disabled(authViewModel.isLoading || email.isEmpty)
                .accessibilityIdentifier("sendResetButton")
            }
            .padding(24)
            .navigationTitle("Reset Password")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    PasswordResetView()
        .environmentObject(AuthViewModel())
} 