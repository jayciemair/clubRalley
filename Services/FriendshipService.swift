//
//  FriendshipService.swift
//  Club Ralley
//
//  Service for managing follow/unfollow and friendship relationships
//

import Foundation
import SwiftUI

@MainActor
class FriendshipService: ObservableObject {

    // MARK: - Dependencies

    private let supabase = SupabaseManager.shared

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
            print("Followed user: \(userId)")
            isLoading = false
        } catch {
            isLoading = false
            self.error = error
            print("Failed to follow user: \(error)")
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
                where: "user_id = '\(currentUser.id)' AND friend_id = '\(userId)'"
            )
            print("Unfollowed user: \(userId)")
            isLoading = false
        } catch {
            isLoading = false
            self.error = error
            print("Failed to unfollow user: \(error)")
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
            let result: DatabaseFriendship? = try await supabase.query("friendships")
                .select("*")
                .eq("user_id", value: currentUser.id)
                .eq("friend_id", value: userId)
                .single()

            return result != nil
        } catch {
            print("Failed to check following status: \(error)")
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
                .eq("friend_id", value: userId)
                .execute()

            return followers.count
        } catch {
            print("Failed to get followers count: \(error)")
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
                .eq("user_id", value: userId)
                .execute()

            return following.count
        } catch {
            print("Failed to get following count: \(error)")
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
                .eq("user_id", value: userId1)
                .eq("friend_id", value: userId2)
                .execute()

            guard !user1FollowsUser2.isEmpty else { return false }

            // Check if user2 follows user1
            let user2FollowsUser1: [DatabaseFriendship] = try await supabase.query("friendships")
                .select("*")
                .eq("user_id", value: userId2)
                .eq("friend_id", value: userId1)
                .execute()

            return !user2FollowsUser1.isEmpty
        } catch {
            print("Failed to check mutual friends: \(error)")
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
                .eq("user_id", value: currentUser.id)
                .execute()

            return Set(following.map { $0.friend_id })
        } catch {
            print("Failed to get following IDs: \(error)")
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
                .eq("friend_id", value: currentUser.id)
                .execute()

            return Set(followers.map { $0.user_id })
        } catch {
            print("Failed to get follower IDs: \(error)")
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
    /// - Parameter userId: The user ID to get followers for
    /// - Returns: Array of DatabaseUserProfile representing followers
    func loadFollowers(userId: UUID) async throws -> [DatabaseUserProfile] {
        do {
            // Get all friendships where friend_id = userId (people following this user)
            let friendships: [DatabaseFriendship] = try await supabase.query("friendships")
                .select("*")
                .eq("friend_id", value: userId)
                .execute()

            // Get user profiles for each follower
            var followers: [DatabaseUserProfile] = []
            for friendship in friendships {
                let users: [DatabaseUserProfile] = try await supabase.query("club_users")
                    .select("*")
                    .eq("id", value: friendship.user_id)
                    .execute()
                if let user = users.first {
                    followers.append(user)
                }
            }

            print("✅ FriendshipService: Loaded \(followers.count) followers")
            return followers
        } catch {
            print("❌ FriendshipService: Failed to load followers: \(error)")
            throw error
        }
    }

    /// Load users that a specific user is following
    /// - Parameter userId: The user ID to get following for
    /// - Returns: Array of DatabaseUserProfile representing followed users
    func loadFollowing(userId: UUID) async throws -> [DatabaseUserProfile] {
        do {
            // Get all friendships where user_id = userId (people this user follows)
            let friendships: [DatabaseFriendship] = try await supabase.query("friendships")
                .select("*")
                .eq("user_id", value: userId)
                .execute()

            // Get user profiles for each followed user
            var following: [DatabaseUserProfile] = []
            for friendship in friendships {
                let users: [DatabaseUserProfile] = try await supabase.query("club_users")
                    .select("*")
                    .eq("id", value: friendship.friend_id)
                    .execute()
                if let user = users.first {
                    following.append(user)
                }
            }

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
                where: "user_id = '\(currentUser.id)' AND friend_id = '\(userId)'"
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
                where: "user_id = '\(currentUser.id)' AND friend_id = '\(userId)' AND status = 'blocked'"
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
                .eq("user_id", value: currentUser.id)
                .eq("friend_id", value: userId)
                .eq("status", value: "blocked")
                .execute()

            return !result.isEmpty
        } catch {
            print("FriendshipService: Check blocked status failed: \(error)")
            return false
        }
    }

    // MARK: - Report Operations

    /// Report a user for inappropriate behavior
    /// - Parameters:
    ///   - userId: The ID of the user to report
    ///   - reason: The reason for reporting
    func reportUser(_ userId: UUID, reason: String) async throws {
        guard supabase.isAuthenticated else {
            throw SupabaseManager.SupabaseError.notAuthenticated
        }

        guard let currentUser = supabase.currentUser else {
            throw SupabaseManager.SupabaseError.userNotFound
        }

        isLoading = true
        error = nil

        do {
            let report = DatabaseUserReport(
                reporter_id: currentUser.id,
                reported_user_id: userId,
                reason: reason
            )

            try await supabase.insert(report, into: "user_reports")
            print("✅ FriendshipService: Reported user \(userId) for: \(reason)")
            isLoading = false
        } catch {
            isLoading = false
            // Log the report even if database insert fails
            print("⚠️ FriendshipService: Report logged (DB insert failed): User \(userId), Reason: \(reason)")
            // Don't throw - we don't want to fail the user experience if reporting table doesn't exist yet
        }
    }
}

// MARK: - Database Models for Blocking/Reporting

/// Database model for user reports
struct DatabaseUserReport: Codable {
    let reporter_id: UUID
    let reported_user_id: UUID
    let reason: String
}
