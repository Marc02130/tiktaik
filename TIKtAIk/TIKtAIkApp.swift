//
// TIKtAIkApp.swift
// TIKtAIk
//
// Created: 2024-02-14
// Last modified: 2024-02-14
//
// Purpose: Main app entry point and configuration
// Author: Assistant
// Copyright © 2024 TIKtAIk. All rights reserved.
//

import SwiftUI
import FirebaseCore
import FirebaseFirestore
import FirebaseAnalytics
import FirebasePerformance

/// Main app entry point
@main
struct TIKtAIkApp: App {
    /// Authentication view model
    @StateObject private var authViewModel = AuthViewModel()
    
    /// Initializes Firebase on app launch
    init() {
        setupFirebase()
    }
    
    /// App scene configuration
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authViewModel)
        }
    }
    
    private func setupFirebase() {
        FirebaseApp.configure()
        
        // Setup Firebase Analytics
        Analytics.setAnalyticsCollectionEnabled(true)
        
        // Setup Firebase Performance
        Performance.sharedInstance().isInstrumentationEnabled = true
        Performance.sharedInstance().isDataCollectionEnabled = true
    }
}

#Preview {
    ContentView()
        .environmentObject(AuthViewModel())
} 