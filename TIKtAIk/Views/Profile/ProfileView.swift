//
// ProfileView.swift
// TIKtAIk
//
// Created: 2024-02-14
// Last modified: 2024-02-14
//
// Purpose: View for displaying and managing user profile
// Author: Assistant
// Copyright © 2024 TIKtAIk. All rights reserved.
//

// Framework: SwiftUI - UI Framework
import SwiftUI
// Framework: FirebaseAuth - Authentication
import FirebaseAuth
// Framework: FirebaseFirestore - Cloud Database
import FirebaseFirestore

/// View for displaying and managing user profile settings
///
/// Displays:
/// - Profile information
/// - Account settings
/// - App preferences
/// - Sign out option
struct ProfileView: View {
    @EnvironmentObject private var authViewModel: AuthViewModel
    @State private var showingTagEditor = false
    
    var body: some View {
        Group {
            if let profile = authViewModel.userProfile {
                profileContent(profile)
            } else {
                ProgressView("Loading profile...")
            }
        }
        .task {
            if authViewModel.userProfile == nil {
                await authViewModel.loadUserProfile()
            }
        }
    }
    
    private func profileContent(_ profile: UserProfile) -> some View {
        VStack(spacing: 20) {
            // Profile Info
            VStack(spacing: 12) {
                // Avatar
                if let avatarUrl = profile.avatarUrl {
                    AsyncImage(url: URL(string: avatarUrl)) { image in
                        image
                            .resizable()
                            .scaledToFill()
                    } placeholder: {
                        Image(systemName: "person.circle.fill")
                    }
                    .frame(width: 80, height: 80)
                    .clipShape(Circle())
                } else {
                    Image(systemName: "person.circle.fill")
                        .resizable()
                        .frame(width: 80, height: 80)
                        .foregroundColor(.gray)
                }
                
                // Username, Email and Edit Button
                HStack {
                    VStack(alignment: .leading) {
                        Text(profile.username)
                            .font(.title2)
                            .bold()
                        Text(profile.email)
                            .foregroundColor(.gray)
                    }
                    
                    Spacer()
                    
                    Button {
                        authViewModel.showEditProfile = true
                    } label: {
                        Image(systemName: "pencil.circle.fill")
                            .font(.title2)
                            .foregroundColor(.blue)
                    }
                }
                .padding(.horizontal)
                
                // Bio
                if let bio = profile.bio {
                    Text(bio)
                        .foregroundColor(.secondary)
                        .font(.subheadline)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                
                // Stats
                HStack(spacing: 30) {
                    VStack {
                        Text("\(profile.stats.videosCount)")
                            .font(.headline)
                        Text("Videos")
                            .foregroundColor(.gray)
                    }
                    VStack {
                        Text("\(profile.stats.followersCount)")
                            .font(.headline)
                        Text("Followers")
                            .foregroundColor(.gray)
                    }
                    VStack {
                        Text("\(profile.stats.followingCount)")
                            .font(.headline)
                        Text("Following")
                            .foregroundColor(.gray)
                    }
                }
                .padding(.top, 8)
            }
            .padding()
            
            // Interests Section
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Interests")
                        .font(.headline)
                    Spacer()
                    Button("Edit") {
                        showingTagEditor = true
                    }
                }
                
                if profile.interests.isEmpty {
                    Text("Add interests to personalize your feed")
                        .foregroundStyle(.secondary)
                } else {
                    FlowLayout(spacing: 8) {
                        ForEach(Array(profile.interests), id: \.self) { tag in
                            Text(tag)
                                .font(.subheadline)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color(.systemGray6))
                                .clipShape(Capsule())
                        }
                    }
                }
            }
            .padding()
            .background(Color(.systemGray6).opacity(0.5))
            .cornerRadius(12)
            
            Spacer()
            
            // Sign Out Button
            Button(role: .destructive) {
                authViewModel.signOut()
            } label: {
                Text("Sign Out")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.red)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .padding(.horizontal)
            .accessibilityIdentifier("signOutButton")
        }
        .sheet(isPresented: $authViewModel.showEditProfile) {
            EditProfileView(profile: profile)
        }
        .sheet(isPresented: $showingTagEditor) {
            TagSelectionView(selectedTags: .init(
                get: { Set(profile.interests) },
                set: { newTags in
                    Task {
                        await authViewModel.updateInterests(newTags)
                    }
                }
            ))
        }
    }
}

#Preview {
    ProfileView()
        .environmentObject(AuthViewModel(authService: FirebaseAuthService.shared))
} 