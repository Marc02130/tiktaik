//
// FirebaseTestHelper.swift
// TIKtAIk
//
// Created: 2024-02-14
// Last modified: 2024-02-14
//
// Author: Assistant
// Copyright © 2024 TIKtAIk. All rights reserved.
//

import Foundation
import FirebaseCore
import FirebaseAuth
@testable import TIKtAIk

enum FirebaseTestHelper {
    static func setupTestEnvironment() throws {
        // Clean up any existing Firebase instance
        if let app = FirebaseApp.app() {
            app.delete { _ in }
        }
        
        // Configure Firebase for testing
        let options = FirebaseOptions(contentsOfFile: Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist")!)!
        options.bundleID = "com.mb.tiktaik" // Force bundle ID for testing
        FirebaseApp.configure(options: options)
        
        // Verify Firebase is configured
        guard FirebaseApp.app() != nil else {
            throw NSError(domain: "FirebaseTestHelper", code: -1, userInfo: [
                NSLocalizedDescriptionKey: "Failed to configure Firebase"
            ])
        }
    }
    
    static func waitForAuthStateChange() async throws {
        // Create a task to handle timeout
        let timeoutTask = Task {
            try await Task.sleep(nanoseconds: UInt64(5 * Double(NSEC_PER_SEC)))
            throw NSError(domain: "FirebaseTestHelper",
                         code: -1,
                         userInfo: [NSLocalizedDescriptionKey: "Timeout waiting for auth state change"])
        }
        
        // Create a task to wait for auth state change
        let authTask = Task {
            try await withCheckedThrowingContinuation { continuation in
                var handle: AuthStateDidChangeListenerHandle?
                var hasCompleted = false
                
                handle = Auth.auth().addStateDidChangeListener { auth, user in
                    // Only fulfill once
                    if !hasCompleted {
                        hasCompleted = true
                        if let handle = handle {
                            Auth.auth().removeStateDidChangeListener(handle)
                        }
                        continuation.resume()
                    }
                }
            }
        }
        
        // Wait for either auth change or timeout
        do {
            try await authTask.value
            timeoutTask.cancel()
        } catch {
            authTask.cancel()
            throw error
        }
    }
    
    static func tearDown() {
        if let app = FirebaseApp.app() {
            app.delete { _ in }
        }
    }
} 