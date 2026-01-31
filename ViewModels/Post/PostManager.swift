//
//  PostManager.swift
//  Club Ralley
//
//  ViewModel for managing post data and operations.
//  Handles loading, creating, and engaging with posts.
//

import Foundation
import SwiftUI

/**
 * PostManager: ViewModel for post operations
 *
 * Purpose: Manages post data for UI consumption and user actions
 * Strategy: Uses PostService for database operations, maintains local cache
 * Usage: Injected as @EnvironmentObject into HomeFeedView and related views
 */
@MainActor
class PostManager: ObservableObject {

    // MARK: - Published Properties

    /// All posts for home feed and user profiles
    @Published var posts: [ClubRalleyPost] = []

    /// Loading state for UI feedback
    @Published var isLoading = false

    /// Error state for user notifications
    @Published var error: Error?

    /// Comments for the selected post
    @Published var selectedPostComments: [PostComment] = []

    /// Loading state for comments
    @Published var isLoadingComments = false

    // MARK: - Dependencies

    /// Service layer for post database operations
    private let postService = PostService()

    /// Supabase authentication state
    private let supabase = SupabaseManager.shared

    // MARK: - Initialization

    init() {
        // Load posts from backend on startup
        Task {
            await loadPosts()
        }
    }

    // MARK: - Post Loading

    /**
     * Load posts from Supabase database for home feed
     * Handles both real data and fallback to mock data for development
     */
    func loadPosts() async {
        isLoading = true
        error = nil

        do {
            let loadedPosts = try await postService.loadHomeFeedPosts()
            posts = loadedPosts
            print("✅ PostManager: Loaded \(loadedPosts.count) posts from backend")
        } catch {
            print("❌ PostManager: Failed to load posts: \(error)")
            self.error = error

            // Fallback to sample posts for development
            await loadSamplePosts()
        }

        isLoading = false
    }

    /**
     * Load sample posts for development and offline scenarios
     * Ensures app remains functional even without backend connectivity
     */
    private func loadSamplePosts() async {
        let samplePosts = [
            ClubRalleyPost(
                id: UUID(),
                authorName: "Ryan Smith",
                authorUsername: "@rsmith",
                authorPhotoURL: "https://picsum.photos/50/50?random=10",
                authorSchool: "Texas A&M",
                authorLocation: "Chicago, IL",
                authorSport: "soccer",
                title: "Tennis Match",
                content: "I need a hitting partner for tomorrow afternoon. Send help!",
                images: [],
                timestamp: Date().addingTimeInterval(-86400), // Today/1 day ago
                likes: 24,
                comments: 8,
                shares: 3,
                isLiked: false
            ),
            ClubRalleyPost(
                id: UUID(),
                authorName: "Gracie King",
                authorUsername: "@gking",
                authorPhotoURL: "https://picsum.photos/50/50?random=11",
                authorSchool: "Bucknell University",
                authorLocation: "Chicago, IL",
                authorSport: "tennis",
                title: nil,
                content: "Had an amazing session on the courts today! The weather was perfect and my serve is finally coming together.",
                images: ["https://picsum.photos/600/400?random=tennis1"],
                timestamp: Date().addingTimeInterval(-172800), // 2 days ago
                likes: 45,
                comments: 12,
                shares: 5,
                isLiked: true
            ),
            ClubRalleyPost(
                id: UUID(),
                authorName: "Mike Johnson",
                authorUsername: "@mikej",
                authorPhotoURL: "https://picsum.photos/50/50?random=12",
                authorSchool: "Duke University",
                authorLocation: "Chicago, IL",
                authorSport: "basketball",
                title: "Pickup Game Tonight",
                content: "Looking for 2 more players for basketball at 6pm. Riverside Park courts. All skill levels welcome!",
                images: [],
                timestamp: Date().addingTimeInterval(-7200), // 2 hours ago
                likes: 15,
                comments: 8,
                shares: 1,
                isLiked: false
            )
        ]

        posts = samplePosts
        print("📱 PostManager: Using sample posts (fallback mode)")
    }

    // MARK: - Post Creation

    /**
     * Create new post and save to database
     * @param content: Post text content
     * @param title: Optional post title
     * @param images: Array of image URLs
     *
     * Flow: Create local post -> Save to database -> Update local cache
     */
    func createPost(content: String, title: String? = nil, images: [String] = []) async {
        guard !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            print("❌ PostManager: Cannot create post with empty content")
            return
        }

        isLoading = true
        error = nil

        // Create local post model with current user info
        let newPost = ClubRalleyPost(
            id: UUID(),
            authorName: supabase.currentUser?.displayName ?? "Your Name",
            authorUsername: "@\(supabase.currentUser?.email.components(separatedBy: "@").first ?? "you")",
            authorPhotoURL: "https://picsum.photos/50/50?random=50",
            authorSchool: "University", // TODO: Get from user profile
            authorLocation: "Chicago, IL", // TODO: Get from user profile
            authorSport: "athlete", // TODO: Get from user profile
            title: title?.isEmpty == false ? title : nil,
            content: content,
            images: images,
            timestamp: Date(),
            likes: 0,
            comments: 0,
            shares: 0,
            isLiked: false
        )

        do {
            // Save to database via PostService
            let createdPost = try await postService.createPost(newPost)

            // Add to local cache at the top of feed
            posts.insert(createdPost, at: 0)

            print("✅ PostManager: Post created successfully")

        } catch {
            print("❌ PostManager: Failed to create post: \(error)")
            self.error = error

            // Even if backend fails, add to local cache for immediate UI feedback
            posts.insert(newPost, at: 0)
            print("📱 PostManager: Post added locally (backend failed)")
        }

