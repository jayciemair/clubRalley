//
//  UserService.swift
//  Club Ralley
//
//  Service for loading and searching users for the roster
//

import Foundation
import SwiftUI

@MainActor
class UserService: ObservableObject {

    // MARK: - Dependencies

    private let supabase = SupabaseManager.shared

    // MARK: - Published Properties

    @Published var users: [RosterUserData] = []
    @Published var isLoading = false
    @Published var searchQuery = ""
    @Published var error: Error?

    // MARK: - Load All Users

    /// Load users for the roster (excluding current user)
    func loadUsers() async {
        isLoading = true
        error = nil

        do {
            let dbUsers: [DatabaseUserProfile] = try await supabase.query("club_users")
                .select("*")
                .order("created_at", ascending: false)
                .limit(50)
                .execute()

            // Filter out current user and map to roster format
            let currentUserId = supabase.currentUser?.id
            users = dbUsers
                .filter { $0.id != currentUserId }
                .map { mapToRosterUser($0) }

            print("✅ UserService: Loaded \(users.count) users")
            isLoading = false

        } catch {
            print("❌ UserService: Failed to load users: \(error)")
            self.error = error
            isLoading = false

            // Use mock data as fallback
            users = RosterUserData.mockUsers
        }
    }

    // MARK: - Search Users

    /// Search users by name or username
    func searchUsers(query: String) async {
        guard !query.isEmpty else {
            await loadUsers()
            return
        }

        isLoading = true
        error = nil

        do {
            let dbUsers: [DatabaseUserProfile] = try await supabase.query("club_users")
                .select("*")
                .or("first_name.ilike.%\(query)%,last_name.ilike.%\(query)%,username.ilike.%\(query)%")
                .order("first_name", ascending: true)
                .limit(30)
                .execute()

            let currentUserId = supabase.currentUser?.id
            users = dbUsers
                .filter { $0.id != currentUserId }
                .map { mapToRosterUser($0) }

            print("✅ UserService: Search found \(users.count) users")
            isLoading = false

        } catch {
            print("❌ UserService: Search failed: \(error)")
            self.error = error
            isLoading = false

            // Filter mock data as fallback
            users = RosterUserData.mockUsers.filter {
                $0.name.localizedCaseInsensitiveContains(query)
            }
        }
    }

    // MARK: - Follow User

    /// Follow or unfollow a user
    func toggleFollow(userId: UUID) async -> Bool {
        guard supabase.isAuthenticated, let currentUser = supabase.currentUser else {
            return false
        }

        // Find the user in our list
        guard let index = users.firstIndex(where: { $0.id == userId }) else {
            return false
        }

        let wasFollowing = users[index].isFollowing

        // Optimistic update
        users[index].isFollowing.toggle()

        do {
            if wasFollowing {
                try await supabase.delete(
                    from: "friendships",
                    where: "user_id = '\(currentUser.id)' AND friend_id = '\(userId)'"
                )
            } else {
                let friendship = DatabaseFriendship(
                    user_id: currentUser.id,
                    friend_id: userId,
                    status: "accepted"
                )
                try await supabase.insert(friendship, into: "friendships")
            }

            print("✅ UserService: Toggle follow successful")
            return true

        } catch {
            // Revert optimistic update
            users[index].isFollowing = wasFollowing
            print("❌ UserService: Toggle follow failed: \(error)")
            return false
        }
    }

    // MARK: - Check Following Status

    /// Check if current user follows specific users and update their status
    func loadFollowingStatus() async {
        guard supabase.isAuthenticated, let currentUser = supabase.currentUser else {
            return
        }

        do {
            let friendships: [DatabaseFriendship] = try await supabase.query("friendships")
                .select("*")
                .eq("user_id", value: currentUser.id)
                .execute()

            let followingIds = Set(friendships.map { $0.friend_id })

            // Batch update to trigger a single @Published notification
            var updatedUsers = users
            for i in updatedUsers.indices {
                updatedUsers[i].isFollowing = followingIds.contains(updatedUsers[i].id)
            }
            users = updatedUsers

            print("✅ UserService: Updated following status for \(users.count) users")

        } catch {
            print("❌ UserService: Failed to load following status: \(error)")
        }
    }

