//
//  FriendshipService.swift
//  Club Ralley
//
//  Service for managing follow/unfollow and friendship relationships
//

import Foundation
import SwiftUI

// MARK: - Protocol

@MainActor
protocol FriendshipServiceProtocol: ObservableObject {
    var isLoading: Bool { get }
    var error: Error? { get }
    func followUser(_ userId: UUID) async throws
    func unfollowUser(_ userId: UUID) async throws
    func isFollowing(_ userId: UUID) async throws -> Bool
    func getFollowersCount(_ userId: UUID) async throws -> Int
    func getFollowingCount(_ userId: UUID) async throws -> Int
    func getBlockedUserIds() async throws -> Set<UUID>
    func loadFollowers(userId: UUID, limit: Int, offset: Int) async throws -> [DatabaseUserProfile]
    func loadFollowing(userId: UUID, limit: Int, offset: Int) async throws -> [DatabaseUserProfile]
    func getFollowCounts(userId: UUID) async throws -> (followers: Int, following: Int)
    func blockUser(_ userId: UUID) async throws
    func unblockUser(_ userId: UUID) async throws
    func hasBlocked(_ userId: UUID) async -> Bool
    func isBlockedBy(_ userId: UUID) async -> Bool
    func reportUser(_ userId: UUID, reason: String) async throws
}

@MainActor
class FriendshipService: ObservableObject, FriendshipServiceProtocol {

    // MARK: - Dependencies

    private let supabase = SupabaseManager.shared
    private let notificationService = InAppNotificationService.shared

    // MARK: - Published Properties

    @Published var isLoading = false
    @Published var error: Error?

    // MARK: - Follow Operations

    /// Follow a user
    /// - Parameter userId: The ID of the user to follow
    func followUser(_ userId: UUID) async throws {
        guard supabase.isAuthenticated else {
            throw SupabaseManager.SupabaseError.notAuthenticated
        }

        guard let currentUser = supabase.currentUser else {
            throw SupabaseManager.SupabaseError.userNotFound
        }

        isLoading = true
        error = nil

        do {
            let friendship = DatabaseFriendship(
                user_id: currentUser.id,
                friend_id: userId,
                status: "accepted"
            )

            try await supabase.insert(friendship, into: "friendships")

            // Create follow notification
            await notificationService.createFollowNotification(followedUserId: userId)

            print("✅ FriendshipService: Followed user: \(userId)")
            isLoading = false
        } catch {
            isLoading = false
            self.error = error
            print("❌ FriendshipService: Failed to follow user: \(error)")
            throw error
        }
    }

    /// Unfollow a user
    /// - Parameter userId: The ID of the user to unfollow
    func unfollowUser(_ userId: UUID) async throws {
        guard supabase.isAuthenticated else {
            throw SupabaseManager.SupabaseError.notAuthenticated
        }

        guard let currentUser = supabase.currentUser else {
            throw SupabaseManager.SupabaseError.userNotFound
        }

        isLoading = true
        error = nil

        do {
            try await supabase.delete(
                from: "friendships",
                where: "requester_id = '\(currentUser.id)' AND addressee_id = '\(userId)'"
            )
            print("✅ FriendshipService: Unfollowed user: \(userId)")
            isLoading = false
        } catch {
            isLoading = false
            self.error = error
            print("❌ FriendshipService: Failed to unfollow user: \(error)")
            throw error
        }
    }

    /// Check if the current user is following a specific user
    /// - Parameter userId: The ID of the user to check
    /// - Returns: True if following, false otherwise
    func isFollowing(_ userId: UUID) async throws -> Bool {
        guard supabase.isAuthenticated else {
            return false
        }

        guard let currentUser = supabase.currentUser else {
            return false
        }

        do {
            let result: [DatabaseFriendship] = try await supabase.query("friendships")
                .select("*")
                .eq("requester_id", value: currentUser.id)
                .eq("addressee_id", value: userId)
                .eq("status", value: "accepted")
                .execute()

            return !result.isEmpty
        } catch {
            print("❌ FriendshipService: Failed to check following status: \(error)")
            return false
        }
    }

