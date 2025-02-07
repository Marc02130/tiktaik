//
// LoginViewModel.swift
// TIKtAIk
//
// Created: 2024-02-14
// Last modified: 2024-02-14
//
// Author: Assistant
// Copyright © 2024 TIKtAIk. All rights reserved.
//

import SwiftUI
import FirebaseAuth
import Combine

@MainActor
final class LoginViewModel: ObservableObject {
    @Published var email = ""
    @Published var password = ""
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showError = false
    
    var isSignInEnabled: Bool {
        !email.isEmpty && !password.isEmpty && !isLoading
    }
    
    func signIn() async {
        isLoading = true
        errorMessage = nil
        
        do {
            try await Auth.auth().signIn(withEmail: email, password: password)
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
        
        isLoading = false
    }
    
    func sendPasswordReset() async {
        guard !email.isEmpty else {
            errorMessage = "Please enter your email address"
            showError = true
            return
        }
        
        isLoading = true
        
        do {
            try await Auth.auth().sendPasswordReset(withEmail: email)
            errorMessage = "Password reset email sent"
            showError = true
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
        
        isLoading = false
    }
} 