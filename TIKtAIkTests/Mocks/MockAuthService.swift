import Foundation
import FirebaseAuth

/// Mock implementation of AuthServiceProtocol for testing
final class MockAuthService: AuthServiceProtocol {
    /// Shared instance
    static let shared = MockAuthService()
    
    /// Mock authentication state
    private(set) var isAuthenticated = false
    
    /// Mock current user
    private(set) var currentUser: User?
    
    /// Whether mock should throw errors
    var shouldThrowError = false
    
    private init() {}
    
    /// Mock sign in implementation
    func signIn(email: String, password: String) async throws {
        if shouldThrowError {
            isAuthenticated = false
            currentUser = nil
            throw NSError(domain: "MockAuth", code: -1, 
                         userInfo: [NSLocalizedDescriptionKey: "Invalid credentials"])
        }
        isAuthenticated = true
        currentUser = MockUser(uid: "mock-user-id", email: email)
    }
    
    /// Mock create user implementation
    func createUser(email: String, password: String) async throws {
        if shouldThrowError {
            isAuthenticated = false
            currentUser = nil
            throw NSError(domain: "MockAuth", code: -1, 
                         userInfo: [NSLocalizedDescriptionKey: "Account creation failed"])
        }
        isAuthenticated = true
        currentUser = MockUser(uid: "mock-user-id", email: email)
    }
    
    /// Mock sign out implementation
    func signOut() async throws {
        if shouldThrowError {
            throw NSError(domain: "MockAuth", code: -1, 
                         userInfo: [NSLocalizedDescriptionKey: "Sign out failed"])
        }
        isAuthenticated = false
        currentUser = nil
    }
    
    /// Mock password reset implementation
    func resetPassword(email: String) async throws {
        if shouldThrowError {
            throw NSError(domain: "MockAuth", code: -1, 
                         userInfo: [NSLocalizedDescriptionKey: "Password reset failed"])
        }
        // Simulate success
    }
}

/// Mock User implementation for testing
private struct MockUser: User {
    let uid: String
    let email: String?
    
    // Required User protocol properties
    var isAnonymous: Bool { false }
    var providerData: [UserInfo] { [] }
    var refreshToken: String? { "mock-token" }
    var tenantID: String? { nil }
    var displayName: String? { nil }
    var phoneNumber: String? { nil }
    var photoURL: URL? { nil }
    var isEmailVerified: Bool { true }
    var metadata: UserMetadata { MockUserMetadata() }
    var multiFactor: MultiFactor { MockMultiFactor() }
    var providerID: String { "password" }
}

/// Mock UserMetadata for testing
private struct MockUserMetadata: UserMetadata {
    var creationDate: Date? { Date() }
    var lastSignInDate: Date? { Date() }
}

/// Mock MultiFactor for testing
private struct MockMultiFactor: MultiFactor {
    var enrolledFactors: [EnrolledFactorInfo] { [] }
    func getSession(completion: @escaping (MultiFactorSession?, Error?) -> Void) {}
    func enroll(with assertion: MultiFactorAssertion, displayName: String?, completion: @escaping (Error?) -> Void) {}
    func unenroll(with factorInfo: EnrolledFactorInfo, completion: @escaping (Error?) -> Void) {}
    func unenroll(withFactorUID factorUID: String, completion: @escaping (Error?) -> Void) {}
} 