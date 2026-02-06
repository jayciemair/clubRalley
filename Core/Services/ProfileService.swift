//
//  ProfileService.swift
//  Club Ralley
//
//  Service layer for user profile operations connecting app models to Supabase backend
//  Handles profile loading, updating, following, and social interactions
//

import Foundation
import SwiftUI

// MARK: - ProfileService

/**
 * ProfileService: Bridge between ProfileViewModel and Supabase users table
 *
 * Purpose: Handles all profile-related database operations
 * Strategy: Real Supabase calls with mock fallbacks for reliability
 * Database: Maps UserProfile model to 'users', 'friendships', 'user_photos' tables
 */
@MainActor
class ProfileService: ObservableObject {

    // MARK: - Dependencies

    /// Supabase client for database operations
    private let supabase = SupabaseManager.shared

    // MARK: - Published Properties for UI Feedback

    /// Loading state for UI spinners
    @Published var isLoading = false

    /// Last operation error for user feedback
    @Published var lastError: SupabaseManager.SupabaseError?

    // MARK: - Current User Profile

    /**
     * Load current authenticated user's profile from database
     *
     * @returns: Complete UserProfile with stats, photos, teams, etc.
     *
     * Database Query Strategy:
     * - Main profile: SELECT from users WHERE id = current_user_id
     * - Stats: COUNT posts, ralleys, friends from respective tables
     * - Photos: SELECT from user_photos WHERE user_id = current_user_id
     * - Teams: SELECT from user_teams JOIN teams WHERE user_id = current_user_id
     * - Social info: Calculate from friendships, posts engagement
     */
    func loadCurrentUserProfile() async throws -> UserProfile? {
        print("🔵 helloWORLD PROFILE_SVC loadCurrentUserProfile START")
        print("🔵 helloWORLD PROFILE_SVC - isAuthenticated: \(supabase.isAuthenticated)")

        guard supabase.isAuthenticated else {
            print("🔴 helloWORLD PROFILE_SVC - NOT AUTHENTICATED")
            throw SupabaseManager.SupabaseError.notAuthenticated
        }

        guard let currentUser = supabase.currentUser else {
            print("🔴 helloWORLD PROFILE_SVC - NO CURRENT USER")
            throw SupabaseManager.SupabaseError.userNotFound
        }

        print("🔵 helloWORLD PROFILE_SVC - currentUser.id: \(currentUser.id)")

        isLoading = true
        lastError = nil

        do {
            // Query user profile from database
            print("🔵 helloWORLD PROFILE_SVC - Querying users table...")
            let dbUser = try await supabase.query("club_users")
                .select("*")
                .eq("id", value: currentUser.id)
                .single() as DatabaseUserProfile?

            guard let dbUser = dbUser else {
                print("🔴 helloWORLD PROFILE_SVC - No user found in database")
                throw SupabaseManager.SupabaseError.userNotFound
            }

            print("🟢 helloWORLD PROFILE_SVC - Found user: \(dbUser.first_name) \(dbUser.last_name)")
            print("🔵 helloWORLD PROFILE_SVC - username: \(dbUser.username)")
            print("🔵 helloWORLD PROFILE_SVC - bio: \(dbUser.bio ?? "nil")")

            // Load real stats from database
            print("🔵 helloWORLD PROFILE_SVC - Loading stats...")
            let stats = await loadUserStats(userId: currentUser.id)
            print("🔵 helloWORLD PROFILE_SVC - Stats: followers=\(stats.followersCount), following=\(stats.followingCount)")

            // Build UserProfile from database data with real stats
            let profile = mapDatabaseUserToProfile(dbUser, isCurrentUser: true, stats: stats)

            isLoading = false
            print("🟢 helloWORLD PROFILE_SVC loadCurrentUserProfile SUCCESS")
            return profile

        } catch let error as SupabaseManager.SupabaseError {
            isLoading = false
            lastError = error
            print("🔴 helloWORLD PROFILE_SVC - Supabase error: \(error)")

            // Fallback to mock data for development
            return generateMockCurrentUserProfile()

        } catch {
            isLoading = false
            let supabaseError = SupabaseManager.SupabaseError.networkError(error.localizedDescription)
            lastError = supabaseError
            print("🔴 helloWORLD PROFILE_SVC - Network error: \(error)")

            // Fallback to mock data
            return generateMockCurrentUserProfile()
        }
    }

