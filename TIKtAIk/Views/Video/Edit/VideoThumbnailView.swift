//
// VideoThumbnailView.swift
// TIKtAIk
//
// Created: 2024-02-14
// Last modified: 2024-02-14
//
// Purpose: View for selecting video thumbnails
// Author: Assistant
// Copyright © 2024 TIKtAIk. All rights reserved.
//

import SwiftUI
import AVKit

struct VideoThumbnailView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: VideoThumbnailViewModel
    @State private var showError = false
    @State private var errorMessage: String?
    
    init(videoId: String) {
        _viewModel = StateObject(wrappedValue: VideoThumbnailViewModel(videoId: videoId))
    }
    
    var body: some View {
        NavigationView {
            Group {
                if viewModel.isLoading {
                    ProgressView("Generating thumbnails...")
                } else {
                    ScrollView {
                        thumbnailGrid
                    }
                }
            }
            .navigationTitle("Select Thumbnail")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        Task {
                            do {
                                try await viewModel.saveThumbnail()
                                dismiss()
                            } catch {
                                errorMessage = error.localizedDescription
                                showError = true
                            }
                        }
                    }
                    .disabled(viewModel.selectedThumbnailIndex == nil)
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", action: {})
            } message: {
                if let message = errorMessage {
                    Text(message)
                }
            }
        }
    }
    
    private var thumbnailGrid: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 150))], spacing: 16) {
            ForEach(viewModel.thumbnails.indices, id: \.self) { index in
                ThumbnailButtonView(
                    image: viewModel.thumbnails[index],
                    isSelected: index == viewModel.selectedThumbnailIndex,
                    action: { viewModel.selectedThumbnailIndex = index }
                )
            }
        }
        .padding()
    }
}

private struct ThumbnailButtonView: View {
    let image: UIImage
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(width: 150, height: 100)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay {
                    RoundedRectangle(cornerRadius: 8)
                        .strokeBorder(isSelected ? Color.accentColor : .clear, lineWidth: 3)
                }
        }
        .buttonStyle(.plain)
    }
} 