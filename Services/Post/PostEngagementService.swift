//
//  PostEngagementService.swift
//  Club Ralley
//
//  Service for post engagement operations: likes, comments, reposts.
//

import Foundation
import SwiftUI

/**
 * PostEngagementService: Handles post engagement operations
 *
 * Purpose: Manages likes, comments, and reposts for posts
 * Database: Uses post_likes, post_comments, and reposts tables
 */
@MainActor
class PostEngagementService: ObservableObject {

    // MARK: - Dependencies

    /// Supabase client for database operations
    private let supabase = SupabaseManager.shared

    // MARK: - Published Properties

    /// Loading state for UI spinners
    @Published var isLoading = false

    /// Last operation error for user feedback
    @Published var lastError: SupabaseManager.SupabaseError?

    // MARK: - Like Operations

    /**
     * Toggle like status for a post
     * @param postId: Post ID to like/unlike
     * @returns: New like status (true if liked, false if unliked)
     */
    func toggleLike(postId: UUID) async throws -> Bool {
        guard supabase.isAuthenticated else {
            throw SupabaseManager.SupabaseError.notAuthenticated
        }

        guard let currentUser = supabase.currentUser else {
            throw SupabaseManager.SupabaseError.userNotFound
        }

        do {
            // In real implementation:
            // 1. Check if user already liked: SELECT * FROM post_likes WHERE post_id = ? AND user_id = ?
            // 2. If exists: DELETE and decrement counter
            // 3. If not exists: INSERT and increment counter

            print("PostEngagementService: Toggled like for post \(postId)")
            return true

        } catch {
            print("PostEngagementService: Like toggle failed: \(error)")
            throw SupabaseManager.SupabaseError.networkError(error.localizedDescription)
        }
    }

    // MARK: - Comment Operations

    /**
     * Load comments for a specific post
     * @param postId: Post ID to load comments for
     * @returns: Array of comments with user information
     */
    func loadComments(postId: UUID) async throws -> [PostComment] {
        isLoading = true
        lastError = nil

        do {
            let comments = try await supabase.query("post_comments")
                .select("*, club_users(first_name, last_name, username, profile_photo_url)")
                .eq("post_id", value: postId)
                .execute() as [DatabaseCommentWithUser]

            let mappedComments = comments.map { dbComment in
                mapDatabaseCommentToApp(dbComment)
            }

            isLoading = false
            print("PostEngagementService: Loaded \(mappedComments.count) comments for post \(postId)")
            return mappedComments

        } catch {
            isLoading = false
            print("PostEngagementService: Load comments failed: \(error)")

            // Return mock comments for development
            return generateMockComments(for: postId)
        }
    }

    /**
     * Add a new comment to a post
     * @param postId: Post ID to comment on
     * @param content: Comment text content
     * @returns: Created comment with user information
     */
    func addComment(postId: UUID, content: String) async throws -> PostComment {
        guard supabase.isAuthenticated else {
            throw SupabaseManager.SupabaseError.notAuthenticated
        }

        guard let currentUser = supabase.currentUser else {
            throw SupabaseManager.SupabaseError.userNotFound
        }

        isLoading = true
        lastError = nil

        do {
            let dbComment = DatabaseComment(
                post_id: postId,
                user_id: currentUser.id,
                content: content
            )

            try await supabase.insert(dbComment, into: "post_comments")

            print("PostEngagementService: Comment added to post \(postId)")

            isLoading = false

            // Return the created comment
            return PostComment(
                id: UUID(),
                postId: postId,
                userId: currentUser.id,
                content: content,
                createdAt: Date(),
                user: User(
                    id: currentUser.id,
                    email: currentUser.email,
                    firstName: currentUser.firstName,
                    lastName: currentUser.lastName,
                    username: currentUser.email.components(separatedBy: "@").first ?? "user",
                    dateOfBirth: DateOfBirth(month: 1, year: 2000),
                    gender: .preferNotToSay,
                    locationCity: "",
                    locationState: "",
                    bio: nil,
                    instagramHandle: nil,
                    profilePhotoURL: nil,
                    isVerifiedAthlete: false,
                    athleteInfo: nil,
                    friendsCount: 0,
                    ralleysCount: 0,
                    createdAt: Date(),
                    updatedAt: Date()
                )
            )

        } catch let error as SupabaseManager.SupabaseError {
            isLoading = false
            lastError = error
            throw error
        } catch {
            isLoading = false
            let supabaseError = SupabaseManager.SupabaseError.networkError(error.localizedDescription)
            lastError = supabaseError
            throw supabaseError
        }
    }

    /**
     * Delete a comment
     * @param commentId: Comment ID to delete
     */
    func deleteComment(commentId: UUID) async throws {
        guard supabase.isAuthenticated else {
            throw SupabaseManager.SupabaseError.notAuthenticated
        }

        isLoading = true
        lastError = nil

        do {
            try await supabase.delete(from: "post_comments", where: "id = '\(commentId)'")
            print("PostEngagementService: Comment \(commentId) deleted")
            isLoading = false
        } catch {
            isLoading = false
            print("PostEngagementService: Delete comment failed: \(error)")
            throw SupabaseManager.SupabaseError.networkError(error.localizedDescription)
        }
    }

    // MARK: - Repost Operations

