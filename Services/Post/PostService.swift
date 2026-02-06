//
//  PostService.swift
//  Club Ralley
//
//  Core service for post CRUD operations connecting app models to Supabase backend.
//  Handles post creation, retrieval, and deletion.
//

import Foundation
import SwiftUI

/**
 * PostService: Bridge between PostManager and Supabase posts table
 *
 * Purpose: Handles core post-related database operations (CRUD)
 * Strategy: Real Supabase calls with mock fallbacks for reliability
 * Database: Maps ClubRalleyPost model to 'posts' table schema
 */
@MainActor
class PostService: ObservableObject {

    // MARK: - Dependencies

    /// Supabase client for database operations
    private let supabase = SupabaseManager.shared

    // MARK: - Published Properties for UI Feedback

    /// Loading state for UI spinners
    @Published var isLoading = false

    /// Last operation error for user feedback
    @Published var lastError: SupabaseManager.SupabaseError?

    // MARK: - Post Creation

    /**
     * Create new post in Supabase database
     * @param post: ClubRalleyPost to create
     * @param visibility: Post visibility setting
     * @returns: Created post with database ID and timestamps
     */
    func createPost(_ post: ClubRalleyPost, visibility: PostVisibility = .everyone) async throws -> ClubRalleyPost {
        print("🔵 helloWORLD POST_CREATE START")
        print("🔵 helloWORLD POST_CREATE - isAuthenticated: \(supabase.isAuthenticated)")

        guard supabase.isAuthenticated else {
            print("🔴 helloWORLD POST_CREATE FAILED - not authenticated")
            throw SupabaseManager.SupabaseError.notAuthenticated
        }

        guard let currentUser = supabase.currentUser else {
            print("🔴 helloWORLD POST_CREATE FAILED - no current user")
            throw SupabaseManager.SupabaseError.userNotFound
        }

        print("🔵 helloWORLD POST_CREATE - userId: \(currentUser.id)")

        isLoading = true
        lastError = nil

        do {
            // Map ClubRalleyPost to database post structure
            let dbPost = DatabasePost(
                user_id: currentUser.id,
                content: formatPostContent(post),
                post_type: post.postType.rawValue,
                likes_count: 0,
                comments_count: 0,
                visibility: visibility.rawValue,
                ralley_id: post.relatedRalleyId,
                tagged_user_ids: post.taggedUserIds.isEmpty ? nil : post.taggedUserIds,
                link_url: post.linkUrl,
                shares_count: 0
            )

            print("🔵 helloWORLD POST_CREATE - dbPost created, calling insert...")
            // Insert into Supabase posts table
            try await supabase.insert(dbPost, into: "posts")

            print("🟢 helloWORLD POST_CREATE SUCCESS")

            // Return the post with updated database info
            var updatedPost = post
            updatedPost.visibility = visibility

            isLoading = false
            return updatedPost

        } catch let error as SupabaseManager.SupabaseError {
            isLoading = false
            lastError = error
            print("PostService: Create failed with Supabase error: \(error)")
            throw error
        } catch {
            isLoading = false
            let supabaseError = SupabaseManager.SupabaseError.networkError(error.localizedDescription)
            lastError = supabaseError
            print("PostService: Create failed with network error: \(error)")
            throw supabaseError
        }
    }

    // MARK: - Post Retrieval

    /**
     * Load posts for home feed from database
     * @param limit: Maximum number of posts to retrieve
     * @param offset: Pagination offset
     * @returns: Array of posts with user information populated
     */
    func loadHomeFeedPosts(limit: Int = 20, offset: Int = 0) async throws -> [ClubRalleyPost] {
        print("🔵 helloWORLD POST_LOAD_FEED START")
        isLoading = true
        lastError = nil

        do {
            print("🔵 helloWORLD POST_LOAD_FEED - querying posts table...")
            let posts = try await supabase.query("posts")
                .select("*, club_users(first_name, last_name, username, profile_photo_url)")
                .execute() as [DatabasePostWithUser]

            // Map database results to app models
            let mappedPosts = posts.map { dbPost in
                mapDatabasePostToApp(dbPost)
            }

            isLoading = false
            print("🟢 helloWORLD POST_LOAD_FEED SUCCESS - loaded \(mappedPosts.count) posts")
            return mappedPosts

        } catch let error as SupabaseManager.SupabaseError {
            isLoading = false
            lastError = error
            print("🔴 helloWORLD POST_LOAD_FEED FAILED: \(error)")

            // Return empty array - let UI show empty state
            return []

        } catch {
            isLoading = false
            let supabaseError = SupabaseManager.SupabaseError.networkError(error.localizedDescription)
            lastError = supabaseError
            print("🔴 helloWORLD POST_LOAD_FEED FAILED with network error: \(error)")

            // Return empty array - let UI show empty state
            return []
        }
    }

