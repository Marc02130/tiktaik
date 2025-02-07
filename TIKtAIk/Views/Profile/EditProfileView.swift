//
// EditProfileView.swift
// TIKtAIk
//
// Created: 2024-02-14
// Last modified: 2024-02-14
//
// Purpose: View for editing user profile information
// Author: Assistant
// Copyright © 2024 TIKtAIk. All rights reserved.
//

// Framework: SwiftUI - UI Framework
import SwiftUI
// Framework: FirebaseFirestore - Cloud Database
import FirebaseFirestore

/// View for editing user profile information
///
/// Allows users to:
/// - Update username
/// - Edit bio
/// - Save or cancel changes
struct EditProfileView: View {
    /// Current user profile
    let profile: UserProfile
    /// Environment dismiss action
    @Environment(\.dismiss) private var dismiss
    /// Auth view model for profile updates
    @EnvironmentObject private var authViewModel: AuthViewModel
    @StateObject private var viewModel: EditProfileViewModel
    
    init(profile: UserProfile) {
        self.profile = profile
        _viewModel = StateObject(wrappedValue: EditProfileViewModel(profile: profile))
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("Profile Information") {
                    TextField("Username", text: $viewModel.username)
                    TextField("Bio", text: $viewModel.bio)
                    Picker("Account Type", selection: $viewModel.userType) {
                        ForEach(UserProfile.UserType.allCases, id: \.self) { type in
                            Text(type.rawValue.capitalized)
                                .tag(type)
                        }
                    }
                }
                
                Section("Privacy & Settings") {
                    Toggle("Private Account", isOn: $viewModel.isPrivate)
                    Toggle("Enable Notifications", isOn: $viewModel.notificationsEnabled)
                    Toggle("Allow Comments", isOn: $viewModel.allowComments)
                }
                
                Section("Feed Preferences") {
                    Toggle("Creator Mode", isOn: $viewModel.isCreator)
                        .onChange(of: viewModel.isCreator) { oldValue, newValue in
                            Task {
                                await viewModel.updateCreatorStatus(isCreator: newValue)
                            }
                        }
                }
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        Task {
                            await viewModel.saveChanges(authViewModel)
                            dismiss()
                        }
                    }
                    .disabled(viewModel.isSaving)
                }
            }
        }
    }
}

@MainActor
final class EditProfileViewModel: ObservableObject {
    @Published var username: String
    @Published var bio: String
    @Published var userType: UserProfile.UserType
    @Published var isPrivate: Bool
    @Published var notificationsEnabled: Bool
    @Published var allowComments: Bool
    @Published private(set) var isSaving = false
    @Published var isCreator: Bool
    
    private let profile: UserProfile
    
    init(profile: UserProfile) {
        self.profile = profile
        self.username = profile.username
        self.bio = profile.bio ?? ""
        self.userType = profile.userType
        self.isPrivate = profile.settings.isPrivate
        self.notificationsEnabled = profile.settings.notificationsEnabled
        self.allowComments = profile.settings.allowComments
        self.isCreator = profile.isCreator
    }
    
    @MainActor
    func saveChanges(_ authViewModel: AuthViewModel) async {
        isSaving = true
        defer { isSaving = false }
        
        let updatedProfile = UserProfile(
            id: profile.id,
            email: profile.email,
            username: username,
            userType: userType,
            bio: bio.isEmpty ? nil : bio,
            avatarUrl: profile.avatarUrl,
            stats: profile.stats,
            settings: UserProfile.UserSettings(
                isPrivate: isPrivate,
                notificationsEnabled: notificationsEnabled,
                allowComments: allowComments
            ),
            createdAt: profile.createdAt,
            updatedAt: Date(),
            interests: profile.interests,
            isCreator: isCreator
        )
        
        do {
            try await Firestore.firestore()
                .collection(UserProfile.collectionName)
                .document(profile.id)
                .setData(updatedProfile.asDictionary)
                
            // After successful save, reload the profile
            await authViewModel.loadUserProfile()
        } catch {
            print("Failed to save profile:", error)
        }
    }
    
    func updateCreatorStatus(isCreator: Bool) async {
        // Implementation of updateCreatorStatus function
    }
}

#Preview {
    NavigationView {
        EditProfileView(profile: UserProfile(
            id: "preview-id",
            email: "test@example.com",
            username: "TestUser",
            userType: .consumer,
            bio: "Test bio",
            avatarUrl: nil,
            stats: UserProfile.UserStats(
                followersCount: 0,
                followingCount: 0,
                videosCount: 0
            ),
            settings: UserProfile.UserSettings(
                isPrivate: false,
                notificationsEnabled: true,
                allowComments: true
            ),
            createdAt: Date(),
            updatedAt: Date(),
            interests: ["coding", "swiftui", "ios"],  // Add sample interests
            isCreator: false  // Add isCreator parameter
        ))
        .environmentObject(AuthViewModel())
    }
} 