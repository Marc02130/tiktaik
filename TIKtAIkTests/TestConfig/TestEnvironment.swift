//
// TestEnvironment.swift
// TIKtAIk
//
// Created: 2024-02-14
// Last modified: 2024-02-14
//
// Author: Assistant
// Copyright © 2024 TIKtAIk. All rights reserved.
//

import Foundation

enum TestEnvironment {
    static func setupEnvironment() {
        // Set up test environment variables
        setenv("TEST_MODE", "1", 1)
        
        // Set up Firebase test credentials
        setenv("FIREBASE_TEST_EMAIL", "test@tiktaik.com", 1)
        setenv("FIREBASE_TEST_PASSWORD", "testpassword123", 1)
    }
    
    static func tearDownEnvironment() {
        // Clean up environment variables
        unsetenv("TEST_MODE")
        unsetenv("FIREBASE_TEST_EMAIL")
        unsetenv("FIREBASE_TEST_PASSWORD")
    }
} 