    /// Get followers count for a user
    /// - Parameter userId: The user ID to get followers for
    /// - Returns: Number of followers
    func getFollowersCount(_ userId: UUID) async throws -> Int {
        do {
            let followers: [DatabaseFriendship] = try await supabase.query("friendships")
                .select("*")
                .eq("addressee_id", value: userId)
                .eq("status", value: "accepted")
                .execute()

            return followers.count
        } catch {
            print("❌ FriendshipService: Failed to get followers count: \(error)")
            return 0
        }
    }

    /// Get following count for a user
    /// - Parameter userId: The user ID to get following for
    /// - Returns: Number of users being followed
    func getFollowingCount(_ userId: UUID) async throws -> Int {
        do {
            let following: [DatabaseFriendship] = try await supabase.query("friendships")
                .select("*")
                .eq("requester_id", value: userId)
                .eq("status", value: "accepted")
                .execute()

            return following.count
        } catch {
            print("❌ FriendshipService: Failed to get following count: \(error)")
            return 0
        }
    }

    // MARK: - Mutual Friends Methods

    /// Check if two users are mutual friends (both follow each other)
    /// - Parameters:
    ///   - userId1: First user ID
    ///   - userId2: Second user ID
    /// - Returns: True if they mutually follow each other
    func areMutualFriends(_ userId1: UUID, _ userId2: UUID) async throws -> Bool {
        do {
            // Check if user1 follows user2
            let user1FollowsUser2: [DatabaseFriendship] = try await supabase.query("friendships")
                .select("*")
                .eq("requester_id", value: userId1)
                .eq("addressee_id", value: userId2)
                .eq("status", value: "accepted")
                .execute()

            guard !user1FollowsUser2.isEmpty else { return false }

            // Check if user2 follows user1
            let user2FollowsUser1: [DatabaseFriendship] = try await supabase.query("friendships")
                .select("*")
                .eq("requester_id", value: userId2)
                .eq("addressee_id", value: userId1)
                .eq("status", value: "accepted")
                .execute()

            return !user2FollowsUser1.isEmpty
        } catch {
            print("❌ FriendshipService: Failed to check mutual friends: \(error)")
            return false
        }
    }

    /// Get list of user IDs that current user is following
    /// - Returns: Set of user IDs being followed
    func getFollowingIds() async throws -> Set<UUID> {
        guard supabase.isAuthenticated else { return [] }
        guard let currentUser = supabase.currentUser else { return [] }

        do {
            let following: [DatabaseFriendship] = try await supabase.query("friendships")
                .select("*")
                .eq("requester_id", value: currentUser.id)
                .eq("status", value: "accepted")
                .execute()

            return Set(following.map { $0.addressee_id })
        } catch {
            print("❌ FriendshipService: Failed to get following IDs: \(error)")
            return []
        }
    }

    /// Get list of user IDs who follow current user
    /// - Returns: Set of follower user IDs
    func getFollowerIds() async throws -> Set<UUID> {
        guard supabase.isAuthenticated else { return [] }
        guard let currentUser = supabase.currentUser else { return [] }

        do {
            let followers: [DatabaseFriendship] = try await supabase.query("friendships")
                .select("*")
                .eq("addressee_id", value: currentUser.id)
                .eq("status", value: "accepted")
                .execute()

            return Set(followers.map { $0.requester_id })
        } catch {
            print("❌ FriendshipService: Failed to get follower IDs: \(error)")
            return []
        }
    }

