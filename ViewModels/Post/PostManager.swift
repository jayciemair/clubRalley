//
//  PostManager.swift
//  Club Ralley
//
//  ViewModel for managing post data and core operations.
//  Handles loading, creating, and deleting posts.
//

import Foundation
import SwiftUI

/**
 * PostManager: ViewModel for core post operations
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

    /// Loading more posts (for infinite scroll)
    @Published var isLoadingMore = false

    /// Whether there are more posts to load
    @Published var hasMorePosts = true

    /// Error state for user notifications
    @Published var error: Error?

    /// Page size for pagination
    private let pageSize = 20

    // MARK: - Dependencies

    /// Service layer for post database operations
    private let postService = PostService()

    /// Engagement service for likes, comments, reposts
    private let engagementService = PostEngagementService()

    /// Supabase authentication state
    private let supabase = SupabaseManager.shared

    // MARK: - Engagement Manager (for comment operations)

    /// Separate manager for engagement operations
    @Published var engagementManager: PostEngagementManager?

    // MARK: - Initialization

    init() {
        self.engagementManager = PostEngagementManager(postManager: self)
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
            print("PostManager: Loaded \(loadedPosts.count) posts from backend")
        } catch {
            print("PostManager: Failed to load posts: \(error)")
            self.error = error

            // Fallback to sample posts for development
            await loadSamplePosts()
        }

        isLoading = false
    }

    /**
     * Load sample posts for development and offline scenarios
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
                timestamp: Date().addingTimeInterval(-86400),
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
                timestamp: Date().addingTimeInterval(-172800),
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
                timestamp: Date().addingTimeInterval(-7200),
                likes: 15,
                comments: 8,
                shares: 1,
                isLiked: false
            )
        ]

        posts = samplePosts
        print("PostManager: Using sample posts (fallback mode)")
    }

    // MARK: - Post Creation

    /**
     * Create new post and save to database
     * @param content: Post text content
     * @param title: Optional post title
     * @param images: Array of image URLs
     * @param visibility: Post visibility setting
     */
    func createPost(
        content: String,
        title: String? = nil,
        images: [String] = [],
        visibility: PostVisibility = .everyone
    ) async {
        guard !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            print("PostManager: Cannot create post with empty content")
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
            authorId: supabase.currentUser?.id,
            authorSchool: "University",
            authorLocation: "Chicago, IL",
            authorSport: "athlete",
            title: title?.isEmpty == false ? title : nil,
            content: content,
            images: images,
            timestamp: Date(),
            postType: images.isEmpty ? .text : .image,
            visibility: visibility,
            likes: 0,
            comments: 0,
            shares: 0,
            isLiked: false
        )

        do {
            // Save to database via PostService
            let createdPost = try await postService.createPost(newPost, visibility: visibility)

            // Add to local cache at the top of feed
            posts.insert(createdPost, at: 0)

            print("PostManager: Post created successfully")

        } catch {
            print("PostManager: Failed to create post: \(error)")
            self.error = error

            // Even if backend fails, add to local cache for immediate UI feedback
            posts.insert(newPost, at: 0)
            print("PostManager: Post added locally (backend failed)")
        }

        isLoading = false
    }

    // MARK: - Engagement Operations (Delegated)

    /**
     * Toggle like status for a post
     */
    func toggleLike(for postId: UUID) async {
        await engagementManager?.toggleLike(for: postId)
    }

    /**
     * Load comments for a post
     */
    func loadComments(for postId: UUID) async {
        await engagementManager?.loadComments(for: postId)
    }

    /**
     * Add comment to a post
     */
    func addComment(to postId: UUID, content: String) async {
        await engagementManager?.addComment(to: postId, content: content)
    }

    /**
     * Delete a comment
     */
    func deleteComment(_ commentId: UUID, from postId: UUID) async {
        await engagementManager?.deleteComment(commentId, from: postId)
    }

    /// Comments for the selected post (delegated)
    var selectedPostComments: [PostComment] {
        engagementManager?.selectedPostComments ?? []
    }

    /// Loading state for comments (delegated)
    var isLoadingComments: Bool {
        engagementManager?.isLoadingComments ?? false
    }

    // MARK: - Post Management

    /**
     * Delete a post
     */
    func deletePost(_ postId: UUID) async {
        // Optimistic update
        let originalPosts = posts
        posts.removeAll { $0.id == postId }

        do {
            try await postService.deletePost(postId)
            print("PostManager: Post deleted")
        } catch {
            // Revert on failure
            posts = originalPosts
            print("PostManager: Failed to delete post: \(error)")
            self.error = error
        }
    }

    /**
     * Report a post for inappropriate content
     */
    func reportPost(_ postId: UUID, reason: String) async {
        do {
            try await postService.reportPost(postId, reason: reason)
            print("PostManager: Post reported")
        } catch {
            print("PostManager: Failed to report post: \(error)")
            self.error = error
        }
    }

    // MARK: - Legacy Method

    /**
     * Legacy method for immediate UI updates
     */
    func addPost(_ post: ClubRalleyPost) {
        posts.insert(post, at: 0)
        print("PostManager: Post added to local feed")
    }

    // MARK: - User Content Filtering

    /**
     * Get posts created by current user for profile display
     */
    func getUserPosts() -> [ClubRalleyPost] {
        let currentUserName = supabase.currentUser?.displayName ?? "Your Name"
        let userPosts = posts.filter { $0.authorName == currentUserName }

        print("PostManager: Found \(userPosts.count) posts for current user")
        return userPosts.sorted { $0.timestamp > $1.timestamp }
    }

    /**
     * Get posts for specific user
     */
    func getPostsForUser(username: String) -> [ClubRalleyPost] {
        return posts.filter { $0.authorUsername == username }
            .sorted { $0.timestamp > $1.timestamp }
    }

    // MARK: - Feed Management

    /**
     * Refresh posts by reloading from database
     */
    func refreshPosts() async {
        print("PostManager: Refreshing posts from database")
        hasMorePosts = true
        await loadPosts()
    }

    /**
     * Load more posts for infinite scroll
     */
    func loadMorePosts() async {
        guard !isLoadingMore && hasMorePosts else { return }

        isLoadingMore = true

        do {
            let morePosts = try await postService.loadMorePosts(currentCount: posts.count, limit: pageSize)

            if morePosts.isEmpty {
                hasMorePosts = false
            } else {
                posts.append(contentsOf: morePosts)
                // If we got fewer than requested, no more posts available
                if morePosts.count < pageSize {
                    hasMorePosts = false
                }
            }
            print("PostManager: Loaded \(morePosts.count) more posts, total: \(posts.count)")
        } catch {
            print("PostManager: Failed to load more posts: \(error)")
        }

        isLoadingMore = false
    }

    /**
     * Clear error state
     */
    func clearError() {
        error = nil
    }

    // MARK: - Internal Methods

    /**
     * Update a post in the local cache
     */
    func updatePost(at index: Int, with updatedPost: ClubRalleyPost) {
        guard index >= 0 && index < posts.count else { return }
        posts[index] = updatedPost
    }

    /**
     * Find index of post by ID
     */
    func indexOfPost(_ postId: UUID) -> Int? {
        return posts.firstIndex(where: { $0.id == postId })
    }
}