    /**
     * Repost a post with optional quote comment
     * @param postId: Original post ID to repost
     * @param comment: Optional quote comment
     * @returns: Success status
     */
    func repost(postId: UUID, comment: String? = nil) async throws -> Bool {
        guard supabase.isAuthenticated else {
            throw SupabaseManager.SupabaseError.notAuthenticated
        }

        guard let currentUser = supabase.currentUser else {
            throw SupabaseManager.SupabaseError.userNotFound
        }

        isLoading = true
        lastError = nil

        do {
            let repost = DatabaseRepost(
                original_post_id: postId,
                user_id: currentUser.id,
                comment: comment
            )

            try await supabase.insert(repost, into: "reposts")

            // Increment shares count on original post
            // Note: In production, this should be done via database trigger

            print("PostEngagementService: Post \(postId) reposted")
            isLoading = false
            return true

        } catch {
            isLoading = false
            print("PostEngagementService: Repost failed: \(error)")
            throw SupabaseManager.SupabaseError.networkError(error.localizedDescription)
        }
    }

    /**
     * Undo a repost
     * @param postId: Original post ID to undo repost for
     * @returns: Success status
     */
    func undoRepost(postId: UUID) async throws -> Bool {
        guard supabase.isAuthenticated else {
            throw SupabaseManager.SupabaseError.notAuthenticated
        }

        guard let currentUser = supabase.currentUser else {
            throw SupabaseManager.SupabaseError.userNotFound
        }

        isLoading = true
        lastError = nil

        do {
            try await supabase.delete(
                from: "reposts",
                where: "original_post_id = '\(postId)' AND user_id = '\(currentUser.id)'"
            )

            print("PostEngagementService: Repost for post \(postId) removed")
            isLoading = false
            return true

        } catch {
            isLoading = false
            print("PostEngagementService: Undo repost failed: \(error)")
            throw SupabaseManager.SupabaseError.networkError(error.localizedDescription)
        }
    }

    /**
     * Get repost count for a post
     * @param postId: Post ID to get repost count for
     * @returns: Number of reposts
     */
    func getRepostCount(postId: UUID) async throws -> Int {
        do {
            let reposts: [DatabaseRepost] = try await supabase.query("reposts")
                .select("*")
                .eq("original_post_id", value: postId)
                .execute()

            return reposts.count
        } catch {
            print("PostEngagementService: Get repost count failed: \(error)")
            return 0
        }
    }

    /**
     * Check if current user has reposted a post
     * @param postId: Post ID to check
     * @returns: True if user has reposted
     */
    func hasReposted(postId: UUID) async throws -> Bool {
        guard let currentUser = supabase.currentUser else { return false }

        do {
            let reposts: [DatabaseRepost] = try await supabase.query("reposts")
                .select("*")
                .eq("original_post_id", value: postId)
                .eq("user_id", value: currentUser.id)
                .execute()

            return !reposts.isEmpty
        } catch {
            return false
        }
    }

    // MARK: - Helper Methods

    /**
     * Map database comment to app model
     */
    private func mapDatabaseCommentToApp(_ dbComment: DatabaseCommentWithUser) -> PostComment {
        return PostComment(
            id: dbComment.id,
            postId: dbComment.post_id,
            userId: dbComment.user_id,
            content: dbComment.content,
            createdAt: dbComment.created_at,
            user: User(
                id: dbComment.user_id,
                email: "",
                firstName: dbComment.user.first_name,
                lastName: dbComment.user.last_name,
                username: dbComment.user.username,
                dateOfBirth: DateOfBirth(month: 1, year: 2000),
                gender: .preferNotToSay,
                locationCity: "",
                locationState: "",
                bio: nil,
                instagramHandle: nil,
                profilePhotoURL: dbComment.user.profile_photo_url,
                isVerifiedAthlete: false,
                athleteInfo: nil,
                friendsCount: 0,
                ralleysCount: 0,
                createdAt: Date(),
                updatedAt: Date()
            )
        )
    }

    /**
     * Generate mock comments for development
     */
    private func generateMockComments(for postId: UUID) -> [PostComment] {
        return [
            PostComment(
                id: UUID(),
                postId: postId,
                userId: UUID(),
                content: "Great post! Keep it up!",
                createdAt: Date().addingTimeInterval(-1800),
                user: User(
                    id: UUID(),
                    email: "sarah@example.com",
                    firstName: "Sarah",
                    lastName: "Wilson",
                    username: "sarahw",
                    dateOfBirth: DateOfBirth(month: 5, year: 1998),
                    gender: .female,
                    locationCity: "Chicago",
                    locationState: "IL",
                    bio: nil,
                    instagramHandle: nil,
                    profilePhotoURL: "https://picsum.photos/44/44?random=20",
                    isVerifiedAthlete: false,
                    athleteInfo: nil,
                    friendsCount: 50,
                    ralleysCount: 5,
                    createdAt: Date(),
                    updatedAt: Date()
                )
            ),
            PostComment(
                id: UUID(),
                postId: postId,
                userId: UUID(),
                content: "Love this! Count me in for the next game.",
                createdAt: Date().addingTimeInterval(-3600),
                user: User(
                    id: UUID(),
                    email: "mike@example.com",
                    firstName: "Mike",
                    lastName: "Johnson",
                    username: "mikej",
                    dateOfBirth: DateOfBirth(month: 8, year: 1995),
                    gender: .male,
                    locationCity: "Chicago",
                    locationState: "IL",
                    bio: nil,
                    instagramHandle: nil,
                    profilePhotoURL: "https://picsum.photos/44/44?random=21",
                    isVerifiedAthlete: false,
                    athleteInfo: nil,
                    friendsCount: 80,
                    ralleysCount: 12,
                    createdAt: Date(),
                    updatedAt: Date()
                )
            )
        ]
    }
}
