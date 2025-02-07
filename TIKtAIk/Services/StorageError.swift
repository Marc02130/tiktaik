//
// StorageError.swift
// TIKtAIk
//
// Created: 2024-02-14
// Last modified: 2024-02-14
//
// Author: Assistant
// Copyright © 2024 TIKtAIk. All rights reserved.
//

import Foundation

/// Errors that can occur during storage operations
public enum StorageError: LocalizedError {
    case authenticationRequired
    case authenticationFailed(Error)
    case uploadFailed(Error)
    case downloadFailed(Error)
    case invalidData
    case notInitialized
    
    public var errorDescription: String? {
        switch self {
        case .authenticationRequired:
            return "Authentication is required for this operation"
        case .authenticationFailed(let error):
            return "Authentication failed: \(error.localizedDescription)"
        case .uploadFailed(let error):
            return "Upload failed: \(error.localizedDescription)"
        case .downloadFailed(let error):
            return "Download failed: \(error.localizedDescription)"
        case .invalidData:
            return "Invalid data received"
        case .notInitialized:
            return "Storage service not properly initialized"
        }
    }
} 