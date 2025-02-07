//
// CommentViewModel.swift
// TIKtAIk
//
// Created: 2024-02-14
// Last modified: 2024-02-14
//
// Purpose: View model for comment management
// Author: Assistant
// Copyright © 2024 TIKtAIk. All rights reserved.
//

import Foundation
import Combine

final class CommentViewModel: ObservableObject {
    @Published private(set) var comments: [Comment] = []
    @Published private(set) var isLoading = false
    @Published private(set) var error: String?
    @Published var newComment = ""
    
    private var videoId: String?
    private let commentService = CommentService()
    
    @MainActor
    func loadComments(for videoId: String) async {
        self.videoId = videoId
        isLoading = true
        error = nil
        
        do {
            comments = try await commentService.fetchComments(videoId: videoId)
        } catch {
            self.error = error.localizedDescription
        }
        
        isLoading = false
    }
    
    @MainActor
    func addComment() async {
        guard let videoId = videoId, !newComment.isEmpty else { return }
        
        do {
            let comment = try await commentService.addComment(videoId: videoId, content: newComment)
            comments.insert(comment, at: 0)
            newComment = ""
        } catch {
            self.error = error.localizedDescription
        }
    }
} 