//
// TestSetup.swift
// TIKtAIkTests
//
// Created: 2024-02-14
// Last modified: 2024-02-14
//
// Purpose: Test environment configuration helpers
// Author: Assistant
// Copyright © 2024 TIKtAIk. All rights reserved.
//

import Foundation

/// Helper for test environment setup
enum TestSetup {
    /// Test configuration options
    struct Config {
        /// Test email for authentication
        static let testEmail = "test@example.com"
        /// Test password for authentication
        static let testPassword = "password123"
        /// Test timeout duration
        static let timeout: TimeInterval = 30.0
    }
    
    /// Configures the test environment
    static func configureTestEnvironment() {
        // Add any needed test configuration here
    }
    
    /// Tears down the test environment
    static func tearDownTestEnvironment() {
        // Add any needed test cleanup here
    }
}

/// Test-specific errors
enum TestError: LocalizedError {
    case timeout
    
    var errorDescription: String? {
        switch self {
        case .timeout:
            return "Operation timed out"
        }
    }
} 