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
    @EnvironmentObject private var profileViewModel: ProfileViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showTagSelection = false
    @State private var showTrimView = false
    @State private var showCropView = false
    @State private var showThumbnailView = false
    @State private var isPlaying = false
    @State private var isMuted = false
    @State private var showError = false
    @State private var errorMessage: String?
    @State private var showSubtitleEditor = false
    @State private var subtitles: [VideoSubtitle] = []
    @State private var showMetadataForm = false
    
    var body: some View {
        NavigationView {
            MainContent(
                viewModel: viewModel,
                isPlaying: $isPlaying,
                isMuted: $isMuted,
                showTagSelection: $showTagSelection,
                showTrimView: $showTrimView,
                showCropView: $showCropView,
                showThumbnailView: $showThumbnailView,
                showSubtitleEditor: $showSubtitleEditor,
                showError: $showError,
                errorMessage: $errorMessage,
                subtitles: $subtitles,
                dismiss: dismiss,
                showMetadataForm: $showMetadataForm
            )
        }
    }
}

// Renamed from ContentView to MainContent to avoid conflict
private struct MainContent: View {
    @ObservedObject var viewModel: VideoEditViewModel
    @EnvironmentObject private var profileViewModel: ProfileViewModel
    @Binding var isPlaying: Bool
    @Binding var isMuted: Bool
    @Binding var showTagSelection: Bool
    @Binding var showTrimView: Bool
    @Binding var showCropView: Bool
    @Binding var showThumbnailView: Bool
    @Binding var showSubtitleEditor: Bool
    @Binding var showError: Bool
    @Binding var errorMessage: String?
    @Binding var subtitles: [VideoSubtitle]
    let dismiss: DismissAction
    @Binding var showMetadataForm: Bool
    
    var body: some View {
        FormContent(
            viewModel: viewModel,
            isPlaying: $isPlaying,
            isMuted: $isMuted,
            showTagSelection: $showTagSelection,
            showTrimView: $showTrimView,
            showCropView: $showCropView,
            showThumbnailView: $showThumbnailView,
            showSubtitleEditor: $showSubtitleEditor,
            showError: $showError,
            errorMessage: $errorMessage,
            subtitles: $subtitles,
            dismiss: dismiss,
            showMetadataForm: $showMetadataForm
        )
        .navigationTitle("Edit Video")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            CustomToolbarContent(
                viewModel: viewModel,
                dismiss: dismiss,
                showError: $showError,
                errorMessage: $errorMessage
            )
        }
        .alert("Error Saving", isPresented: $showError) {
            Button("OK", role: .cancel) { }
        } message: {
            if let message = errorMessage {
                Text(message)
            }
        }
        .sheet(isPresented: $showMetadataForm) {
            VideoMetadataForm(usermetadata: $viewModel.usermetadata)
                .environmentObject(profileViewModel)
        }
        .sheet(isPresented: $showTagSelection) {
            TagSelectionView(selectedTags: viewModel.selectedTagsBinding)
        }
        .sheet(isPresented: $showTrimView) {
            if let url = viewModel.videoURL {
                VideoTrimView(
                    timeRange: $viewModel.timeRange,
                    duration: viewModel.duration,
                    thumbnails: viewModel.thumbnails ?? [],
                    onPreview: viewModel.previewTime,
                    onSave: { Task { await viewModel.trimVideo() } },
                    viewModel: viewModel
                )
            }
        }
        .sheet(isPresented: $showCropView) {
            if let thumbnail = viewModel.thumbnails?.first {
                VideoCropView(
                    cropRect: $viewModel.cropRect,
                    thumbnail: thumbnail,
                    onSave: { Task { await viewModel.cropVideo() } },
                    viewModel: viewModel
                )
            }
        }
        .sheet(isPresented: $showThumbnailView) {
            VideoThumbnailView(videoId: viewModel.videoId)
        }
        .sheet(isPresented: $showSubtitleEditor) {
            if let videoURLString = viewModel.videoURL {
                let videoURL = URL(fileURLWithPath: videoURLString)
                let subtitleViewModel = viewModel.getSubtitleViewModel() ?? VideoSubtitleViewModel(
                    videoId: viewModel.videoId,
                    videoURL: videoURL
                )
                SubtitleEditView(
                    viewModel: subtitleViewModel
                )
                .navigationTitle("Subtitles")
            } else {
                Text("Video not available")
            }
        }
    }
}

