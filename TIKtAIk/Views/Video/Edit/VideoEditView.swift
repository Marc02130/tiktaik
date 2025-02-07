//
// VideoEditView.swift
// TIKtAIk
//
// Created: 2024-02-14
// Last modified: 2024-02-14
//
// Purpose: View for editing video metadata and settings
// Author: Assistant
// Copyright © 2024 TIKtAIk. All rights reserved.
//

// Framework: SwiftUI - UI Framework
import SwiftUI
// Framework: AVKit - Video Playback
import AVKit

/// View for editing video details and settings
///
/// Allows users to:
/// - Edit video title and description
/// - Manage video tags
/// - Update privacy settings
/// - Preview video content
struct VideoEditView: View {
    /// View model managing video edit operations
    @StateObject private var viewModel: VideoEditViewModel
    /// Environment dismiss action
    @Environment(\.dismiss) private var dismiss
    @FocusState private var focusedField: Field?
    
    // Define fields that can have focus
    private enum Field {
        case title
        case description
        case tags
    }
    
    /// Initializes view with video ID and refresh trigger
    /// - Parameter videoId: Unique identifier of video to edit
    /// - Parameter refreshTrigger: Trigger for refreshing video data
    init(videoId: String, refreshTrigger: RefreshTrigger) {
        _viewModel = StateObject(wrappedValue: VideoEditViewModel(videoId: videoId, refreshTrigger: refreshTrigger))
    }
    
    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading {
                    ProgressView("Loading video details...")
                } else {
                    Form {
                        Section("Video Details") {
                            TextField("Title", text: $viewModel.title)
                                .focused($focusedField, equals: .title)
                                .textInputAutocapitalization(.words)
                            
                            TextField("Description", text: $viewModel.description, axis: .vertical)
                                .focused($focusedField, equals: .description)
                                .lineLimit(3...6)
                            
                            TextField("Tags (comma separated)", text: $viewModel.tags)
                                .focused($focusedField, equals: .tags)
                                .autocorrectionDisabled()
                        }
                        
                        Section("Privacy") {
                            Toggle("Private Video", isOn: $viewModel.isPrivate)
                            Toggle("Allow Comments", isOn: $viewModel.allowComments)
                        }
                        
                        Section("Thumbnail") {
                            if let thumbnails = viewModel.thumbnails {
                                ThumbnailSelectionView(
                                    selectedIndex: $viewModel.selectedThumbnailIndex,
                                    thumbnails: thumbnails
                                )
                            } else {
                                ProgressView("Generating thumbnails...")
                            }
                        }
                        
                        if let player = viewModel.player {
                            Section("Preview") {
                                VideoPlayer(player: player)
                                    .frame(height: 200)
                                    .onDisappear {
                                        player.pause()
                                    }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Edit Video")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        Task {
                            await viewModel.saveChanges()
                            if viewModel.error == nil {
                                dismiss()
                            }
                        }
                    }
                    .disabled(viewModel.isSaving || viewModel.isLoading)
                }
                
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") {
                        focusedField = nil
                    }
                }
            }
        }
        .alert(
            "Error",
            isPresented: Binding(
                get: { viewModel.error != nil },
                set: { if !$0 { viewModel.clearError() } }
            )
        ) {
            Button("OK") {
                viewModel.clearError()
            }
        } message: {
            if let error = viewModel.error {
                Text(error)
            }
        }
        .task {
            await viewModel.loadVideo()
            await viewModel.generateThumbnails()
        }
    }
}

struct ThumbnailSelectionView: View {
    @Binding var selectedIndex: Int
    let thumbnails: [UIImage]
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(thumbnails.indices, id: \.self) { index in
                    ThumbnailButton(
                        image: thumbnails[index],
                        isSelected: index == selectedIndex,
                        action: { selectedIndex = index }
                    )
                }
            }
            .padding()
        }
    }
}

struct ThumbnailButton: View {
    let image: UIImage
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(width: 120, height: 80)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay {
                    RoundedRectangle(cornerRadius: 8)
                        .strokeBorder(isSelected ? Color.blue : .clear, lineWidth: 3)
                }
        }
        .buttonStyle(.plain)
    }
} 