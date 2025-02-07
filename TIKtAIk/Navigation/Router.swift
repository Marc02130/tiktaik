//
// Router.swift
// TIKtAIk
//
// Created: 2024-02-14
// Last modified: 2024-02-14
//
// Purpose: Navigation router for the app
// Author: Assistant
// Copyright © 2024 TIKtAIk. All rights reserved.
//

// Framework: SwiftUI - UI Framework
import SwiftUI

/// Router for managing app navigation
///
/// Handles:
/// - Navigation paths for each tab
/// - Modal presentations
/// - Deep linking
@Observable final class Router {
    /// Navigation path for home feed
    var homePath: [Route] = []
    /// Navigation path for video library
    var libraryPath: [Route] = []
    /// Navigation path for profile
    var profilePath: [Route] = []
    
    /// Whether to show video upload sheet
    var showUploadVideo = false
    
    enum Route: Hashable {
        case videoDetail(String)
        case editVideo(String)
    }
    
    /// Resets all navigation paths
    func resetPaths() {
        homePath = []
        libraryPath = []
        profilePath = []
    }
} 