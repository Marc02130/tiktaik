//
// StorageService.swift
// TIKtAIk
//
// Created: 2024-02-14
// Last modified: 2024-02-14
//
// Author: Assistant
// Copyright © 2024 TIKtAIk. All rights reserved.
//

import Foundation
import FirebaseStorage
import FirebaseAuth
import FirebaseCore

/// Service for handling Firebase Storage operations
class StorageService {
    static let shared = StorageService()
    private let storage: Storage
    private let auth: Auth
    
    private init() {
        // Ensure Firebase is configured
        if FirebaseApp.app() == nil {
            FirebaseApp.configure()
        }
        
        self.storage = Storage.storage()
        self.auth = Auth.auth()
    }
    
    /// Signs in for testing using email/password
    func signInForTesting() async throws {
        // Convert signOut to async using withCheckedThrowingContinuation
        try await withCheckedThrowingContinuation { continuation in
            do {
                try Auth.auth().signOut()
                continuation.resume()
            } catch {
                continuation.resume(throwing: error)
            }
        }
        
        let email = ProcessInfo.processInfo.environment["FIREBASE_TEST_EMAIL"] ?? "test@tiktaik.com"
        let password = ProcessInfo.processInfo.environment["FIREBASE_TEST_PASSWORD"] ?? "testpassword123"
        
        return try await withCheckedThrowingContinuation { continuation in
            auth.signIn(withEmail: email, password: password) { result, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                continuation.resume(returning: ())
            }
        }
    }
    
    /// Uploads data to Firebase Storage
    /// - Parameters:
    ///   - data: The data to upload
    ///   - path: The storage path
    ///   - metadata: Optional metadata
    /// - Returns: Download URL for the uploaded file
    func uploadData(_ data: Data, to path: String, metadata: StorageMetadata? = nil) async throws -> URL {
        // Ensure we're authenticated
        guard let _ = auth.currentUser else {
            throw StorageError.authenticationRequired
        }
        
        let storageRef = storage.reference()
        let fileRef = storageRef.child(path)
        
        return try await withCheckedThrowingContinuation { continuation in
            fileRef.putData(data, metadata: metadata) { metadata, error in
                if let error = error {
                    continuation.resume(throwing: StorageError.uploadFailed(error))
                    return
                }
                
                // Get download URL
                fileRef.downloadURL { url, error in
                    if let error = error {
                        continuation.resume(throwing: StorageError.downloadFailed(error))
                        return
                    }
                    
                    guard let url = url else {
                        continuation.resume(throwing: StorageError.invalidData)
                        return
                    }
                    
                    continuation.resume(returning: url)
                }
            }
        }
    }
    
    /// Deletes a file from Firebase Storage
    /// - Parameter path: The storage path to delete
    func deleteFile(at path: String) async throws {
        guard let _ = auth.currentUser else {
            throw StorageError.authenticationRequired
        }
        
        let storageRef = storage.reference()
        let fileRef = storageRef.child(path)
        
        try await fileRef.delete()
    }
} 