//
// CommentRow.swift
// TIKtAIk
//
// Created: 2024-02-14
// Last modified: 2024-02-14
//
// Purpose: Row view for displaying a single comment
// Author: Assistant
// Copyright © 2024 TIKtAIk. All rights reserved.
//

import SwiftUI
import FirebaseAuth

extension View {
    func debugLog(_ message: String) -> some View {
        print(message)
        return self
    }
}

struct CommentRow: View {
    let comment: Comment
    let onReply: () -> Void
    let onDelete: () -> Void
    let onToggle: (() -> Void)?  // Optional toggle handler
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Reply indicator if needed
            if comment.parentId != nil {
                Text("Reply")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Text(comment.content)
                .font(.body)
            
            HStack(spacing: 12) {
                // Like count
                Label("\(comment.likesCount)", systemImage: "heart")
                    .font(.caption)
                
                // Reply count if top-level comment
                if comment.parentId == nil {
                    Label("\(comment.replyCount)", systemImage: "bubble.right")
                        .font(.caption)
                        .onTapGesture {
                            onToggle?()  // Only toggle when tapping reply count
                        }
                    
                    Text("•")
                    
                    // Only show reply button for parent comments
                    Button {
                        onReply()
                    } label: {
                        Image(systemName: "arrowshape.turn.up.left")
                            .font(.caption)
                    }
                }
                
                Spacer()
                
                // Relative timestamp
                Text(comment.createdAt, style: .relative)
                    .font(.caption)
            }
            .foregroundStyle(.secondary)
        }
        .padding(.horizontal)
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            if comment.userId == Auth.auth().currentUser?.uid {
                Button(role: .destructive) {
                    print("DEBUG: Delete button tapped for comment \(comment.id)")
                    onDelete()
                } label: {
                    Label("Delete", systemImage: "trash")
                }
            }
        }
        .onAppear {
            print("DEBUG: CommentRow appeared for comment \(comment.id)")
        }
    }
}

#Preview {
    CommentRow(
        comment: Comment(
            id: "1",
            userId: "user1",
            videoId: "video1",
            parentId: nil,
            content: "This is a test comment",
            likesCount: 42,
            replyCount: 5,
            createdAt: Date(),
            updatedAt: Date()
        ),
        onReply: {},
        onDelete: {},
        onToggle: nil
    )
} 