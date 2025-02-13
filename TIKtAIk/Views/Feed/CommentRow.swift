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

struct CommentRow: View {
    let comment: Comment
    let onReply: () -> Void  // Add callback for reply action
    
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
    }
}

#Preview {
    CommentRow(comment: Comment(
        id: "1",
        userId: "user1",
        videoId: "video1",
        parentId: nil,
        content: "This is a test comment",
        likesCount: 42,
        replyCount: 5,
        createdAt: Date(),
        updatedAt: Date()
    )) {
        // Implementation of onReply
    }
} 