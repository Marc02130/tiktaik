//
// SubtitleControlsView.swift
// TIKtAIk
//
// Created: 2024-02-14
// Last modified: 2024-02-14
//
// Purpose: View for subtitle generation controls and preferences
// Author: Assistant
// Copyright © 2024 TIKtAIk. All rights reserved.

import SwiftUI

struct SubtitleControlsView: View {
    @ObservedObject var viewModel: VideoSubtitleViewModel
    
    var body: some View {
        VStack(spacing: 12) {
            // Font Size
            Picker("Font Size", selection: $viewModel.preferences.fontSize) {
                ForEach(SubtitlePreferences.FontSize.allCases, id: \.self) { size in
                    Text(size.rawValue).tag(size)
                }
            }
            .pickerStyle(.segmented)
            
            // Color
            Picker("Color", selection: $viewModel.preferences.textColor) {
                ForEach(SubtitlePreferences.TextColor.allCases, id: \.self) { color in
                    Circle()
                        .fill(color.color)
                        .frame(width: 20, height: 20)
                        .tag(color)
                }
            }
            .pickerStyle(.segmented)
            
            // Position
            Picker("Position", selection: $viewModel.preferences.position) {
                ForEach(SubtitlePreferences.Position.allCases, id: \.self) { position in
                    Text(position.rawValue.capitalized).tag(position)
                }
            }
            .pickerStyle(.segmented)
        }
        .padding()
        .onChange(of: viewModel.preferences) { newValue in
            Task {
                await viewModel.updatePreferences(newValue)
            }
        }
    }
}

#Preview {
    // Create a dummy URL for preview purposes
    let previewURL = URL(fileURLWithPath: "preview.mp4")
    return SubtitleControlsView(viewModel: VideoSubtitleViewModel(videoId: "preview", videoURL: previewURL))
} 