        isLoading = false
    }

    // MARK: - Post Engagement

    /**
     * Toggle like status for a post
     * Updates both database and local cache
     * @param postId: ID of post to like/unlike
     */
    func toggleLike(for postId: UUID) async {
        // Optimistic UI update - change local state immediately
        if let index = posts.firstIndex(where: { $0.id == postId }) {
            let wasLiked = posts[index].isLiked
            posts[index].isLiked.toggle()
            posts[index].likes += posts[index].isLiked ? 1 : -1

            print("❤️ PostManager: Optimistic like update for post")

            // Attempt to sync with database
            do {
                let newLikeStatus = try await postService.toggleLike(postId: postId)

                // Update local state to match database response
                // (In case there was a conflict or different result)
                posts[index].isLiked = newLikeStatus
                print("✅ PostManager: Like synced with database")

            } catch {
                print("❌ PostManager: Failed to sync like with database: \(error)")

                // Revert optimistic update on failure
                posts[index].isLiked = wasLiked
                posts[index].likes += wasLiked ? 1 : -1
                self.error = error
            }
        }
    }

    /**
     * Legacy method for immediate UI updates (maintains backward compatibility)
     * @param post: Full post model to add to feed
     */
    func addPost(_ post: ClubRalleyPost) {
        posts.insert(post, at: 0) // Add to beginning of feed
        print("📝 PostManager: Post added to local feed")
    }

    // MARK: - User Content Filtering

    /**
     * Get posts created by current user for profile display
     * @returns: Array of user's posts sorted by creation date
     */
    func getUserPosts() -> [ClubRalleyPost] {
        let currentUserName = supabase.currentUser?.displayName ?? "Your Name"
        let userPosts = posts.filter { $0.authorName == currentUserName }

        print("👤 PostManager: Found \(userPosts.count) posts for current user")
        return userPosts.sorted { $0.timestamp > $1.timestamp }
    }

    /**
     * Get posts for specific user (for viewing other profiles)
     * @param username: Username to filter posts by
     * @returns: Array of user's posts
     */
    func getPostsForUser(username: String) -> [ClubRalleyPost] {
        return posts.filter { $0.authorUsername == username }
            .sorted { $0.timestamp > $1.timestamp }
    }

    // MARK: - Feed Management

    /**
     * Refresh posts by reloading from database
     * Used for pull-to-refresh functionality
     */
    func refreshPosts() async {
        print("🔄 PostManager: Refreshing posts from database")
        await loadPosts()
    }

    /**
     * Clear error state (for user notification dismissal)
     */
    func clearError() {
        error = nil
    }

    // MARK: - Comment Operations

    /**
     * Load comments for a specific post
     * @param postId: ID of post to load comments for
     */
    func loadComments(for postId: UUID) async {
        isLoadingComments = true

        do {
            let comments = try await postService.loadComments(postId: postId)
            selectedPostComments = comments
            print("✅ PostManager: Loaded \(comments.count) comments")
        } catch {
            print("❌ PostManager: Failed to load comments: \(error)")
            self.error = error
        }

        isLoadingComments = false
    }

    /**
     * Add a comment to a post
     * @param postId: ID of post to comment on
     * @param content: Comment text
     */
    func addComment(to postId: UUID, content: String) async {
        guard !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return
        }

        do {
            let newComment = try await postService.addComment(postId: postId, content: content)

            // Add to local cache
            selectedPostComments.insert(newComment, at: 0)

            // Update post comment count
            if let index = posts.firstIndex(where: { $0.id == postId }) {
                posts[index].comments += 1
            }

            print("✅ PostManager: Comment added")
        } catch {
            print("❌ PostManager: Failed to add comment: \(error)")
            self.error = error
        }
    }

    /**
     * Delete a comment from a post
     * @param commentId: ID of comment to delete
     * @param postId: ID of post the comment belongs to
     */
    func deleteComment(_ commentId: UUID, from postId: UUID) async {
        // Optimistic update
        let originalComments = selectedPostComments
        selectedPostComments.removeAll { $0.id == commentId }

        // Update post comment count
        if let index = posts.firstIndex(where: { $0.id == postId }) {
            posts[index].comments -= 1
        }

        do {
            try await postService.deleteComment(commentId: commentId)
            print("✅ PostManager: Comment deleted")
        } catch {
            // Revert on failure
            selectedPostComments = originalComments
            if let index = posts.firstIndex(where: { $0.id == postId }) {
                posts[index].comments += 1
            }
            print("❌ PostManager: Failed to delete comment: \(error)")
            self.error = error
        }
    }

    // MARK: - Post Management

    /**
     * Delete a post
     * @param postId: ID of post to delete
     */
    func deletePost(_ postId: UUID) async {
        // Optimistic update
        let originalPosts = posts
        posts.removeAll { $0.id == postId }

        do {
            try await postService.deletePost(postId)
            print("✅ PostManager: Post deleted")
        } catch {
            // Revert on failure
            posts = originalPosts
            print("❌ PostManager: Failed to delete post: \(error)")
            self.error = error
        }
    }

    /**
     * Report a post for inappropriate content
     * @param postId: ID of post to report
     * @param reason: Reason for reporting
     */
    func reportPost(_ postId: UUID, reason: String) async {
        do {
            try await postService.reportPost(postId, reason: reason)
            print("✅ PostManager: Post reported")
        } catch {
            print("❌ PostManager: Failed to report post: \(error)")
            self.error = error
        }
    }
}
