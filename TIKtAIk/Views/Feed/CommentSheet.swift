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
    @StateObject private var viewModel = CommentViewModel()
    @Environment(\.dismiss) private var dismiss
    @FocusState private var isInputFocused: Bool
    @State private var replyingTo: Comment? = nil  // Track which comment we're replying to
    
    var body: some View {
        NavigationStack {
            ZStack {
                if viewModel.isLoading {
                    ProgressView()
                } else if viewModel.commentThreads.isEmpty {
                    VStack {
                        Text("No comments yet")
                            .foregroundStyle(.secondary)
                        Text("Be the first to comment!")
                            .font(.caption)
                    }
                } else {
                    ScrollView {
                        if let error = viewModel.error {
                            ErrorView(error: error) {
                                Task {
                                    await viewModel.loadComments(for: video.id)
                                }
                            }
                        } else {
                            CommentList(
                                threads: viewModel.commentThreads,
                                hasMore: viewModel.hasMoreComments,
                                isLoading: viewModel.isLoading,
                                onLoadMore: {
                                    await viewModel.loadMoreComments()
                                },
                                onReply: { comment in
                                    replyingTo = comment
                                    isInputFocused = true
                                },
                                onToggleThread: { threadId in
                                    viewModel.toggleThread(threadId)
                                }
                            )
                        }
                    }
                    .refreshable {
                        await viewModel.loadComments(for: video.id)
                    }
                }
                
                // Input field at bottom
                VStack {
                    Spacer()
                    commentInputField
                }
            }
            .navigationTitle("\(viewModel.totalCommentCount) Comments")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") { dismiss() }
                }
            }
            .alert("Error", isPresented: $viewModel.showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(viewModel.error ?? "Unknown error")
            }
        }
        .task {
            await viewModel.loadComments(for: video.id)
        }
    }
    
    private var commentInputField: some View {
        VStack(spacing: 8) {
            // Show reply indicator if replying
            if let comment = replyingTo {
                HStack {
                    Text("Replying to comment")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Spacer()
                    
                    Button {
                        replyingTo = nil
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                    }
                }
                .padding(.horizontal)
            }
            
            HStack {
                TextField(replyingTo != nil ? "Add a reply..." : "Add a comment...", 
                         text: $viewModel.newComment)
                    .textFieldStyle(.roundedBorder)
                    .focused($isInputFocused)
                
                Button {
                    Task {
                        if let parentComment = replyingTo {
                            await viewModel.addReply(to: parentComment)
                        } else {
                            await viewModel.addComment()
                        }
                        replyingTo = nil
                        isInputFocused = false
                    }
                } label: {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.title2)
                }
                .disabled(viewModel.newComment.isEmpty)
            }
            .padding()
            .background {
                Rectangle()
                    .fill(.background)
                    .shadow(radius: 2)
            }
        }
    }
}

// Error view component
struct ErrorView: View {
    let error: String
    let retry: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.largeTitle)
                .foregroundStyle(.secondary)
            
            Text(error)
                .multilineTextAlignment(.center)
            
            Button("Try Again") {
                retry()
            }
            .buttonStyle(.bordered)
        }
        .padding()
    }
}