    /// Get list of user IDs that current user has blocked
    /// - Returns: Set of blocked user IDs
    func getBlockedUserIds() async throws -> Set<UUID> {
        guard supabase.isAuthenticated else { return [] }
        guard let currentUser = supabase.currentUser else { return [] }

        do {
            // Get users that current user has blocked
            let blockedByMe: [DatabaseFriendship] = try await supabase.query("friendships")
                .select("*")
                .eq("requester_id", value: currentUser.id)
                .eq("status", value: "blocked")
                .execute()

            // Also get users who have blocked the current user
            let blockedMe: [DatabaseFriendship] = try await supabase.query("friendships")
                .select("*")
                .eq("addressee_id", value: currentUser.id)
                .eq("status", value: "blocked")
                .execute()

            var blockedIds = Set(blockedByMe.map { $0.addressee_id })
            blockedIds.formUnion(blockedMe.map { $0.requester_id })

            return blockedIds
        } catch {
            print("❌ FriendshipService: Failed to get blocked user IDs: \(error)")
            return []
        }
    }

    /// Get mutual friend IDs (users who both follow and are followed by current user)
    /// - Returns: Set of mutual friend user IDs
    func getMutualFriendIds() async throws -> Set<UUID> {
        let following = try await getFollowingIds()
        let followers = try await getFollowerIds()
        return following.intersection(followers)
    }

    // MARK: - User List Methods

    /// Load followers for a specific user
    /// - Parameters:
    ///   - userId: The user ID to get followers for
    ///   - limit: Maximum number of results (default 50)
    ///   - offset: Pagination offset (default 0)
    /// - Returns: Array of DatabaseUserProfile representing followers
    func loadFollowers(userId: UUID, limit: Int = 50, offset: Int = 0) async throws -> [DatabaseUserProfile] {
        do {
            // Get friendships with pagination
            let friendships: [DatabaseFriendship] = try await supabase.query("friendships")
                .select("*")
                .eq("addressee_id", value: userId)
                .eq("status", value: "accepted")
                .range(from: offset, to: offset + limit - 1)
                .execute()

            // Batch load user profiles with .in() instead of N+1 loop
            let followerIds = friendships.map { $0.requester_id }
            guard !followerIds.isEmpty else { return [] }

            let followers: [DatabaseUserProfile] = try await supabase.query("club_users")
                .select("*")
                .in("id", values: followerIds)
                .execute()

            print("✅ FriendshipService: Loaded \(followers.count) followers")
            return followers
        } catch {
            print("❌ FriendshipService: Failed to load followers: \(error)")
            throw error
        }
    }

    /// Load users that a specific user is following
    /// - Parameters:
    ///   - userId: The user ID to get following for
    ///   - limit: Maximum number of results (default 50)
    ///   - offset: Pagination offset (default 0)
    /// - Returns: Array of DatabaseUserProfile representing followed users
    func loadFollowing(userId: UUID, limit: Int = 50, offset: Int = 0) async throws -> [DatabaseUserProfile] {
        do {
            // Get friendships with pagination
            let friendships: [DatabaseFriendship] = try await supabase.query("friendships")
                .select("*")
                .eq("requester_id", value: userId)
                .eq("status", value: "accepted")
                .range(from: offset, to: offset + limit - 1)
                .execute()

            // Batch load user profiles with .in() instead of N+1 loop
            let followingIds = friendships.map { $0.addressee_id }
            guard !followingIds.isEmpty else { return [] }

            let following: [DatabaseUserProfile] = try await supabase.query("club_users")
                .select("*")
                .in("id", values: followingIds)
                .execute()

            print("✅ FriendshipService: Loaded \(following.count) following")
            return following
        } catch {
            print("❌ FriendshipService: Failed to load following: \(error)")
            throw error
        }
    }

    /// Get follow counts for a specific user
    /// - Parameter userId: The user ID to get counts for
    /// - Returns: Tuple with followers and following counts
    func getFollowCounts(userId: UUID) async throws -> (followers: Int, following: Int) {
        let followersCount = try await getFollowersCount(userId)
        let followingCount = try await getFollowingCount(userId)
        return (followers: followersCount, following: followingCount)
    }

