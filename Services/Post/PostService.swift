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
// MARK: - Protocol

@MainActor
protocol PostServiceProtocol: ObservableObject {
    var isLoading: Bool { get }
    var lastError: SupabaseManager.SupabaseError? { get }
    func createPost(_ post: ClubRalleyPost, visibility: PostVisibility) async throws -> ClubRalleyPost
    func loadHomeFeedPosts(limit: Int, offset: Int) async throws -> [ClubRalleyPost]
    func loadMorePosts(currentCount: Int, limit: Int) async throws -> [ClubRalleyPost]
    func loadUserPosts(userId: UUID) async throws -> [ClubRalleyPost]
    func deletePost(_ postId: UUID) async throws
    func reportPost(_ postId: UUID, reason: String) async throws
}

@MainActor
class PostService: ObservableObject, PostServiceProtocol {

    // MARK: - Dependencies

    /// Supabase client for database operations
    private let supabase = SupabaseManager.shared

    /// Friendship service for block filtering
    private let friendshipService: FriendshipService

    /// Shared blocked user state
    private let sharedUserState: SharedUserState

    // MARK: - Published Properties for UI Feedback

    /// Loading state for UI spinners
    @Published var isLoading = false

    /// Last operation error for user feedback
    @Published var lastError: SupabaseManager.SupabaseError?

    // MARK: - Initialization

    init(friendshipService: FriendshipService, sharedUserState: SharedUserState) {
        self.friendshipService = friendshipService
        self.sharedUserState = sharedUserState
    }

    convenience init() {
        let fs = FriendshipService()
        self.init(friendshipService: fs, sharedUserState: SharedUserState(friendshipService: fs))
    }

    // MARK: - Post Creation

    /**
     * Create new post in Supabase database
     * @param post: ClubRalleyPost to create
     * @param visibility: Post visibility setting
     * @returns: Created post with database ID and timestamps
     */
    func createPost(_ post: ClubRalleyPost, visibility: PostVisibility = .everyone) async throws -> ClubRalleyPost {
        guard supabase.isAuthenticated else {
            throw SupabaseManager.SupabaseError.notAuthenticated
        }

        guard let currentUser = supabase.currentUser else {
            throw SupabaseManager.SupabaseError.userNotFound
        }

        isLoading = true
        lastError = nil

        do {
            // Map ClubRalleyPost to database post structure
            let dbPost = DatabasePost(
                user_id: currentUser.id,
                content: formatPostContent(post),
                ralley_id: post.relatedRalleyId,
                image_url: post.images.first,
                post_type: post.postType.rawValue,
                sport: post.authorSport
            )

            // Insert into Supabase posts table
            try await supabase.insert(dbPost, into: "posts")

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
     * Filters out posts from blocked users
     * @param limit: Maximum number of posts to retrieve
     * @param offset: Pagination offset
     * @returns: Array of posts with user information populated
     */
    func loadHomeFeedPosts(limit: Int = 20, offset: Int = 0) async throws -> [ClubRalleyPost] {
        isLoading = true
        lastError = nil

        do {
            // Refresh blocked users cache if needed (every 5 minutes)
            await sharedUserState.refreshBlockedUsersIfNeeded()

            let posts = try await supabase.query("posts")
                .select("*, club_users(first_name, last_name, username, profile_photo_url)")
                .order("created_at", ascending: false)
                .range(from: offset, to: offset + limit - 1)
                .execute() as [DatabasePostWithUser]

            // Map database results to app models and filter blocked users
            let mappedPosts = posts
                .filter { !self.sharedUserState.isBlocked($0.user_id) }
                .map { dbPost in
                    mapDatabasePostToApp(dbPost)
                }

            isLoading = false
            print("✅ PostService: Loaded \(mappedPosts.count) posts (offset: \(offset), filtered \(posts.count - mappedPosts.count) blocked)")
            return mappedPosts

        } catch let error as SupabaseManager.SupabaseError {
            isLoading = false
            lastError = error
            print("❌ PostService: Load feed failed: \(error)")
            throw error

        } catch {
            isLoading = false
            let supabaseError = SupabaseManager.SupabaseError.networkError(error.localizedDescription)
            lastError = supabaseError
            print("❌ PostService: Load feed failed with network error: \(error)")
            throw supabaseError
        }
    }

    /**
     * Load more posts for infinite scroll
     * @param currentCount: Current number of posts loaded
     * @param limit: Number of additional posts to load
     * @returns: Array of additional posts
     */
    func loadMorePosts(currentCount: Int, limit: Int = 20) async throws -> [ClubRalleyPost] {
        return try await loadHomeFeedPosts(limit: limit, offset: currentCount)
    }

    /// Force refresh of blocked users cache
    func refreshBlockedUsers() async {
        await sharedUserState.forceRefresh()
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
            throw error
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
     * @param postId: Post ID to report
     * @param reason: Reason for reporting
     */
    func reportPost(_ postId: UUID, reason: String) async throws {
        let reportService = ReportService()

        // Map string reason to ReportReason enum
        let reportReason: ReportReason
        switch reason.lowercased() {
        case let r where r.contains("spam"):
            reportReason = .spam
        case let r where r.contains("harass"):
            reportReason = .harassment
        case let r where r.contains("hate"):
            reportReason = .hateSpeech
        case let r where r.contains("violen"):
            reportReason = .violence
        case let r where r.contains("inappropriate"):
            reportReason = .inappropriate
        case let r where r.contains("impersonat"):
            reportReason = .impersonation
        default:
            reportReason = .other
        }

        try await reportService.reportPost(postId, reason: reportReason, additionalContext: reason)
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
            authorSport: dbPost.sport,
            title: extractTitleFromContent(dbPost.content),
            content: extractContentFromContent(dbPost.content),
            images: dbPost.image_url.map { [$0] } ?? [],
            timestamp: dbPost.created_at,
            postType: PostType(rawValue: dbPost.resolvedPostType) ?? .text,
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
