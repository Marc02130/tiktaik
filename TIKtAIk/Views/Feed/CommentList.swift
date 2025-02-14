//
// CommentList.swift
// TIKtAIk
//
// Created: 2024-02-14
// Last modified: 2024-02-14
//
// Purpose: List view for displaying comments
// Author: Assistant
// Copyright © 2024 TIKtAIk. All rights reserved.
//

import SwiftUI

struct CommentList: View {
    let threads: [CommentThread]
    let hasMore: Bool
    let isLoading: Bool
    let onLoadMore: () async -> Void
    let onReply: (Comment) -> Void
    let onToggleThread: (String) -> Void
    let onDelete: (Comment) -> Void
    
    var body: some View {
        LazyVStack(alignment: .leading, spacing: 16) {
            ForEach(threads) { thread in
                VStack {
                    CommentThreadView(
                        thread: thread,
                        onReply: onReply,
                        onToggle: { onToggleThread(thread.id) },
                        onDelete: onDelete
                    )
                    
                    Divider()
                }
            }
            
            if hasMore {
                ProgressView()
                    .onAppear {
                        Task {
                            await onLoadMore()
                        }
                    }
            }
        }
        .padding()
    }
}

#Preview {
    CommentList(threads: [
        CommentThread(comment: Comment(
            id: "1",
            userId: "user1",
            videoId: "video1",
            content: "First comment",
            likesCount: 42,
            replyCount: 5,
            createdAt: Date(),
            updatedAt: Date()
        ), replies: []),
        CommentThread(comment: Comment(
            id: "2",
            userId: "user2",
            videoId: "video1",
            content: "Second comment",
            likesCount: 23,
            replyCount: 2,
            createdAt: Date().addingTimeInterval(-3600),
            updatedAt: Date().addingTimeInterval(-3600)
        ), replies: [])
    ], hasMore: true, isLoading: false, onLoadMore: {}, onReply: { _ in }, onToggleThread: { _ in }, onDelete: { _ in })
} 