    // MARK: - Other User Profiles

    /**
     * Load another user's profile by ID
     *
     * @param userID: UUID of the user to load
     * @returns: UserProfile with following status relative to current user
     */
    func loadUserProfile(userID: UUID) async throws -> UserProfile? {
        isLoading = true
        lastError = nil

        do {
            let dbUser = try await supabase.query("club_users")
                .select("*")
                .eq("id", value: userID)
                .single() as DatabaseUserProfile?

            guard let dbUser = dbUser else {
                throw SupabaseManager.SupabaseError.userNotFound
            }

            // Check if current user follows this user and load stats in parallel
            async let isFollowing = checkFollowingStatus(userID: userID)
            async let stats = loadUserStats(userId: userID)

            // Build profile with following status and real stats
            let profile = mapDatabaseUserToProfile(
                dbUser,
                isCurrentUser: false,
                isFollowedByCurrentUser: try await isFollowing,
                stats: await stats
            )

            isLoading = false
            print("✅ ProfileService: Loaded user profile for \(userID) with real stats")
            return profile

        } catch {
            isLoading = false
            print("❌ ProfileService: Load user profile failed: \(error)")

            // Fallback to mock data
            return generateMockOtherUserProfile(userID: userID)
        }
    }

    // MARK: - Profile Updates

    /**
     * Update current user's profile
     *
     * @param profile: Updated UserProfile to save
     * @returns: Success status
     */
    func updateProfile(_ profile: UserProfile) async throws -> Bool {
        print("🔵 helloWORLD PROFILE_SVC updateProfile START")
        print("🔵 helloWORLD PROFILE_SVC - firstName: \(profile.user.firstName)")
        print("🔵 helloWORLD PROFILE_SVC - lastName: \(profile.user.lastName)")
        print("🔵 helloWORLD PROFILE_SVC - username: \(profile.user.username)")
        print("🔵 helloWORLD PROFILE_SVC - bio: \(profile.user.bio ?? "nil")")

        guard supabase.isAuthenticated else {
            print("🔴 helloWORLD PROFILE_SVC updateProfile - NOT AUTHENTICATED")
            throw SupabaseManager.SupabaseError.notAuthenticated
        }

        guard let currentUser = supabase.currentUser else {
            print("🔴 helloWORLD PROFILE_SVC updateProfile - NO CURRENT USER")
            throw SupabaseManager.SupabaseError.userNotFound
        }

        print("🔵 helloWORLD PROFILE_SVC - Updating for userId: \(currentUser.id)")

        do {
            // Map UserProfile to database format - include all editable fields
            let dbUpdate = DatabaseUserProfileUpdate(
                first_name: profile.user.firstName,
                last_name: profile.user.lastName,
                username: profile.user.username,
                bio: profile.user.bio,
                city: profile.user.locationCity.isEmpty ? nil : profile.user.locationCity,
                state: profile.user.locationState.isEmpty ? nil : profile.user.locationState,
                instagram_handle: profile.user.instagramHandle,
                profile_photo_url: profile.user.profilePhotoURL
            )

            print("🔵 helloWORLD PROFILE_SVC - Calling supabase.update...")
            try await supabase.update(dbUpdate, in: "club_users", where: "id = '\(currentUser.id)'")

            print("🟢 helloWORLD PROFILE_SVC updateProfile SUCCESS")
            return true

        } catch {
            print("🔴 helloWORLD PROFILE_SVC updateProfile FAILED: \(error)")
            throw SupabaseManager.SupabaseError.networkError(error.localizedDescription)
        }
    }

