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
    @State private var showTagSelection = false
    
    // Define fields that can have focus
    private enum Field {
        case title
        case description
    }
    
    /// Initializes view with video ID and refresh trigger
    /// - Parameter videoId: Unique identifier of video to edit
    /// - Parameter refreshTrigger: Trigger for refreshing video data
    init(videoId: String, refreshTrigger: RefreshTrigger) {
        let vm = VideoEditViewModel(videoId: videoId, refreshTrigger: refreshTrigger)
        _viewModel = StateObject(wrappedValue: vm)
    }
    
    var body: some View {
        NavigationStack {
            content
                .navigationTitle("Edit Video")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar { toolbarContent }
                .sheet(isPresented: $showTagSelection) { tagSelectionSheet }
                .alert("Error", isPresented: errorBinding) { errorAlert }
        }
        .task {
            await viewModel.loadVideo()
            await viewModel.generateThumbnails()
        }
    }
    
    private var content: some View {
        Group {
            if viewModel.isLoading {
                ProgressView("Loading video details...")
            } else {
                Form {
                    videoDetailsSection
                    tagsSection
                    privacySection
                    thumbnailSection
                }
            }
        }
    }
    
    private var videoDetailsSection: some View {
        Section("Video Details") {
            TextField("Title", text: $viewModel.title)
                .focused($focusedField, equals: .title)
                .textInputAutocapitalization(.words)
            
            TextField("Description", text: $viewModel.description, axis: .vertical)
                .focused($focusedField, equals: .description)
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
    
    private var thumbnailSection: some View {
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
    }
    
    private var toolbarContent: some ToolbarContent {
        Group {
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
    
    private var tagSelectionSheet: some View {
        NavigationView {
            TagSelectionView(selectedTags: Binding(
                get: { viewModel.selectedTags },
                set: { viewModel.updateTags($0) }
            ))
            .navigationTitle("Edit Tags")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        showTagSelection = false
                    }
                }
            }
        }
    }
    
    private var errorBinding: Binding<Bool> {
        Binding(
            get: { viewModel.error != nil },
            set: { if !$0 { viewModel.clearError() } }
        )
    }
    
    private var errorAlert: some View {
        Button("OK") { 
            viewModel.clearError() 
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