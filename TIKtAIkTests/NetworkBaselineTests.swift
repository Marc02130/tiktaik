//
// NetworkBaselineTests.swift
// TIKtAIkTests
//
// Created: 2024-02-14
// Last modified: 2024-02-14
//
// Purpose: Network performance baseline tests
// Author: Assistant
// Copyright © 2024 TIKtAIk. All rights reserved.
//

import XCTest
@testable import TIKtAIk

/// Tests for establishing network performance baselines
final class NetworkBaselineTests: XCTestCase {
    /// Auth view model for testing
    private var authViewModel: AuthViewModel!
    /// Mock auth service
    private var mockAuthService: MockAuthService!
    
    override func setUp() async throws {
        try await super.setUp()
        
        // Set up auth environment
        await MainActor.run {
            mockAuthService = MockAuthService.shared
            authViewModel = AuthViewModel(authService: mockAuthService)
        }
    }
    
    override func tearDown() async throws {
        await MainActor.run {
            mockAuthService = nil
            authViewModel = nil
        }
        try await super.tearDown()
    }
    
    /// Tests login performance baseline
    func testLoginPerformance() async throws {
        // Skip test if running in CI environment
        guard !ProcessInfo.processInfo.environment.keys.contains("CI") else {
            throw XCTSkip("Skipping performance test in CI environment")
        }
        
        // Measure login performance
        measure {
            let expectation = expectation(description: "Login complete")
            
            Task {
                do {
                    try await authViewModel.signIn(email: "test@example.com", password: "password123")
                    expectation.fulfill()
                } catch {
                    XCTFail("Login failed: \(error.localizedDescription)")
                }
            }
            
            // Wait for login with timeout
            wait(for: [expectation], timeout: TestSetup.Config.timeout)
        }
    }
} 