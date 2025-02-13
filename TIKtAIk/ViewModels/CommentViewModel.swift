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

@MainActor
final class CommentViewModel: ObservableObject {
    @Published private(set) var commentThreads: [CommentThread] = []
    @Published private(set) var isLoading = false
    @Published private(set) var error: String?
    @Published var showError = false
    @Published var newComment = ""
    @Published private(set) var hasMoreComments = true
    @Published private(set) var totalCommentCount = 0
    
    private let service = CommentService()
    private var videoId: String?
    private var lastComment: Comment?
    
    func loadComments(for videoId: String) async {
        self.videoId = videoId
        isLoading = true
        error = nil
        
        do {
            // Get all comments first for the total count
            let allComments = try await service.getAllComments(videoId: videoId)
            totalCommentCount = allComments.count
            
            // Then load paginated threads as before
            let result = try await service.fetchComments(videoId: videoId)
            organizeIntoThreads(result)
            lastComment = result.parents.last
            hasMoreComments = result.parents.count >= service.limit
        } catch {
            self.error = handleError(error)
            showError = true
        }
        
        isLoading = false
    }
    
    private func organizeIntoThreads(_ result: (parents: [Comment], repliesByParent: [String: [Comment]])) {
        print("DEBUG: Organizing threads:")
        print("DEBUG: Parent comments:", result.parents.map { $0.id })
        print("DEBUG: Replies by parent:", result.repliesByParent.mapValues { $0.count })
        
        commentThreads = result.parents.map { parent in
            let threadReplies = result.repliesByParent[parent.id] ?? []
            print("DEBUG: Creating thread for parent \(parent.id) with \(threadReplies.count) replies")
            return CommentThread(
                comment: parent,
                replies: threadReplies,
                isExpanded: false
            )
        }
        
        // Update total count (parents + all replies)
        totalCommentCount = result.parents.count + result.repliesByParent.values.reduce(0) { $0 + $1.count }
        print("DEBUG: Created \(commentThreads.count) threads with total \(totalCommentCount) comments")
    }
    
    func loadMoreComments() async {
        guard let videoId = videoId,
              hasMoreComments,
              !isLoading,
              let last = lastComment else { return }
        
        isLoading = true
        print("DEBUG: Loading more comments after:", last.id)
        
        do {
            let result = try await service.fetchComments(
                videoId: videoId,
                lastComment: last
            )
            print("DEBUG: Loaded additional \(result.parents.count) parent comments")
            
            // Append new threads instead of replacing
            let newThreads = result.parents.map { parent in
                CommentThread(
                    comment: parent,
                    replies: result.repliesByParent[parent.id] ?? [],
                    isExpanded: false
                )
            }
            commentThreads.append(contentsOf: newThreads)
            
            // Update pagination state
            lastComment = result.parents.last
            hasMoreComments = result.parents.count >= service.limit
            
            // Update total count
            totalCommentCount = commentThreads.reduce(0) { count, thread in
                count + 1 + thread.replies.count
            }
        } catch {
            self.error = handleError(error)
            showError = true
        }
        
        isLoading = false
    }
    
    func addComment() async {
        guard let videoId = videoId, !newComment.isEmpty else {
            error = CommentError.invalidContent.localizedDescription
            showError = true
            return
        }
        
        do {
            let comment = try await service.addComment(videoId: videoId, content: newComment)
            // Add new comment as a thread
            commentThreads.insert(
                CommentThread(comment: comment, replies: [], isExpanded: false),
                at: 0
            )
            totalCommentCount += 1  // Increment total count
            newComment = ""
        } catch {
            self.error = handleError(error)
            showError = true
        }
    }
    
    func addReply(to parentComment: Comment) async {
        guard let videoId = videoId, !newComment.isEmpty else {
            error = CommentError.invalidContent.localizedDescription
            showError = true
            return
        }
        
        do {
            let reply = try await service.addReply(to: parentComment, content: newComment)
            
            // Update the thread
            if let index = commentThreads.firstIndex(where: { $0.id == parentComment.id }) {
                var updatedThread = commentThreads[index]
                updatedThread.replies.insert(reply, at: 0)
                updatedThread.comment.replyCount += 1
                commentThreads[index] = updatedThread
                totalCommentCount += 1  // Increment total count
            }
            
            newComment = ""
        } catch {
            self.error = handleError(error)
            showError = true
        }
    }
    
    func toggleThread(_ threadId: String) {
        if let index = commentThreads.firstIndex(where: { $0.id == threadId }) {
            commentThreads[index].isExpanded.toggle()
        }
    }
    
    private func handleError(_ error: Error) -> String {
        if let commentError = error as? CommentError {
            return commentError.localizedDescription
        }
        
        // Map Firebase errors to user-friendly messages
        switch error {
        case let nsError as NSError where nsError.domain == NSURLErrorDomain:
            return CommentError.networkError.localizedDescription
        default:
            return error.localizedDescription
        }
    }
} 