    // MARK: - Block Operations

    /// Block a user
    /// - Parameter userId: The ID of the user to block
    func blockUser(_ userId: UUID) async throws {
        guard supabase.isAuthenticated else {
            throw SupabaseManager.SupabaseError.notAuthenticated
        }

        guard let currentUser = supabase.currentUser else {
            throw SupabaseManager.SupabaseError.userNotFound
        }

        isLoading = true
        error = nil

        do {
            // First, remove any existing friendship
            try? await supabase.delete(
                from: "friendships",
                where: "requester_id = '\(currentUser.id)' AND addressee_id = '\(userId)'"
            )

            // Insert blocked relationship
            let blockedRelationship = DatabaseFriendship(
                user_id: currentUser.id,
                friend_id: userId,
                status: "blocked"
            )

            try await supabase.insert(blockedRelationship, into: "friendships")
            print("✅ FriendshipService: Blocked user: \(userId)")
            isLoading = false
        } catch {
            isLoading = false
            self.error = error
            print("❌ FriendshipService: Failed to block user: \(error)")
            throw error
        }
    }

    /// Unblock a user
    /// - Parameter userId: The ID of the user to unblock
    func unblockUser(_ userId: UUID) async throws {
        guard supabase.isAuthenticated else {
            throw SupabaseManager.SupabaseError.notAuthenticated
        }

        guard let currentUser = supabase.currentUser else {
            throw SupabaseManager.SupabaseError.userNotFound
        }

        isLoading = true
        error = nil

        do {
            try await supabase.delete(
                from: "friendships",
                where: "requester_id = '\(currentUser.id)' AND addressee_id = '\(userId)' AND status = 'blocked'"
            )
            print("✅ FriendshipService: Unblocked user: \(userId)")
            isLoading = false
        } catch {
            isLoading = false
            self.error = error
            print("❌ FriendshipService: Failed to unblock user: \(error)")
            throw error
        }
    }

    /// Check if the current user has blocked a specific user
    /// - Parameter userId: The ID of the user to check
    /// - Returns: True if blocked, false otherwise
    func hasBlocked(_ userId: UUID) async -> Bool {
        guard let currentUser = supabase.currentUser else { return false }

        do {
            let result: [DatabaseFriendship] = try await supabase.query("friendships")
                .select("*")
                .eq("requester_id", value: currentUser.id)
                .eq("addressee_id", value: userId)
                .eq("status", value: "blocked")
                .execute()

            return !result.isEmpty
        } catch {
            print("❌ FriendshipService: Check blocked status failed: \(error)")
            return false
        }
    }

    /// Check if a user has blocked the current user
    /// - Parameter userId: The ID of the user to check
    /// - Returns: True if they blocked current user, false otherwise
    func isBlockedBy(_ userId: UUID) async -> Bool {
        guard let currentUser = supabase.currentUser else { return false }

        do {
            let result: [DatabaseFriendship] = try await supabase.query("friendships")
                .select("*")
                .eq("requester_id", value: userId)
                .eq("addressee_id", value: currentUser.id)
                .eq("status", value: "blocked")
                .execute()

            return !result.isEmpty
        } catch {
            print("❌ FriendshipService: Check is blocked by status failed: \(error)")
            return false
        }
    }

    // MARK: - Report Operations

    /// Report a user for inappropriate behavior
    /// - Parameters:
    ///   - userId: The ID of the user to report
    ///   - reason: The reason for reporting
    func reportUser(_ userId: UUID, reason: String) async throws {
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

        try await reportService.reportUser(userId, reason: reportReason, additionalContext: reason)
    }
}

// MARK: - Database Models

// Note: DatabaseFriendship is defined in Models/Database/DatabaseFriendship.swift

/// Database model for user reports (stubbed - no reports table in lean schema)
struct DatabaseUserReport: Codable {
    let reporter_id: UUID
    let reported_user_id: UUID
    let reason: String
}
