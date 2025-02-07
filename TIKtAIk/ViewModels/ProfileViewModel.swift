import SwiftUI
import FirebaseAuth
import FirebaseFirestore

/// View model managing profile data and operations
@MainActor
final class ProfileViewModel: ObservableObject {
    /// Current user profile data
    @Published private(set) var userProfile: UserProfile?
    /// Loading state indicator
    @Published private(set) var isLoading = false
    /// Current error if any
    @Published private(set) var error: Error?
    @Published var showEditProfile = false
    @Published var showError = false
    
    /// Loads user profile from Firestore
    func loadProfile() async {
        guard let userId = Auth.auth().currentUser?.uid else {
            print("DEBUG: No authenticated user found")
            return 
        }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            let snapshot = try await Firestore.firestore()
                .collection(UserProfile.collectionName)
                .document(userId)
                .getDocument()
            
            if snapshot.exists {
                userProfile = try UserProfile.from(snapshot)
            }
        } catch {
            self.error = error
            self.showError = true
        }
    }
    
    /// Updates user profile in Firestore
    func updateProfile(_ profile: UserProfile) async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            try await Firestore.firestore()
                .collection(UserProfile.collectionName)
                .document(profile.id)
                .setData(profile.asDictionary)
            
            self.userProfile = profile
        } catch {
            self.error = error
            self.showError = true
        }
    }
    
    /// Updates user interests/tags
    /// - Parameter interests: New interests/tags
    func updateInterests(_ interests: Set<String>) async {
        guard let profile = userProfile else { return }
        isLoading = true
        defer { isLoading = false }
        
        let updatedProfile = UserProfile(
            id: profile.id,
            email: profile.email,
            username: profile.username,
            userType: profile.userType,
            bio: profile.bio,
            avatarUrl: profile.avatarUrl,
            stats: profile.stats,
            settings: profile.settings,
            createdAt: profile.createdAt,
            updatedAt: Date(),
            interests: Array(interests), // Convert Set to Array for storage
            isCreator: profile.isCreator // Keep existing creator status
        )
        
        await updateProfile(updatedProfile)
    }
} 