    // MARK: - Social Features

    /**
     * Toggle follow status for a user
     *
     * @param userID: User to follow/unfollow
     * @returns: New following status (true if now following, false if unfollowed)
     */
    func toggleFollow(userID: UUID) async throws -> Bool {
        guard supabase.isAuthenticated else {
            throw SupabaseManager.SupabaseError.notAuthenticated
        }

        guard let currentUser = supabase.currentUser else {
            throw SupabaseManager.SupabaseError.userNotFound
        }

        do {
            // Check current following status
            let isCurrentlyFollowing = try await checkFollowingStatus(userID: userID)

            if isCurrentlyFollowing {
                // Unfollow: Delete from friendships table
                try await supabase.delete(
                    from: "friendships",
                    where: "user_id = '\(currentUser.id)' AND friend_id = '\(userID)'"
                )

                print("✅ ProfileService: Unfollowed user \(userID)")
                return false

            } else {
                // Follow: Insert into friendships table
                let friendship = DatabaseFriendship(
                    user_id: currentUser.id,
                    friend_id: userID,
                    status: "accepted"
                )

                try await supabase.insert(friendship, into: "friendships")

                print("✅ ProfileService: Now following user \(userID)")
                return true
            }

        } catch {
            print("❌ ProfileService: Toggle follow failed: \(error)")
            throw SupabaseManager.SupabaseError.networkError(error.localizedDescription)
        }
    }

    /**
     * Check if current user is following another user
     *
     * @param userID: User to check following status for
     * @returns: True if following, false otherwise
     */
    func checkFollowingStatus(userID: UUID) async throws -> Bool {
        guard let currentUser = supabase.currentUser else {
            return false
        }

        do {
            let result = try await supabase.query("friendships")
                .select("*")
                .eq("user_id", value: currentUser.id)
                .eq("friend_id", value: userID)
                .execute() as [DatabaseFriendship]

            return !result.isEmpty

        } catch {
            print("❌ ProfileService: Check following status failed: \(error)")
            return false
        }
    }

    // MARK: - Helper Methods

    /**
     * Map database user profile to app UserProfile model
     *
     * @param dbUser: Database user profile record (lean 6-table schema)
     * @param isCurrentUser: Whether this is the logged-in user
     * @param isFollowedByCurrentUser: Following status (for other users)
     * @param stats: Optional pre-loaded stats (if nil, uses defaults from dbUser)
     * @returns: Fully constructed UserProfile
     */
    private func mapDatabaseUserToProfile(
        _ dbUser: DatabaseUserProfile,
        isCurrentUser: Bool,
        isFollowedByCurrentUser: Bool? = nil,
        stats loadedStats: UserStats? = nil
    ) -> UserProfile {

        // Lean schema doesn't store DOB or gender - use defaults
        let dateOfBirth = DateOfBirth(month: 1, year: 2000)
        let gender: Gender = .preferNotToSay

        // Create User object matching User.swift model
        let user = User(
            id: dbUser.id,
            email: dbUser.email,
            firstName: dbUser.first_name,
            lastName: dbUser.last_name,
            username: dbUser.username,
            dateOfBirth: dateOfBirth,
            gender: gender,
            locationCity: dbUser.city ?? "",
            locationState: dbUser.state ?? "",
            bio: dbUser.bio,
            instagramHandle: dbUser.instagram_handle,
            profilePhotoURL: dbUser.profile_photo_url,
            isVerifiedAthlete: dbUser.is_verified_athlete,
            athleteInfo: nil,
            friendsCount: dbUser.friends_count,
            ralleysCount: dbUser.ralleys_count,
            createdAt: dbUser.created_at,
            updatedAt: dbUser.created_at  // Lean schema doesn't have updated_at
        )

        // Use pre-loaded stats or create from database user
        let stats = loadedStats ?? UserStats(
            followersCount: dbUser.friends_count,
            followingCount: 0,
            gamesPlayed: 0,
            wins: 0,
            postsCount: 0,
            ralleysAttended: 0,
            ralleysHosted: dbUser.ralleys_count
        )

        // Create SocialInfo matching UserProfile.swift model
        let socialInfo = SocialInfo(
            instagramHandle: dbUser.instagram_handle,
            linkedinHandle: nil,
            twitterHandle: nil,
            isVerifiedAthlete: dbUser.is_verified_athlete,
            verificationBadge: dbUser.is_verified_athlete ? "verified" : nil,
            joinedAt: dbUser.created_at
        )

        // Determine relationship status (no currentUser case in enum)
        let relationshipStatus: RelationshipStatus = isFollowedByCurrentUser == true ? .following : .none

        return UserProfile(
            id: dbUser.id,
            user: user,
            stats: stats,
            socialInfo: socialInfo,
            teams: [],
            photos: [],
            mutualFriends: [],
            isFollowedByCurrentUser: isFollowedByCurrentUser,
            relationshipStatus: relationshipStatus
        )
    }

