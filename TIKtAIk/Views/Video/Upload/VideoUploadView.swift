//
// VideoUploadView.swift
// TIKtAIk
//
// Created: 2024-02-14
// Last modified: 2024-02-14
//
// Purpose: View for uploading and previewing videos
// Author: Assistant
// Copyright © 2024 TIKtAIk. All rights reserved.
//

// Framework: SwiftUI - UI Framework
import SwiftUI
// Framework: PhotosUI - Photo Library Access
import PhotosUI
// Framework: AVKit - Video Playback
import AVKit

/// View for uploading videos to TIKtAIk
///
/// Features:
/// - Video selection from photo library
/// - Upload progress tracking
/// - Error handling
/// - Video preview
/// - Metadata form
struct VideoUploadView: View {
    @StateObject private var viewModel: VideoUploadViewModel
    @EnvironmentObject private var profileViewModel: ProfileViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showTagSelection = false
    @State private var showMetadataForm = false
    let refreshTrigger: RefreshTrigger
    
    init(refreshTrigger: RefreshTrigger) {
        self._viewModel = StateObject(wrappedValue: VideoUploadViewModel())
        self.refreshTrigger = refreshTrigger
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // Video Selection/Preview
                    VideoPickerSection(viewModel: viewModel)
                    
                    if viewModel.selectedVideoURL != nil {
                        // Thumbnail Selection
                        ThumbnailSection(viewModel: viewModel)
                        
                        // Title & Description
                        TextField("Title", text: $viewModel.title)
                            .textFieldStyle(.roundedBorder)
                        
                        TextEditor(text: $viewModel.description)
                            .frame(height: 100)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.gray.opacity(0.2))
                            )
                        
                        // Privacy Settings
                        Toggle("Private", isOn: $viewModel.isPrivate)
                        Toggle("Allow Comments", isOn: $viewModel.allowComments)
                        
                        // Tags
                        Button {
                            showTagSelection = true
                        } label: {
                            HStack {
                                Text("Tags")
                                Spacer()
                                Text(viewModel.selectedTags.isEmpty ? "Add tags" : "\(viewModel.selectedTags.count) tags")
                                    .foregroundStyle(.secondary)
                            }
                        }
                        
                        // Metadata
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
                }
                .padding()
            }
            .navigationTitle("Upload Video")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Upload") {
                        Task {
                            await viewModel.uploadVideo()
                        }
                    }
                    .disabled(!viewModel.isValidForm)
                }
            }
            .sheet(isPresented: $showTagSelection) {
                TagSelectionView(selectedTags: viewModel.selectedTagsBinding)
            }
            .sheet(isPresented: $showMetadataForm) {
                VideoMetadataForm(usermetadata: $viewModel.usermetadata)
                    .environmentObject(profileViewModel)
            }
        }
    }
}

// MARK: - Video Picker Section
private struct VideoPickerSection: View {
    @ObservedObject var viewModel: VideoUploadViewModel
    
    var body: some View {
        VStack(spacing: 12) {
            if let url = viewModel.selectedVideoURL {
                VideoPlayer(player: AVPlayer(url: url))
                    .frame(height: 300)
                    .cornerRadius(12)
                
                if viewModel.isUploading {
                    UploadProgressView(progress: viewModel.uploadProgress)
                }
            } else {
                PhotosPicker(selection: $viewModel.selectedItem,
                           matching: .videos,
                           photoLibrary: .shared()) {
                    UploadPromptView()
                }
            }
        }
    }
}

// MARK: - Thumbnail Section
private struct ThumbnailSection: View {
    @ObservedObject var viewModel: VideoUploadViewModel
    
    var body: some View {
        Button {
            Task {
                await viewModel.generateThumbnails()
            }
        } label: {
            if let thumbnails = viewModel.thumbnails, !thumbnails.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(thumbnails.indices, id: \.self) { index in
                            Image(uiImage: thumbnails[index])
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 80, height: 120)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(index == viewModel.selectedThumbnailIndex ? Color.blue : Color.clear, lineWidth: 2)
                                )
                                .onTapGesture {
                                    viewModel.selectedThumbnailIndex = index
                                }
                        }
                    }
                    .padding(.horizontal)
                }
            } else {
                Text("Generate Thumbnails")
                    .foregroundColor(.blue)
            }
        }
    }
}

// MARK: - Helper Views
private struct UploadPromptView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "video.badge.plus")
                .font(.system(size: 40))
            Text("Select Video")
                .font(.headline)
            Text("MP4 or MOV up to 500MB")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(height: 300)
        .frame(maxWidth: .infinity)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
}

private struct UploadProgressView: View {
    let progress: Double
    
    var body: some View {
        VStack(spacing: 8) {
            ProgressView(value: progress)
            Text("\(Int(progress * 100))%")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal)
    }
}