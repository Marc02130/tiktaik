//
// MainTabView.swift
// TIKtAIk
//
// Created: 2024-02-14
// Last modified: 2024-02-14
//
// Purpose: Main tab navigation view for authenticated users
// Author: Assistant
// Copyright © 2024 TIKtAIk. All rights reserved.
//

import SwiftUI

/// Main tab navigation view for authenticated users
///
/// Provides navigation between main app sections:
/// - Feed
/// - Library
/// - Upload
/// - Profile
struct MainTabView: View {
    /// Authentication view model
    @EnvironmentObject private var authViewModel: AuthViewModel
    /// Router for navigation
    @Binding var router: Router
    /// Selected tab index
    @State private var selectedTab = 0
    @State private var refreshTrigger = RefreshTrigger()  // Add only this for VideoEditView
    
    var body: some View {
        // Add debug print to check if view is being rendered
        #if DEBUG
        let _ = print("MainTabView body called, selectedTab:", selectedTab)
        #endif
        
        TabView(selection: $selectedTab) {
            // Home feed tab
            NavigationStack(path: $router.homePath) {
                FeedView()
                    .toolbar(.hidden) // Hide navigation bar
            }
            .tabItem {
                Label("Home", systemImage: "house.fill")
            }
            .tag(0)
            
            // Video Library
            NavigationStack(path: $router.libraryPath) {
                VideoLibraryView(
                    viewModel: VideoLibraryViewModel(),  // Create here since it's needed per instance
                    refreshTrigger: refreshTrigger
                )
            }
            .tabItem {
                Label("Library", systemImage: "photo.stack")
            }
            .tag(1)
            
            // Upload tab - Direct navigation to VideoUploadView
            NavigationStack {
                VideoUploadView(refreshTrigger: refreshTrigger)
            }
            .tabItem {
                Label("Upload", systemImage: "plus.circle.fill")
            }
            .tag(2)
            
            // Profile tab
            NavigationStack(path: $router.profilePath) {
                ProfileView()
            }
            .tabItem {
                Label("Profile", systemImage: "person.fill")
            }
            .tag(3)
        }
        .onAppear {
            #if DEBUG
            print("MainTabView appeared")
            #endif
        }
        .task {
            // Load initial data
            if authViewModel.userProfile == nil {
                await authViewModel.loadUserProfile()
            }
        }
    }
}

#Preview {
    MainTabView(router: .constant(Router()))
        .environmentObject(AuthViewModel())
} 