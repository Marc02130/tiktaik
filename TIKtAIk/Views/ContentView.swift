//
// ContentView.swift
// TIKtAIk
//
// Created: 2024-02-14
// Last modified: 2024-02-14
//
// Purpose: Root view handling authentication state and main navigation
// Author: Assistant
// Copyright © 2024 TIKtAIk. All rights reserved.
//

import SwiftUI
import FirebaseAuth

/// Root view managing authentication state and main navigation
struct ContentView: View {
    /// Authentication view model
    @EnvironmentObject private var authViewModel: AuthViewModel
    /// Router for navigation
    @State private var router = Router()
    
    var body: some View {
        Group {
            if authViewModel.isLoading {
                ProgressView("Loading...")
            } else if authViewModel.isAuthenticated {
                MainTabView(router: $router)
            } else {
                LoginView()
            }
        }
        .task {
            if authViewModel.userProfile == nil {
                await authViewModel.loadUserProfile()
            }
        }
    }
    
    /// Validates the current authentication state
    @MainActor
    private func validateAuthState() async {
        // Check if we have a cached user
        if Auth.auth().currentUser != nil {
            do {
                // Attempt to refresh token
                try await Auth.auth().currentUser?.reload()
                // Update auth state
                authViewModel.checkAuthState()
            } catch {
                print("Auth validation failed:", error.localizedDescription)
                authViewModel.signOut()
            }
        } else {
            // No cached user, ensure signed out state
            authViewModel.signOut()
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AuthViewModel())
} 