// Renamed from ToolbarContent to CustomToolbarContent
private struct CustomToolbarContent: ToolbarContent {
    let viewModel: VideoEditViewModel
    let dismiss: DismissAction
    @Binding var showError: Bool
    @Binding var errorMessage: String?
    
    var body: some ToolbarContent {
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

private struct FormContent: View {
    @ObservedObject var viewModel: VideoEditViewModel
    @Binding var isPlaying: Bool
    @Binding var isMuted: Bool
    @Binding var showTagSelection: Bool
    @Binding var showTrimView: Bool
    @Binding var showCropView: Bool
    @Binding var showThumbnailView: Bool
    @Binding var showSubtitleEditor: Bool
    @Binding var showError: Bool
    @Binding var errorMessage: String?
    @Binding var subtitles: [VideoSubtitle]
    let dismiss: DismissAction
    @Binding var showMetadataForm: Bool
    
    var body: some View {
        Form {
            VideoPreviewSection(viewModel: viewModel, isPlaying: $isPlaying, isMuted: $isMuted)
            VideoDetailsSection(viewModel: viewModel)
            PrivacySection(viewModel: viewModel)
            TagsSection(viewModel: viewModel, showTagSelection: $showTagSelection)
            Section("Additional Details") {
                Button {
                    showMetadataForm = true
                } label: {
                    HStack {
                        Text("Metadata")
                        Spacer()
                        Text(viewModel.usermetadata.customFields.isEmpty ? "Add details" : "\(viewModel.usermetadata.customFields.count) fields")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            EditVideoSection(
                viewModel: viewModel,
                showTrimView: $showTrimView,
                showCropView: $showCropView,
                showThumbnailView: $showThumbnailView,
                showSubtitleEditor: $showSubtitleEditor
            )
        }
        .onChange(of: viewModel.usermetadata) { _, newValue in
            Task {
                try? await viewModel.saveChanges()
            }
        }
    }
}

private struct VideoPreviewSection: View {
    @ObservedObject var viewModel: VideoEditViewModel
    @Binding var isPlaying: Bool
    @Binding var isMuted: Bool
    
    var body: some View {
        Section("Preview") {
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
}

private struct VideoDetailsSection: View {
    @ObservedObject var viewModel: VideoEditViewModel
    
    var body: some View {
        Section("Details") {
            TextField("Title", text: $viewModel.title)
                .textInputAutocapitalization(.words)
            
            TextField("Description", text: $viewModel.description, axis: .vertical)
                .lineLimit(3...6)
        }
    }
}

private struct TagsSection: View {
    @ObservedObject var viewModel: VideoEditViewModel
    @Binding var showTagSelection: Bool
    
    var body: some View {
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
}

private struct PrivacySection: View {
    @ObservedObject var viewModel: VideoEditViewModel
    
    var body: some View {
        Section("Privacy") {
            Toggle("Private Video", isOn: $viewModel.isPrivate)
            Toggle("Allow Comments", isOn: $viewModel.allowComments)
        }
    }
}

private struct EditVideoSection: View {
    @ObservedObject var viewModel: VideoEditViewModel
    @Binding var showTrimView: Bool
    @Binding var showCropView: Bool
    @Binding var showThumbnailView: Bool
    @Binding var showSubtitleEditor: Bool
    
    var body: some View {
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
            Button("Edit Subtitles") {
                showSubtitleEditor = true
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
