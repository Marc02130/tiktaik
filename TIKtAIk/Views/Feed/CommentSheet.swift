//
// CommentSheet.swift
// TIKtAIk
//
// Created: 2024-02-14
// Last modified: 2024-02-14
//
// Purpose: Comment sheet for videos
// Author: Assistant
// Copyright © 2024 TIKtAIk. All rights reserved.
//

import SwiftUI

struct CommentSheet: View {
    let video: Video
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = CommentViewModel()
    @FocusState private var isInputFocused: Bool
    
    var body: some View {
        NavigationStack {
            VStack {
                if viewModel.isLoading {
                    ProgressView()
                } else {
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 16) {
                            ForEach(viewModel.comments) { comment in
                                CommentRow(comment: comment)
                            }
                        }
                        .padding()
                    }
                }
                
                Divider()
                
                // Comment input
                HStack {
                    TextField("Add a comment...", text: $viewModel.newComment)
                        .textFieldStyle(.roundedBorder)
                        .focused($isInputFocused)
                    
                    Button {
                        Task {
                            await viewModel.addComment()
                            isInputFocused = false
                        }
                    } label: {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.title2)
                    }
                    .disabled(viewModel.newComment.isEmpty)
                }
                .padding()
            }
            .navigationTitle("Comments")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
        .task {
            await viewModel.loadComments(for: video.id)
        }
    }
}

struct CommentRow: View {
    let comment: Comment
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(comment.content)
                .font(.body)
            
            HStack {
                Text("\(comment.likesCount) likes")
                Text("•")
                Text(comment.createdAt, style: .relative)
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
    }
} 