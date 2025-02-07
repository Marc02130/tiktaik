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
    enum Mode {
        case upload
        case edit
    }
    
    @StateObject private var viewModel = VideoUploadViewModel()
    @Environment(\.dismiss) private var dismiss
    @State private var mode: Mode = .upload
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Video Preview/Picker
                if let url = viewModel.selectedVideoURL {
                    VStack(spacing: 12) {
                        VideoPlayer(player: AVPlayer(url: url))
                            .frame(height: 300)
                            .cornerRadius(12)
                        
                        // Thumbnail Selection
                        if mode == .upload {
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
                } else {
                    // Upload Prompt (only show in upload mode)
                    if mode == .upload {
                        PhotosPicker(selection: $viewModel.selectedItem,
                                   matching: .videos,
                                   photoLibrary: .shared()) {
                            VideoPickerButton()
                        }
                    }
                }
                
                // Metadata Form
                VStack(alignment: .leading, spacing: 16) {
                    Text("Video Details")
                        .font(.headline)
                        .padding(.bottom, 4)
                    
                    TextField("Title", text: $viewModel.title)
                        .textFieldStyle(.roundedBorder)
                    
                    TextField("Description", text: $viewModel.description, axis: .vertical)
                        .textFieldStyle(.roundedBorder)
                        .lineLimit(3...6)
                    
                    TextField("Tags (comma separated)", text: $viewModel.tags)
                        .textFieldStyle(.roundedBorder)
                    
                    Toggle("Private Video", isOn: $viewModel.isPrivate)
                        .padding(.vertical, 4)
                    
                    Toggle("Allow Comments", isOn: $viewModel.allowComments)
                        .padding(.vertical, 4)
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(12)
                
                // Upload Status
                if viewModel.isUploading {
                    VStack(spacing: 8) {
                        ProgressView(value: viewModel.uploadProgress) {
                            Text("Uploading... \(Int(viewModel.uploadProgress * 100))%")
                        }
                        Text(viewModel.uploadStatus)
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    .padding()
                }
                
                // Error Message
                if let error = viewModel.error {
                    Text(error)
                        .foregroundColor(.red)
                        .font(.caption)
                        .padding()
                }
                
                // Action Button
                if viewModel.selectedVideoURL != nil && !viewModel.isUploading {
                    Button {
                        Task {
                            if mode == .upload {
                                await viewModel.uploadVideo()
                            } else {
                                await viewModel.updateVideo()
                            }
                        }
                    } label: {
                        Text(mode == .upload ? "Upload Video" : "Save Changes")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    .disabled(!viewModel.isValidForm)
                    .padding(.horizontal)
                }
            }
            .padding()
        }
        .navigationTitle(mode == .upload ? "Upload Video" : "Edit Video")
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: viewModel.shouldDismiss) { _, shouldDismiss in
            if shouldDismiss {
                dismiss()
            }
        }
        .onChange(of: viewModel.uploadComplete) { _, complete in
            if complete {
                mode = .edit
            }
        }
    }
} 