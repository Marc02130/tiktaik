//
// VideoPickerButton.swift
// TIKtAIk
//
// Created: 2024-02-14
// Last modified: 2024-02-14
//
// Purpose: Button view for video selection
// Author: Assistant
// Copyright © 2024 TIKtAIk. All rights reserved.
//

import SwiftUI

/// Button view for selecting videos from library
struct VideoPickerButton: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "video.badge.plus")
                .font(.largeTitle)
                .foregroundColor(.blue)
            
            Text("Select Video")
                .font(.headline)
            
            Text("MP4, MOV up to 3 minutes")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
} 