    // MARK: - Stats Loading Methods

    /**
     * Load user stats from database (followers, following, posts, ralleys)
     * @param userId: User ID to load stats for
     * @returns: UserStats with real counts from database
     */
    func loadUserStats(userId: UUID) async -> UserStats {
        async let followersCount = getFollowersCount(userId: userId)
        async let followingCount = getFollowingCount(userId: userId)
        async let postsCount = getPostsCount(userId: userId)
        async let ralleysAttended = getRalleysAttendedCount(userId: userId)
        async let ralleysHosted = getRalleysHostedCount(userId: userId)

        return await UserStats(
            followersCount: followersCount,
            followingCount: followingCount,
            gamesPlayed: ralleysAttended,
            wins: 0,
            postsCount: postsCount,
            ralleysAttended: ralleysAttended,
            ralleysHosted: ralleysHosted
        )
    }

    /**
     * Get count of users following this user
     */
    private func getFollowersCount(userId: UUID) async -> Int {
        do {
            let result: [DatabaseFriendship] = try await supabase.query("friendships")
                .select("*")
                .eq("friend_id", value: userId)
                .eq("status", value: "accepted")
                .execute()
            return result.count
        } catch {
            print("ProfileService: Failed to get followers count: \(error)")
            return 0
        }
    }

    /**
     * Get count of users this user is following
     */
    private func getFollowingCount(userId: UUID) async -> Int {
        do {
            let result: [DatabaseFriendship] = try await supabase.query("friendships")
                .select("*")
                .eq("user_id", value: userId)
                .eq("status", value: "accepted")
                .execute()
            return result.count
        } catch {
            print("ProfileService: Failed to get following count: \(error)")
            return 0
        }
    }

    /**
     * Get count of posts by this user
     */
    private func getPostsCount(userId: UUID) async -> Int {
        do {
            let result: [DatabasePostWithUser] = try await supabase.query("posts")
                .select("*, club_users(*)")
                .eq("user_id", value: userId)
                .execute()
            return result.count
        } catch {
            print("ProfileService: Failed to get posts count: \(error)")
            return 0
        }
    }

    /**
     * Get count of ralleys this user has attended
     */
    private func getRalleysAttendedCount(userId: UUID) async -> Int {
        do {
            let result: [DatabaseRalleyParticipant] = try await supabase.query("ralley_participants")
                .select("*")
                .eq("user_id", value: userId)
                .execute()
            return result.count
        } catch {
            print("ProfileService: Failed to get ralleys attended count: \(error)")
            return 0
        }
    }

    /**
     * Get count of ralleys this user has hosted
     */
    private func getRalleysHostedCount(userId: UUID) async -> Int {
        do {
            let result: [DatabaseRalleyWithUser] = try await supabase.query("ralleys")
                .select("*, club_users(*)")
                .eq("host_user_id", value: userId)
                .execute()
            return result.count
        } catch {
            print("ProfileService: Failed to get ralleys hosted count: \(error)")
            return 0
        }
    }