    // MARK: - Load Single User

    /// Load a single user by their UUID
    /// - Parameter userId: The user's UUID
    /// - Returns: The user profile if found
    func loadUser(_ userId: UUID) async throws -> DatabaseUserProfile {
        isLoading = true
        error = nil

        do {
            let users: [DatabaseUserProfile] = try await supabase.query("club_users")
                .select("*")
                .eq("id", value: userId)
                .execute()

            isLoading = false

            guard let user = users.first else {
                throw SupabaseManager.SupabaseError.userNotFound
            }

            print("✅ UserService: Loaded user \(user.first_name) \(user.last_name)")
            return user

        } catch {
            print("❌ UserService: Failed to load user \(userId): \(error)")
            self.error = error
            isLoading = false
            throw error
        }
    }

    // MARK: - Helper Methods

    private func mapToRosterUser(_ dbUser: DatabaseUserProfile) -> RosterUserData {
        RosterUserData(
            id: dbUser.id,
            name: "\(dbUser.first_name) \(dbUser.last_name)",
            username: dbUser.username,
            location: "\(dbUser.city ?? ""), \(dbUser.state ?? "")",
            photoURL: dbUser.profile_photo_url ?? "https://picsum.photos/100/100?random=\(dbUser.id.hashValue % 1000)",
            mutuals: dbUser.friends_count,
            isFollowing: false,
            isVerified: dbUser.is_verified_athlete
        )
    }
}

// MARK: - Roster User Data Model

struct RosterUserData: Identifiable {
    let id: UUID
    let name: String
    let username: String
    let location: String
    let photoURL: String
    let mutuals: Int
    var isFollowing: Bool
    let isVerified: Bool

    static let mockUsers: [RosterUserData] = [
        RosterUserData(id: UUID(), name: "Sam Marcus", username: "sammarcus", location: "Chicago, IL", photoURL: "https://picsum.photos/100/100?random=201", mutuals: 21, isFollowing: false, isVerified: false),
        RosterUserData(id: UUID(), name: "Gracie King", username: "gking", location: "Chicago, IL", photoURL: "https://picsum.photos/100/100?random=202", mutuals: 9, isFollowing: false, isVerified: true),
        RosterUserData(id: UUID(), name: "Abby Smith", username: "abbysmith", location: "Chicago, IL", photoURL: "https://picsum.photos/100/100?random=203", mutuals: 44, isFollowing: false, isVerified: false),
        RosterUserData(id: UUID(), name: "Sarah Jay", username: "sarahjay", location: "Chicago, IL", photoURL: "https://picsum.photos/100/100?random=204", mutuals: 9, isFollowing: false, isVerified: false),
        RosterUserData(id: UUID(), name: "Maddie Moss", username: "maddiemoss", location: "Chicago, IL", photoURL: "https://picsum.photos/100/100?random=205", mutuals: 21, isFollowing: false, isVerified: true),
        RosterUserData(id: UUID(), name: "Brandon Moss", username: "brandonm", location: "Chicago, IL", photoURL: "https://picsum.photos/100/100?random=206", mutuals: 44, isFollowing: false, isVerified: false),
        RosterUserData(id: UUID(), name: "Jaycie Stone", username: "jayciestone", location: "Chicago, IL", photoURL: "https://picsum.photos/100/100?random=207", mutuals: 9, isFollowing: false, isVerified: false),
        RosterUserData(id: UUID(), name: "Whitney K", username: "whitneyk", location: "Chicago, IL", photoURL: "https://picsum.photos/100/100?random=208", mutuals: 9, isFollowing: false, isVerified: false),
        RosterUserData(id: UUID(), name: "Abby P", username: "abbyp", location: "Chicago, IL", photoURL: "https://picsum.photos/100/100?random=209", mutuals: 9, isFollowing: false, isVerified: true)
    ]
}
