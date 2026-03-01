//
//  PostEngagementService.swift
//  Club Ralley
//
//  Service for post engagement operations: likes, comments.
//  Actual posts table columns: id, user_id, content, image_url, ralley_id, likes_count, liked_by (jsonb), created_at
//

import Foundation
import SwiftUI

/**
 * PostEngagementService: Handles post engagement operations
 *
 * Purpose: Manages likes and comments for posts
 * Database: Uses posts.liked_by JSONB column and comments table
 */
// MARK: - Protocol

@MainActor
protocol PostEngagementServiceProtocol: ObservableObject {
    var isLoading: Bool { get }
    func toggleLike(postId: UUID) async throws -> Bool
    func hasLiked(postId: UUID) async -> Bool
    func getLikeCount(postId: UUID) async -> Int
    func loadComments(postId: UUID) async throws -> [PostComment]
    func addComment(postId: UUID, content: String) async throws -> PostComment
    func deleteComment(commentId: UUID) async throws
    func repost(postId: UUID, comment: String?) async throws -> Bool
    func undoRepost(postId: UUID) async throws -> Bool
    func hasReposted(postId: UUID) async throws -> Bool
}

@MainActor
class PostEngagementService: ObservableObject, PostEngagementServiceProtocol {

    // MARK: - Dependencies

    /// Supabase client for database operations
    private let supabase = SupabaseManager.shared

    /// Notification service for creating in-app notifications
    private let notificationService = InAppNotificationService.shared

    // MARK: - Published Properties

    /// Loading state for UI spinners
    @Published var isLoading = false

    /// Last operation error for user feedback
    @Published var lastError: SupabaseManager.SupabaseError?

    // MARK: - Like Operations (Using posts.liked_by JSONB)

    /**
     * Toggle like status for a post
     * Uses posts.liked_by JSONB array
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
            // Load the post to get current liked_by array
            guard let post: PostWithLikes = try await supabase.query("posts")
                .select("id, liked_by, likes_count")
                .eq("id", value: postId)
                .single() else {
                throw SupabaseManager.SupabaseError.networkError("Post not found")
            }

            // Parse current liked_by array
            var likedByArray = post.liked_by ?? []
            let userIdString = currentUser.id.uuidString

            let isLiked: Bool
            if likedByArray.contains(userIdString) {
                // Remove like
                likedByArray.removeAll { $0 == userIdString }
                isLiked = false
                print("PostEngagementService: Removed like for post \(postId)")
            } else {
                // Add like
                likedByArray.append(userIdString)
                isLiked = true
                print("PostEngagementService: Added like for post \(postId)")
            }

            // Update the post with new liked_by array and likes_count
            let update = PostLikesUpdate(
                liked_by: likedByArray,
                likes_count: likedByArray.count
            )

            try await supabase.update(update, in: "posts", where: "id = '\(postId)'")

            // Create notification for like (only if adding a like)
            if isLiked {
                if let fullPost: DatabasePostOwner = try? await supabase.query("posts")
                    .select("user_id")
                    .eq("id", value: postId)
                    .single() {
                    await notificationService.createLikeNotification(postId: postId, postOwnerId: fullPost.user_id)
                }
            }

            return isLiked

        } catch {
            print("PostEngagementService: Like toggle failed: \(error)")
            throw SupabaseManager.SupabaseError.networkError(error.localizedDescription)
        }
    }

    /**
     * Check if current user has liked a post
     * @param postId: Post ID to check
     * @returns: True if user has liked the post
     */
    func hasLiked(postId: UUID) async -> Bool {
        guard let currentUser = supabase.currentUser else { return false }

        do {
            guard let post: PostWithLikes = try await supabase.query("posts")
                .select("id, liked_by")
                .eq("id", value: postId)
                .single() else {
                return false
            }

            let likedByArray = post.liked_by ?? []
            return likedByArray.contains(currentUser.id.uuidString)
        } catch {
            print("PostEngagementService: Check like status failed: \(error)")
            return false
        }
    }

    /**
     * Get like count for a post
     * @param postId: Post ID to get count for
     * @returns: Number of likes
     */
    func getLikeCount(postId: UUID) async -> Int {
        do {
            guard let post: PostWithLikes = try await supabase.query("posts")
                .select("id, likes_count")
                .eq("id", value: postId)
                .single() else {
                return 0
            }

            return post.likes_count
        } catch {
            print("PostEngagementService: Get like count failed: \(error)")
            return 0
        }
    }

