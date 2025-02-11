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
    @StateObject var viewModel: VideoEditViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showTagSelection = false
    @State private var showTrimView = false
    @State private var showCropView = false
    @State private var showThumbnailView = false
    @State private var isPlaying = false
    @State private var isMuted = false
    @State private var showError = false
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationView {
            Group {
                if viewModel.isLoading {
                    ProgressView("Loading video details...")
                } else {
                    Form {
                        videoPreviewSection
                        videoDetailsSection
                        tagsSection
                        privacySection
                        editVideoSection
                    }
                }
            }
            .navigationTitle("Edit Video")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { toolbarContent }
            .alert("Error Saving", isPresented: $showError) {
                Button("OK", action: {})
            } message: {
                if let message = errorMessage {
                    Text(message)
                }
            }
            .sheet(isPresented: $showTagSelection) {
                TagSelectionView(selectedTags: viewModel.selectedTagsBinding)
            }
            .sheet(isPresented: $showTrimView) {
                if let videoURL = viewModel.videoURL {
                    VideoTrimView(
                        timeRange: $viewModel.timeRange,
                        duration: viewModel.duration,
                        thumbnails: viewModel.thumbnails ?? [],
                        onPreview: { time in
                            viewModel.previewTime(time)
                        },
                        onSave: {
                            Task {
                                await viewModel.trimVideo()
                            }
                        },
                        viewModel: viewModel
                    )
                }
            }
            .sheet(isPresented: $showCropView) {
                if let videoURL = viewModel.videoURL,
                   let thumbnail = viewModel.thumbnails?.first {
                    VideoCropView(
                        cropRect: $viewModel.cropRect,
                        thumbnail: thumbnail,
                        onSave: {
                            Task {
                                await viewModel.cropVideo()
                            }
                        },
                        viewModel: viewModel
                    )
                }
            }
            .sheet(isPresented: $showThumbnailView) {
                VideoThumbnailView(videoId: viewModel.videoId)
            }
        }
    }
    
    private var videoPreviewSection: some View {
        Section {
            if let player = viewModel.player {
                VideoPlayer(player: player)
                    .frame(height: 200)
                    .overlay(alignment: .bottom) {
                        HStack {
                            Button {
                                isPlaying.toggle()
                                if isPlaying {
                                    player.play()
                                } else {
                                    player.pause()
                                }
                            } label: {
                                Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                            }
                            
                            Button {
                                isMuted.toggle()
                                player.isMuted = isMuted
                            } label: {
                                Image(systemName: isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill")
                            }
                            
                            Spacer()
                        }
                        .padding()
                        .background(.ultraThinMaterial)
                    }
            }
        }
    }
    
    private var videoDetailsSection: some View {
        Section("Video Details") {
            TextField("Title", text: $viewModel.title)
                .textInputAutocapitalization(.words)
            
            TextField("Description", text: $viewModel.description, axis: .vertical)
                .lineLimit(3...6)
        }
    }
    
    private var tagsSection: some View {
        Section("Tags") {
            if viewModel.selectedTags.isEmpty {
                Text("No tags")
                    .foregroundStyle(.secondary)
            } else {
                TagsDisplay(tags: Array(viewModel.selectedTags))
            }
            
            Button("Edit Tags") {
                showTagSelection = true
            }
        }
    }
    
    private var privacySection: some View {
        Section("Privacy") {
            Toggle("Private Video", isOn: $viewModel.isPrivate)
            Toggle("Allow Comments", isOn: $viewModel.allowComments)
        }
    }
    
    private var editVideoSection: some View {
        Section("Edit Video") {
            Button("Trim Video") {
                showTrimView = true
            }
            .disabled(viewModel.videoURL == nil)
            
            Button("Crop Video") {
                showCropView = true
            }
            .disabled(viewModel.videoURL == nil)
            
            Button("Change Thumbnail") {
                showThumbnailView = true
            }
        }
    }
    
    private var toolbarContent: some ToolbarContent {
        Group {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Cancel") {
                    dismiss()
                }
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Save") {
                    Task {
                        do {
                            try await viewModel.saveChanges()
                            dismiss()
                        } catch {
                            errorMessage = error.localizedDescription
                            showError = true
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Supporting Views
struct TagsDisplay: View {
    let tags: [String]
    
    var body: some View {
        FlowLayout(spacing: 8) {
            ForEach(tags, id: \.self) { tag in
                Text(tag)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.accentColor.opacity(0.2))
                    .foregroundColor(.accentColor)
                    .clipShape(Capsule())
            }
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