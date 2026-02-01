//
//  PostEngagementManager.swift
//  Club Ralley
//
//  ViewModel for managing post engagement: likes, comments, and reposts.
//

import Foundation
import SwiftUI

/**
 * PostEngagementManager: ViewModel for post engagement operations
 *
 * Purpose: Manages likes, comments, and reposts for posts
 * Strategy: Uses PostEngagementService for database operations
 * Usage: Used by PostManager to handle engagement operations
 */
@MainActor
class PostEngagementManager: ObservableObject {

    // MARK: - Published Properties

    /// Comments for the selected post
    @Published var selectedPostComments: [PostComment] = []

    /// Loading state for comments
    @Published var isLoadingComments = false

    /// Error state
    @Published var error: Error?

    // MARK: - Dependencies

    /// Service layer for engagement operations
    private let engagementService = PostEngagementService()

    /// Reference to parent PostManager
    private weak var postManager: PostManager?

    // MARK: - Initialization

    init(postManager: PostManager) {
        self.postManager = postManager
    }

    // MARK: - Like Operations

    /**
     * Toggle like status for a post
     * Updates both database and local cache
     */
    func toggleLike(for postId: UUID) async {
        guard let postManager = postManager,
              let index = postManager.indexOfPost(postId) else { return }

        // Optimistic UI update
        let wasLiked = postManager.posts[index].isLiked
        postManager.posts[index].isLiked.toggle()
        postManager.posts[index].likes += postManager.posts[index].isLiked ? 1 : -1

        print("PostEngagementManager: Optimistic like update for post")

        // Attempt to sync with database
        do {
            let newLikeStatus = try await engagementService.toggleLike(postId: postId)
            postManager.posts[index].isLiked = newLikeStatus
            print("PostEngagementManager: Like synced with database")

        } catch {
            print("PostEngagementManager: Failed to sync like with database: \(error)")

            // Revert optimistic update on failure
            postManager.posts[index].isLiked = wasLiked
            postManager.posts[index].likes += wasLiked ? 1 : -1
            self.error = error
        }
    }

    // MARK: - Comment Operations

    /**
     * Load comments for a specific post
     */
    func loadComments(for postId: UUID) async {
        isLoadingComments = true

        do {
            let comments = try await engagementService.loadComments(postId: postId)
            selectedPostComments = comments
            print("PostEngagementManager: Loaded \(comments.count) comments")
        } catch {
            print("PostEngagementManager: Failed to load comments: \(error)")
            self.error = error
        }

        isLoadingComments = false
    }

    /**
     * Add a comment to a post
     */
    func addComment(to postId: UUID, content: String) async {
        guard !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return
        }

        do {
            let newComment = try await engagementService.addComment(postId: postId, content: content)

            // Add to local cache
            selectedPostComments.insert(newComment, at: 0)

            // Update post comment count
            if let postManager = postManager,
               let index = postManager.indexOfPost(postId) {
                postManager.posts[index].comments += 1
            }

            print("PostEngagementManager: Comment added")
        } catch {
            print("PostEngagementManager: Failed to add comment: \(error)")
            self.error = error
        }
    }

    /**
     * Delete a comment from a post
     */
    func deleteComment(_ commentId: UUID, from postId: UUID) async {
        // Optimistic update
        let originalComments = selectedPostComments
        selectedPostComments.removeAll { $0.id == commentId }

        // Update post comment count
        if let postManager = postManager,
           let index = postManager.indexOfPost(postId) {
            postManager.posts[index].comments -= 1
        }

        do {
            try await engagementService.deleteComment(commentId: commentId)
            print("PostEngagementManager: Comment deleted")
        } catch {
            // Revert on failure
            selectedPostComments = originalComments
            if let postManager = postManager,
               let index = postManager.indexOfPost(postId) {
                postManager.posts[index].comments += 1
            }
            print("PostEngagementManager: Failed to delete comment: \(error)")
            self.error = error
        }
    }

    // MARK: - Repost Operations

    /**
     * Repost a post with optional quote comment
     */
    func repost(postId: UUID, comment: String? = nil) async -> Bool {
        guard let postManager = postManager,
              let index = postManager.indexOfPost(postId) else { return false }

        do {
            let success = try await engagementService.repost(postId: postId, comment: comment)

            if success {
                // Update local state
                postManager.posts[index].isReposted = true
                postManager.posts[index].shares += 1
                print("PostEngagementManager: Post reposted")
            }

            return success

        } catch {
            print("PostEngagementManager: Failed to repost: \(error)")
            self.error = error
            return false
        }
    }

    /**
     * Undo a repost
     */
    func undoRepost(postId: UUID) async -> Bool {
        guard let postManager = postManager,
              let index = postManager.indexOfPost(postId) else { return false }

        do {
            let success = try await engagementService.undoRepost(postId: postId)

            if success {
                // Update local state
                postManager.posts[index].isReposted = false
                postManager.posts[index].shares = max(0, postManager.posts[index].shares - 1)
                print("PostEngagementManager: Repost undone")
            }

            return success

        } catch {
            print("PostEngagementManager: Failed to undo repost: \(error)")
            self.error = error
            return false
        }
    }

    /**
     * Toggle repost status
     */
    func toggleRepost(for postId: UUID, comment: String? = nil) async -> Bool {
        guard let postManager = postManager,
              let index = postManager.indexOfPost(postId) else { return false }

        if postManager.posts[index].isReposted {
            return await undoRepost(postId: postId)
        } else {
            return await repost(postId: postId, comment: comment)
        }
    }

    /**
     * Check if current user has reposted a post
     */
    func hasReposted(postId: UUID) async -> Bool {
        do {
            return try await engagementService.hasReposted(postId: postId)
        } catch {
            return false
        }
    }

    // MARK: - Clear State

    /**
     * Clear comments when dismissing comment sheet
     */
    func clearComments() {
        selectedPostComments = []
    }

    /**
     * Clear error state
     */
    func clearError() {
        error = nil
    }
}
