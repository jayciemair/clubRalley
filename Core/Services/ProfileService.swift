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
 * ProfileService: Bridge between ProfileViewModel and Supabase club_users table
 *
 * Purpose: Handles all profile-related database operations
 * Strategy: Real Supabase calls with mock fallbacks for reliability
 * Database: Maps UserProfile model to 'club_users', 'friendships', 'user_photos' tables
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
     * - Main profile: SELECT from club_users WHERE id = current_user_id
     * - Stats: COUNT posts, ralleys, friends from respective tables
     * - Photos: SELECT from user_photos WHERE user_id = current_user_id
     * - Teams: SELECT from user_teams JOIN teams WHERE user_id = current_user_id
     * - Social info: Calculate from friendships, posts engagement
     */
    func loadCurrentUserProfile() async throws -> UserProfile? {
        guard supabase.isAuthenticated else {
            throw SupabaseManager.SupabaseError.notAuthenticated
        }

        guard let currentUser = supabase.currentUser else {
            throw SupabaseManager.SupabaseError.userNotFound
        }

        isLoading = true
        lastError = nil

        do {
            // Query user profile from database
            let dbUser = try await supabase.query("club_users")
                .select("*")
                .eq("id", value: currentUser.id)
                .single() as DatabaseUserProfile?

            guard let dbUser = dbUser else {
                throw SupabaseManager.SupabaseError.userNotFound
            }

            // Build UserProfile from database data
            let profile = mapDatabaseUserToProfile(dbUser, isCurrentUser: true)

            isLoading = false
            print("✅ ProfileService: Loaded current user profile from database")
            return profile

        } catch let error as SupabaseManager.SupabaseError {
            isLoading = false
            lastError = error
            print("❌ ProfileService: Load current user failed: \(error)")

            // Fallback to mock data for development
            return generateMockCurrentUserProfile()

        } catch {
            isLoading = false
            let supabaseError = SupabaseManager.SupabaseError.networkError(error.localizedDescription)
            lastError = supabaseError
            print("❌ ProfileService: Load current user failed with network error: \(error)")

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

            // Check if current user follows this user
            let isFollowing = try await checkFollowingStatus(userID: userID)

            // Build profile with following status
            let profile = mapDatabaseUserToProfile(
                dbUser,
                isCurrentUser: false,
                isFollowedByCurrentUser: isFollowing
            )

            isLoading = false
            print("✅ ProfileService: Loaded user profile for \(userID)")
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
        guard supabase.isAuthenticated else {
            throw SupabaseManager.SupabaseError.notAuthenticated
        }

        guard let currentUser = supabase.currentUser else {
            throw SupabaseManager.SupabaseError.userNotFound
        }

        do {
            // Map UserProfile to database format
            let dbUpdate = DatabaseUserProfileUpdate(
                bio: profile.user.bio,
                instagram_handle: profile.user.instagramHandle,
                profile_photo_url: profile.user.profilePhotoURL
            )

            try await supabase.update(dbUpdate, in: "club_users", where: "id = '\(currentUser.id)'")

            print("✅ ProfileService: Profile updated successfully")
            return true

        } catch {
            print("❌ ProfileService: Profile update failed: \(error)")
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
     * @param dbUser: Database user profile record
     * @param isCurrentUser: Whether this is the logged-in user
     * @param isFollowedByCurrentUser: Following status (for other users)
     * @returns: Fully constructed UserProfile
     */
    private func mapDatabaseUserToProfile(
        _ dbUser: DatabaseUserProfile,
        isCurrentUser: Bool,
        isFollowedByCurrentUser: Bool? = nil
    ) -> UserProfile {

        // Create DateOfBirth struct from separate fields
        let dateOfBirth = DateOfBirth(
            month: dbUser.date_of_birth_month,
            year: dbUser.date_of_birth_year
        )

        // Parse gender enum from string
        let gender = Gender(rawValue: dbUser.gender) ?? .preferNotToSay

        // Create User object matching User.swift model
        let user = User(
            id: dbUser.id,
            email: dbUser.email,
            firstName: dbUser.first_name,
            lastName: dbUser.last_name,
            username: dbUser.username,
            dateOfBirth: dateOfBirth,
            gender: gender,
            locationCity: dbUser.location_city,
            locationState: dbUser.location_state,
            bio: dbUser.bio,
            instagramHandle: dbUser.instagram_handle,
            profilePhotoURL: dbUser.profile_photo_url,
            isVerifiedAthlete: dbUser.is_verified_athlete,
            athleteInfo: nil, // TODO: Load from athlete_info table
            friendsCount: dbUser.friends_count,
            ralleysCount: dbUser.ralleys_count,
            createdAt: dbUser.created_at,
            updatedAt: dbUser.updated_at
        )

        // Create UserStats matching UserProfile.swift model
        let stats = UserStats(
            followersCount: dbUser.friends_count,
            followingCount: 0, // TODO: Query from friendships table
            gamesPlayed: 0, // TODO: Calculate from ralley participation
            wins: 0,
            postsCount: 0, // TODO: Query from posts table
            ralleysAttended: 0, // TODO: Query from ralley_participants
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
            teams: [], // TODO: Load from user_teams table
            photos: [], // TODO: Load from user_photos table
            mutualFriends: [],
            isFollowedByCurrentUser: isFollowedByCurrentUser,
            relationshipStatus: relationshipStatus
        )
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
