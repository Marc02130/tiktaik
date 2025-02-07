//
// AuthenticationTests.swift
// TIKtAIk
//
// Created: 2024-02-14
// Last modified: 2024-02-14
//
// Purpose: Unit tests for authentication functionality
// Author: Assistant
// Copyright © 2024 TIKtAIk. All rights reserved.
//

import XCTest
import FirebaseAuth
@testable import TIKtAIk

/// Tests for authentication functionality
/// 
/// Tests:
/// - User creation
/// - Sign in/out
/// - Password reset
/// - Auth state changes
@MainActor
final class AuthenticationTests: XCTestCase {
    /// View model under test
    private var authViewModel: AuthViewModel!
    /// Mock auth service
    private var mockAuthService: MockAuthService!
    
    override func setUp() async throws {
        try await super.setUp()
        mockAuthService = MockAuthService.shared
        authViewModel = AuthViewModel(authService: mockAuthService)
    }
    
    override func tearDown() async throws {
        try await mockAuthService.signOut()
        mockAuthService = nil
        authViewModel = nil
        try await super.tearDown()
    }
    
    /// Tests the sign in flow
    func testSignIn() async throws {
        XCTAssertFalse(authViewModel.isAuthenticated, "Should start unauthenticated")
        XCTAssertFalse(authViewModel.isLoading, "Should not be loading")
        
        // Test sign in
        await authViewModel.signIn(email: "test@example.com", password: "password123")
        
        XCTAssertTrue(authViewModel.isAuthenticated, "Should be authenticated after sign in")
        XCTAssertFalse(authViewModel.isLoading, "Should not be loading after sign in")
        XCTAssertNil(authViewModel.errorMessage, "Should not have error message")
    }
    
    /// Tests the sign out flow
    func testSignOut() async throws {
        // Sign in first
        await authViewModel.signIn(email: "test@example.com", password: "password123")
        XCTAssertTrue(authViewModel.isAuthenticated, "Should be authenticated after sign in")
        
        // Test sign out
        await authViewModel.signOut()
        
        XCTAssertFalse(authViewModel.isAuthenticated, "Should not be authenticated after sign out")
        XCTAssertFalse(authViewModel.isLoading, "Should not be loading after sign out")
        XCTAssertNil(authViewModel.errorMessage, "Should not have error message")
    }
    
    /// Tests the password reset flow
    func testPasswordReset() async throws {
        XCTAssertFalse(authViewModel.isLoading, "Should not be loading")
        
        // Test password reset
        await authViewModel.resetPassword(email: "test@example.com")
        
        XCTAssertFalse(authViewModel.isLoading, "Should not be loading after reset")
        XCTAssertEqual(authViewModel.errorMessage, "Password reset email sent", "Should show success message")
        XCTAssertTrue(authViewModel.showError, "Should show success alert")
    }
    
    /// Tests error handling
    func testErrorHandling() async throws {
        // First verify we start unauthenticated
        XCTAssertFalse(authViewModel.isAuthenticated, "Should start unauthenticated")
        XCTAssertFalse(mockAuthService.isAuthenticated, "Service should start unauthenticated")
        
        // Configure mock to throw error
        mockAuthService.shouldThrowError = true
        
        // Test sign in with error
        await authViewModel.signIn(email: "test@example.com", password: "wrong")
        
        // Debug print states
        print("Mock service authenticated:", mockAuthService.isAuthenticated)
        print("View model authenticated:", authViewModel.isAuthenticated)
        
        // Verify error state matches service state
        XCTAssertFalse(mockAuthService.isAuthenticated, "Service should not be authenticated after error")
        XCTAssertFalse(authViewModel.isAuthenticated, "ViewModel should not be authenticated after error")
        XCTAssertFalse(authViewModel.isLoading, "Should not be loading after error")
        XCTAssertNotNil(authViewModel.errorMessage, "Should have error message")
        XCTAssertTrue(authViewModel.showError, "Should show error alert")
        
        // Reset mock for other tests
        mockAuthService.shouldThrowError = false
    }
} 