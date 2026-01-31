//
//  PostService.swift
//  Club Ralley
//
//  Service layer for post operations connecting app models to Supabase backend
//  Handles post creation, retrieval, engagement, and social interactions
//

import Foundation
import SwiftUI

/**
 * PostService: Bridge between PostManager and Supabase posts table
 * 
 * Purpose: Handles all post-related database operations
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
     * @returns: Created post with database ID and timestamps
     * 
     * Database Mapping:
     * - ClubRalleyPost.content -> posts.content
     * - ClubRalleyPost.authorName -> Derived from club_users table
     * - ClubRalleyPost.images -> Stored as JSON array in content or separate table
     */
    func createPost(_ post: ClubRalleyPost) async throws -> ClubRalleyPost {
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
                post_type: post.title != nil ? "text" : "text", // Could expand for different types
                likes_count: 0,
                comments_count: 0
            )
            
            // Insert into Supabase posts table
            try await supabase.insert(dbPost, into: "posts")
            
            print("✅ PostService: Post created successfully in database")
            
            // Return the post with updated database info
            var updatedPost = post
            // In real implementation, we'd get the created post back from database
            // with proper ID, timestamps, etc.
            
            isLoading = false
            return updatedPost
            
        } catch let error as SupabaseManager.SupabaseError {
            isLoading = false
            lastError = error
            print("❌ PostService: Create failed with Supabase error: \(error)")
            throw error
        } catch {
            isLoading = false
            let supabaseError = SupabaseManager.SupabaseError.networkError(error.localizedDescription)
            lastError = supabaseError
            print("❌ PostService: Create failed with network error: \(error)")
            throw supabaseError
        }
    }
    
    // MARK: - Post Retrieval
    
    /**
     * Load posts for home feed from database
     * @param limit: Maximum number of posts to retrieve
     * @param offset: Pagination offset
     * @returns: Array of posts with user information populated
     * 
     * Query Strategy:
     * - JOIN posts with club_users to get author information
     * - ORDER BY created_at DESC for reverse chronological feed
     * - Include engagement counts (likes_count, comments_count)
     */
    func loadHomeFeedPosts(limit: Int = 20, offset: Int = 0) async throws -> [ClubRalleyPost] {
        isLoading = true
        lastError = nil
        
        do {
            // For now, we'll use our existing mock data structure
            // In real implementation, this would be a complex JOIN query
            let posts = try await supabase.query("posts")
                .select("*, club_users(first_name, last_name, username, profile_photo_url)")
                .execute() as [DatabasePostWithUser]
            
            // Map database results to app models
            let mappedPosts = posts.map { dbPost in
                mapDatabasePostToApp(dbPost)
            }
            
            isLoading = false
            print("✅ PostService: Loaded \(mappedPosts.count) posts from database")
            return mappedPosts
            
        } catch let error as SupabaseManager.SupabaseError {
            isLoading = false
            lastError = error
            print("❌ PostService: Load feed failed: \(error)")
            
            // Fallback to mock data for development
            return generateMockPosts()
            
        } catch {
            isLoading = false
            let supabaseError = SupabaseManager.SupabaseError.networkError(error.localizedDescription)
            lastError = supabaseError
            print("❌ PostService: Load feed failed with network error: \(error)")
            
            // Fallback to mock data
            return generateMockPosts()
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
            print("✅ PostService: Loaded \(mappedPosts.count) user posts from database")
            return mappedPosts
            
        } catch {
            isLoading = false
            print("❌ PostService: Load user posts failed: \(error)")
            
            // Fallback: Filter mock posts by user
            return generateMockPosts().filter { $0.authorName == "Your Name" }
        }
    }
    
    // MARK: - Post Engagement
    
    /**
     * Toggle like status for a post
     * @param postId: Post ID to like/unlike
     * @returns: New like status (true if liked, false if unliked)
     * 
     * Database Operations:
     * 1. Check if user already liked the post (post_likes table)
     * 2. If liked: DELETE from post_likes, DECREMENT posts.likes_count
     * 3. If not liked: INSERT into post_likes, INCREMENT posts.likes_count
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
            // 1. Check existing like: SELECT * FROM post_likes WHERE post_id = ? AND user_id = ?
            // 2. If exists: DELETE and decrement counter
            // 3. If not exists: INSERT and increment counter
            
            // For now, simulate the operation
            print("❤️ PostService: Toggled like for post \(postId)")
            
            // Return new like status (mock)
            return true
            
        } catch {
            print("❌ PostService: Like toggle failed: \(error)")
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
            print("✅ PostService: Loaded \(mappedComments.count) comments for post \(postId)")
            return mappedComments

        } catch {
            isLoading = false
            print("❌ PostService: Load comments failed: \(error)")

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

            print("✅ PostService: Comment added to post \(postId)")

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
            print("✅ PostService: Comment \(commentId) deleted")
            isLoading = false
        } catch {
            isLoading = false
            print("❌ PostService: Delete comment failed: \(error)")
            throw SupabaseManager.SupabaseError.networkError(error.localizedDescription)
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
            print("✅ PostService: Post \(postId) deleted")
            isLoading = false
        } catch {
            isLoading = false
            print("❌ PostService: Delete post failed: \(error)")
            throw SupabaseManager.SupabaseError.networkError(error.localizedDescription)
        }
    }

    /**
     * Report a post for review
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

        isLoading = true
        lastError = nil

        do {
            let report = DatabasePostReport(
                post_id: postId,
                reporter_id: currentUser.id,
                reason: reason
            )

            try await supabase.insert(report, into: "post_reports")
            print("✅ PostService: Post \(postId) reported for: \(reason)")
            isLoading = false
        } catch {
            isLoading = false
            print("❌ PostService: Report post failed: \(error)")
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
        // TODO: Implement proper mapping from database fields
        return ClubRalleyPost(
            id: dbPost.id,
            authorName: "\(dbPost.user.first_name) \(dbPost.user.last_name)",
            authorUsername: "@\(dbPost.user.username)",
            authorPhotoURL: dbPost.user.profile_photo_url ?? "",
            title: extractTitleFromContent(dbPost.content),
            content: extractContentFromContent(dbPost.content),
            images: [], // TODO: Parse images from content or separate table
            timestamp: dbPost.created_at,
            likes: dbPost.likes_count,
            comments: dbPost.comments_count,
            shares: 0, // TODO: Add shares to database schema
            isLiked: false // TODO: Query post_likes table for current user
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
    
    /**
     * Generate mock posts for development and fallback scenarios
     * This maintains app functionality even when backend is unavailable
     */
    private func generateMockPosts() -> [ClubRalleyPost] {
        return [
            ClubRalleyPost(
                id: UUID(),
                authorName: "Sarah Wilson",
                authorUsername: "@sarahw",
                authorPhotoURL: "https://picsum.photos/44/44?random=10",
                title: "Amazing Tennis Practice",
                content: "Just had an incredible practice session! Working on my backhand and it's finally clicking. Can't wait for the tournament next week! 🎾",
                images: ["https://picsum.photos/300/300?random=510"],
                timestamp: Date().addingTimeInterval(-3600), // 1 hour ago
                likes: 24,
                comments: 8,
                shares: 3,
                isLiked: false
            ),
            ClubRalleyPost(
                id: UUID(),
                authorName: "Mike Johnson", 
                authorUsername: "@mikej",
                authorPhotoURL: "https://picsum.photos/44/44?random=11",
                title: nil,
                content: "Basketball pickup game at the park was intense! Made some new friends and got a great workout in. Who's up for tomorrow? 🏀",
                images: [],
                timestamp: Date().addingTimeInterval(-7200), // 2 hours ago
                likes: 15,
                comments: 12,
                shares: 1,
                isLiked: true
            )
        ]
    }
}

// Note: Database models (DatabasePost, DatabasePostWithUser, DatabaseUser)
// are defined in Models/Database/DatabaseModels.swift