    // MARK: - Comment Operations (Using comments table)

    /**
     * Load comments for a specific post
     * @param postId: Post ID to load comments for
     * @returns: Array of comments with user information
     */
    func loadComments(postId: UUID) async throws -> [PostComment] {
        isLoading = true
        lastError = nil

        do {
            let comments = try await supabase.query("comments")
                .select("*, club_users(first_name, last_name, username, profile_photo_url)")
                .eq("post_id", value: postId)
                .order("created_at", ascending: true)
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

            return []
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

            try await supabase.insert(dbComment, into: "comments")

            // Get post owner for notification
            var postOwnerId: UUID?
            if let post: DatabasePostOwner = try? await supabase.query("posts")
                .select("user_id")
                .eq("id", value: postId)
                .single() {
                postOwnerId = post.user_id
            }

            // Create notification for comment
            if let ownerId = postOwnerId {
                await notificationService.createCommentNotification(
                    postId: postId,
                    postOwnerId: ownerId,
                    commentPreview: content
                )
            }

            print("✅ PostEngagementService: Comment added to post \(postId)")

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
            try await supabase.delete(from: "comments", where: "id = '\(commentId)'")
            print("PostEngagementService: Comment \(commentId) deleted")
            isLoading = false
        } catch {
            isLoading = false
            print("PostEngagementService: Delete comment failed: \(error)")
            throw SupabaseManager.SupabaseError.networkError(error.localizedDescription)
        }
    }

    // MARK: - Repost Operations (Using reposts table)

    func repost(postId: UUID, comment: String? = nil) async throws -> Bool {
        guard supabase.isAuthenticated, let currentUser = supabase.currentUser else {
            throw SupabaseManager.SupabaseError.notAuthenticated
        }

        do {
            let repost = DatabaseRepost(
                original_post_id: postId,
                user_id: currentUser.id
            )
            try await supabase.insert(repost, into: "reposts")
            print("✅ PostEngagementService: Reposted post \(postId)")
            return true
        } catch {
            print("❌ PostEngagementService: Repost failed: \(error)")
            throw SupabaseManager.SupabaseError.networkError(error.localizedDescription)
        }
    }

    func undoRepost(postId: UUID) async throws -> Bool {
        guard supabase.isAuthenticated, let currentUser = supabase.currentUser else {
            throw SupabaseManager.SupabaseError.notAuthenticated
        }

        do {
            try await supabase.delete(
                from: "reposts",
                where: "original_post_id = '\(postId)' AND user_id = '\(currentUser.id)'"
            )
            print("✅ PostEngagementService: Undo repost for post \(postId)")
            return true
        } catch {
            print("❌ PostEngagementService: Undo repost failed: \(error)")
            throw SupabaseManager.SupabaseError.networkError(error.localizedDescription)
        }
    }

    func getRepostCount(postId: UUID) async throws -> Int {
        do {
            let reposts: [DatabaseRepost] = try await supabase.query("reposts")
                .select("original_post_id, user_id")
                .eq("original_post_id", value: postId)
                .execute()
            return reposts.count
        } catch {
            print("❌ PostEngagementService: Get repost count failed: \(error)")
            return 0
        }
    }

    func hasReposted(postId: UUID) async throws -> Bool {
        guard let currentUser = supabase.currentUser else { return false }

        do {
            let reposts: [DatabaseRepost] = try await supabase.query("reposts")
                .select("original_post_id, user_id")
                .eq("original_post_id", value: postId)
                .eq("user_id", value: currentUser.id)
                .execute()
            return !reposts.isEmpty
        } catch {
            print("❌ PostEngagementService: Check repost status failed: \(error)")
            return false
        }
    }

    // MARK: - Liker Operations

    /// Fetch users who liked a post
    func getLikers(postId: UUID) async throws -> [PostLiker] {
        do {
            guard let post: PostWithLikes = try await supabase.query("posts")
                .select("id, liked_by")
                .eq("id", value: postId)
                .single() else {
                return []
            }

            let likedByArray = post.liked_by ?? []
            guard !likedByArray.isEmpty else { return [] }

            let likers: [PostLiker] = try await supabase.query("club_users")
                .select("id, first_name, last_name, username, profile_photo_url")
                .in("id", values: likedByArray)
                .execute()

            return likers
        } catch {
            print("PostEngagementService: Get likers failed: \(error)")
            throw SupabaseManager.SupabaseError.networkError(error.localizedDescription)
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
