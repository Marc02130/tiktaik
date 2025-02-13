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
    let onToggleThread: (String) -> Void  // Add toggle callback
    
    var body: some View {
        LazyVStack(alignment: .leading, spacing: 16) {
            ForEach(Array(threads.enumerated()), id: \.element.id) { index, thread in
                VStack(alignment: .leading, spacing: 8) {
                    // Parent comment with tap gesture
                    CommentRow(comment: thread.comment) {
                        onReply(thread.comment)
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        print("DEBUG: Toggling thread \(thread.id) with \(thread.replies.count) replies")
                        onToggleThread(thread.id)
                    }
                    
                    // Show replies if expanded
                    if thread.isExpanded && !thread.replies.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            ForEach(thread.replies) { reply in
                                CommentRow(comment: reply) {
                                    onReply(reply)
                                }
                                .padding(.leading, 32)
                            }
                        }
                    }
                    
                    // Show reply count if collapsed and has replies
                    else if !thread.isExpanded && !thread.replies.isEmpty {
                        Button {
                            print("DEBUG: Expanding thread \(thread.id)")
                            onToggleThread(thread.id)
                        } label: {
                            Text("View \(thread.replies.count) replies")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.leading, 32)
                    }
                }
                
                if index < threads.count - 1 {
                    Divider()
                }
                
                // Load more trigger
                if index == threads.count - 3 && hasMore && !isLoading {
                    ProgressView()
                        .task {
                            await onLoadMore()
                        }
                }
            }
        }
        .padding()
        .onChange(of: threads) { oldValue, newValue in
            print("DEBUG: Threads updated from \(oldValue.count) to \(newValue.count)")
            print("DEBUG: New threads:", newValue.map { "\($0.id): \($0.replies.count) replies" })
        }
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
    ], hasMore: true, isLoading: false, onLoadMore: {}, onReply: { _ in }, onToggleThread: { _ in })
} 