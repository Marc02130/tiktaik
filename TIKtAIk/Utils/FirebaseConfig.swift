//
// FirebaseConfig.swift
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

enum FirebaseConfigError: Error {
    case configurationError(String)
}

class FirebaseConfig {
    static func configureForTesting() throws {
        // Clean up any existing Firebase instance
        if FirebaseApp.app() != nil {
            FirebaseApp.app()?.delete { _ in }
        }
        
        // Create test configuration
        let options = FirebaseOptions(
            googleAppID: "1:534020769432:ios:34c06e0fa91bb9b981f2ed",
            gcmSenderID: "534020769432"
        )
        options.apiKey = "AIzaSyANQmskIwyRdbcBwTo5orSCJYFqpX9OtN8"
        options.projectID = "tiktaik"
        options.bundleID = "com.mb.tiktaik"
        options.clientID = "534020769432-la3nrctnd9qmhqnuqln12fpvmkomb5rl.apps.googleusercontent.com"
        options.storageBucket = "tiktaik.firebasestorage.app"
        
        FirebaseApp.configure(options: options)
    }
    
    static func configureForProduction() {
        FirebaseApp.configure()
    }
    
    static func tearDown() {
        if FirebaseApp.app() != nil {
            FirebaseApp.app()?.delete { _ in }
        }
    }
} 