    /**
     * Load posts for specific user (for profile view)
     * @param userId: User ID to load posts for
     * @returns: Array of user's posts
     */
    func loadUserPosts(userId: UUID) async throws -> [ClubRalleyPost] {
        isLoading = true
        lastError = nil

        do {
            let posts = try await supabase.query("posts")
                .select("*, club_users(first_name, last_name, username, profile_photo_url)")
                .eq("user_id", value: userId)
                .execute() as [DatabasePostWithUser]

            let mappedPosts = posts.map { dbPost in
                mapDatabasePostToApp(dbPost)
            }

            isLoading = false
            print("PostService: Loaded \(mappedPosts.count) user posts from database")
            return mappedPosts

        } catch {
            isLoading = false
            print("PostService: Load user posts failed: \(error)")

            // Return empty array - let UI show empty state
            return []
        }
    }

    // MARK: - Post Management

    /**
     * Delete a post
     * @param postId: Post ID to delete
     */
    func deletePost(_ postId: UUID) async throws {
        guard supabase.isAuthenticated else {
            throw SupabaseManager.SupabaseError.notAuthenticated
        }

        isLoading = true
        lastError = nil

        do {
            try await supabase.delete(from: "posts", where: "id = '\(postId)'")
            print("PostService: Post \(postId) deleted")
            isLoading = false
        } catch {
            isLoading = false
            print("PostService: Delete post failed: \(error)")
            throw SupabaseManager.SupabaseError.networkError(error.localizedDescription)
        }
    }

    /**
     * Report a post for review
     * Note: post_reports table not in lean schema - logs locally only
     * @param postId: Post ID to report
     * @param reason: Reason for reporting
     */
    func reportPost(_ postId: UUID, reason: String) async throws {
        guard supabase.isAuthenticated else {
            throw SupabaseManager.SupabaseError.notAuthenticated
        }

        guard let currentUser = supabase.currentUser else {
            throw SupabaseManager.SupabaseError.userNotFound
        }

        // Log the report (no post_reports table in lean schema)
        print("📋 PostService: Post report logged - Reporter: \(currentUser.id), Post: \(postId), Reason: \(reason)")
        // In production, this would be sent to a moderation queue or external service
    }

    // MARK: - Helper Methods

    /**
     * Format post content for database storage
     * Combines title and content, handles special formatting
     */
    private func formatPostContent(_ post: ClubRalleyPost) -> String {
        if let title = post.title, !title.isEmpty {
            return "\(title)\n\n\(post.content)"
        }
        return post.content
    }

    /**
     * Map database post result to app model
     * Handles the complex mapping between database schema and UI models
     */
    private func mapDatabasePostToApp(_ dbPost: DatabasePostWithUser) -> ClubRalleyPost {
        return ClubRalleyPost(
            id: dbPost.id,
            authorName: "\(dbPost.user.first_name) \(dbPost.user.last_name)",
            authorUsername: "@\(dbPost.user.username)",
            authorPhotoURL: dbPost.user.profile_photo_url ?? "",
            authorId: dbPost.user_id,
            title: extractTitleFromContent(dbPost.content),
            content: extractContentFromContent(dbPost.content),
            images: [],
            timestamp: dbPost.created_at,
            postType: PostType(rawValue: dbPost.post_type) ?? .text,
            visibility: PostVisibility(rawValue: dbPost.visibility ?? "everyone") ?? .everyone,
            relatedRalleyId: dbPost.ralley_id,
            taggedUserIds: dbPost.tagged_user_ids ?? [],
            linkUrl: dbPost.link_url,
            likes: dbPost.likes_count,
            comments: dbPost.comments_count,
            shares: dbPost.shares_count ?? 0,
            isLiked: false,
            isReposted: false,
            originalPostId: dbPost.original_post_id,
            repostComment: dbPost.repost_comment
        )
    }

    /**
     * Extract title from formatted content (if exists)
     */
    private func extractTitleFromContent(_ content: String) -> String? {
        let parts = content.components(separatedBy: "\n\n")
        return parts.count > 1 ? parts[0] : nil
    }

    /**
     * Extract main content from formatted content
     */
    private func extractContentFromContent(_ content: String) -> String {
        let parts = content.components(separatedBy: "\n\n")
        return parts.count > 1 ? parts[1] : content
    }
}