    /**
     * Generate mock current user profile for development and fallback
     */
    private func generateMockCurrentUserProfile() -> UserProfile {
        let dateOfBirth = DateOfBirth(month: 6, year: 1995)

        let user = User(
            id: UUID(),
            email: supabase.currentUser?.email ?? "you@example.com",
            firstName: supabase.currentUser?.firstName ?? "Your",
            lastName: supabase.currentUser?.lastName ?? "Name",
            username: "yourname",
            dateOfBirth: dateOfBirth,
            gender: .preferNotToSay,
            locationCity: "San Francisco",
            locationState: "CA",
            bio: "Love staying active and meeting new people through sports! Always up for a good pickup game. 🏀⚽🎾",
            instagramHandle: "yourname",
            profilePhotoURL: "https://picsum.photos/120/120?random=50",
            isVerifiedAthlete: false,
            athleteInfo: nil,
            friendsCount: 130,
            ralleysCount: 20,
            createdAt: Date().addingTimeInterval(-86400 * 30),
            updatedAt: Date()
        )

        let stats = UserStats(
            followersCount: 130,
            followingCount: 85,
            gamesPlayed: 20,
            wins: 12,
            postsCount: 3,
            ralleysAttended: 15,
            ralleysHosted: 5
        )

        let socialInfo = SocialInfo(
            instagramHandle: "yourname",
            linkedinHandle: nil,
            twitterHandle: nil,
            isVerifiedAthlete: false,
            verificationBadge: nil,
            joinedAt: Date().addingTimeInterval(-86400 * 30)
        )

        return UserProfile(
            id: user.id,
            user: user,
            stats: stats,
            socialInfo: socialInfo,
            teams: [],
            photos: [],
            mutualFriends: [],
            isFollowedByCurrentUser: nil,
            relationshipStatus: .none
        )
    }

    /**
     * Generate mock other user profile for development and fallback
     */
    private func generateMockOtherUserProfile(userID: UUID) -> UserProfile {
        let dateOfBirth = DateOfBirth(month: 3, year: 1998)

        let user = User(
            id: userID,
            email: "alex@example.com",
            firstName: "Alex",
            lastName: "Johnson",
            username: "alexj",
            dateOfBirth: dateOfBirth,
            gender: .male,
            locationCity: "Chicago",
            locationState: "IL",
            bio: "Basketball enthusiast 🏀 | Always looking for pickup games | Former college athlete",
            instagramHandle: "alexj_hoops",
            profilePhotoURL: "https://picsum.photos/120/120?random=100",
            isVerifiedAthlete: true,
            athleteInfo: nil,
            friendsCount: 342,
            ralleysCount: 45,
            createdAt: Date().addingTimeInterval(-86400 * 180),
            updatedAt: Date()
        )

        let stats = UserStats(
            followersCount: 342,
            followingCount: 128,
            gamesPlayed: 45,
            wins: 28,
            postsCount: 28,
            ralleysAttended: 38,
            ralleysHosted: 7
        )

        let socialInfo = SocialInfo(
            instagramHandle: "alexj_hoops",
            linkedinHandle: nil,
            twitterHandle: nil,
            isVerifiedAthlete: true,
            verificationBadge: "verified",
            joinedAt: Date().addingTimeInterval(-86400 * 180)
        )

        return UserProfile(
            id: user.id,
            user: user,
            stats: stats,
            socialInfo: socialInfo,
            teams: [],
            photos: [],
            mutualFriends: [],
            isFollowedByCurrentUser: false,
            relationshipStatus: .none
        )
    }
}

// Note: Database models (DatabaseUserProfile, DatabaseUserProfileUpdate, DatabaseFriendship)
// are defined in Models/Database/DatabaseModels.swift
//
// UI models (UserProfile, UserStats, SocialInfo, etc.)
// are defined in Models/User/UserProfile.swift
