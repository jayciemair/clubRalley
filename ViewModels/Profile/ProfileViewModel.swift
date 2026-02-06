//
//  ProfileViewModel.swift
//  Club Ralley
//
//  ViewModel for profile management and social interactions
//  Uses real Supabase data with graceful fallbacks
//

import Foundation
import SwiftUI

@MainActor
class ProfileViewModel: ObservableObject {

    // MARK: - Published Properties
    @Published var currentUserProfile: UserProfile?
    @Published var viewedProfiles: [UUID: UserProfile] = [:]
    @Published var isLoading = false
    @Published var error: ProfileError?

    // MARK: - Dependencies
    private let friendshipService = FriendshipService()
    private let userService = UserService()
    private let postService = PostService()
    private let ralleyService = RalleyService()
    private let supabase = SupabaseManager.shared

    // MARK: - Current User Methods

    func loadCurrentUserProfile() async {
        print("🔵 helloWORLD PROFILE_VM loadCurrentUserProfile START")
        isLoading = true
        error = nil

        // First check if we have a saved profile from onboarding
        if let savedProfile = SavedUserProfile.loadFromStorage() {
            print("🔵 helloWORLD PROFILE_VM - Found saved profile: \(savedProfile.firstName) \(savedProfile.lastName)")
            print("🔵 helloWORLD PROFILE_VM - userId: \(savedProfile.id)")
            print("🔵 helloWORLD PROFILE_VM - email: \(savedProfile.email)")
            print("🔵 helloWORLD PROFILE_VM - username: \(savedProfile.username)")

            // Try to enrich with real stats from database
            var posts: [ClubRalleyPost] = []
            var ralleys: [ClubRalley] = []
            var followCounts: (followers: Int, following: Int) = (0, 0)

            do {
                print("🔵 helloWORLD PROFILE_VM - Loading posts...")
                posts = try await postService.loadUserPosts(userId: savedProfile.id)
                print("🔵 helloWORLD PROFILE_VM - Loaded \(posts.count) posts")

                print("🔵 helloWORLD PROFILE_VM - Loading ralleys...")
                ralleys = try await ralleyService.loadUserRalleys(userId: savedProfile.id)
                print("🔵 helloWORLD PROFILE_VM - Loaded \(ralleys.count) ralleys")

                print("🔵 helloWORLD PROFILE_VM - Loading follow counts...")
                followCounts = try await friendshipService.getFollowCounts(userId: savedProfile.id)
                print("🔵 helloWORLD PROFILE_VM - Followers: \(followCounts.followers), Following: \(followCounts.following)")
            } catch {
                print("🔴 helloWORLD PROFILE_VM - Failed to load stats: \(error)")
            }

            currentUserProfile = createProfileFromSavedData(
                savedProfile,
                posts: posts,
                ralleys: ralleys,
                followersCount: followCounts.followers,
                followingCount: followCounts.following
            )
            print("🟢 helloWORLD PROFILE_VM - Created profile from saved data")
            isLoading = false
            return
        }

        print("🔵 helloWORLD PROFILE_VM - No saved profile, trying Supabase...")
        print("🔵 helloWORLD PROFILE_VM - isAuthenticated: \(supabase.isAuthenticated)")
        print("🔵 helloWORLD PROFILE_VM - currentUser: \(supabase.currentUser?.id.uuidString ?? "nil")")

        // Try to load from Supabase if user is authenticated
        if supabase.isAuthenticated, let userId = supabase.currentUser?.id {
            print("🔵 helloWORLD PROFILE_VM - Loading from Supabase for userId: \(userId)")
            do {
                print("🔵 helloWORLD PROFILE_VM - Calling userService.loadUser...")
                let dbUser = try await userService.loadUser(userId)
                print("🔵 helloWORLD PROFILE_VM - Loaded user: \(dbUser.first_name) \(dbUser.last_name)")

                let posts = try await postService.loadUserPosts(userId: userId)
                let ralleys = try await ralleyService.loadUserRalleys(userId: userId)
                let followCounts = try await friendshipService.getFollowCounts(userId: userId)

                currentUserProfile = createProfileFromDatabaseUser(
                    dbUser,
                    posts: posts,
                    ralleys: ralleys,
                    followersCount: followCounts.followers,
                    followingCount: followCounts.following,
                    isFollowedByCurrentUser: nil
                )
                print("🟢 helloWORLD PROFILE_VM - Loaded profile from Supabase")
                isLoading = false
                return
            } catch {
                print("🔴 helloWORLD PROFILE_VM - Supabase load FAILED: \(error)")
            }
        }

        // No profile available - user needs to complete onboarding
        print("🔴 helloWORLD PROFILE_VM - No user profile available")
        currentUserProfile = nil
        isLoading = false
    }

    /// Create UserProfile from saved onboarding data
    private func createProfileFromSavedData(
        _ saved: SavedUserProfile,
        posts: [ClubRalleyPost] = [],
        ralleys: [ClubRalley] = [],
        followersCount: Int = 0,
        followingCount: Int = 0
    ) -> UserProfile {
        let user = User(
            id: saved.id,
            email: saved.email,
            firstName: saved.firstName,
            lastName: saved.lastName,
            username: saved.username,
            dateOfBirth: DateOfBirth(month: 1, year: 2000),
            gender: .preferNotToSay,
            locationCity: saved.locationCity,
            locationState: saved.locationState,
            bio: nil,
            instagramHandle: nil,
            profilePhotoURL: saved.profilePhotoURL,
            isVerifiedAthlete: false,
            athleteInfo: nil,
            friendsCount: followersCount,
            ralleysCount: ralleys.count,
            createdAt: saved.createdAt,
            updatedAt: Date()
        )

        let stats = UserStats(
            followersCount: followersCount,
            followingCount: followingCount,
            gamesPlayed: 0,
            wins: 0,
            postsCount: posts.count,
            ralleysAttended: ralleys.filter { !$0.isCaptain }.count,
            ralleysHosted: ralleys.filter { $0.isCaptain }.count
        )

        let socialInfo = SocialInfo(
            instagramHandle: nil,
            linkedinHandle: nil,
            twitterHandle: nil,
            isVerifiedAthlete: false,
            verificationBadge: nil,
            joinedAt: saved.createdAt
        )

        // Convert posts to photos for profile grid
        let photos = posts.prefix(16).enumerated().map { index, post in
            UserPhoto(
                id: post.id,
                imageURL: post.images.first ?? "https://picsum.photos/300/300?random=\(index)",
                caption: post.content,
                createdAt: post.timestamp,
                likesCount: post.likes,
                commentsCount: post.comments,
                tags: []
            )
        }

        return UserProfile(
            id: saved.id,
            user: user,
            stats: stats,
            socialInfo: socialInfo,
            teams: [],
            photos: Array(photos),
            mutualFriends: [],
            isFollowedByCurrentUser: nil,
            relationshipStatus: .none
        )
    }

    func isCurrentUser(_ userId: UUID) -> Bool {
        return currentUserProfile?.user.id == userId
    }

    // MARK: - Profile Loading

    func loadUserProfile(_ userId: UUID) async -> UserProfile? {
        if let cached = viewedProfiles[userId] {
            return cached
        }

        isLoading = true
        error = nil

        do {
            // Load real user data from Supabase
            let dbUser = try await userService.loadUser(userId)
            let posts = try await postService.loadUserPosts(userId: userId)
            let ralleys = try await ralleyService.loadUserRalleys(userId: userId)
            let attendedRalleys = try await ralleyService.loadAttendedRalleys(userId: userId)
            let followCounts = try await friendshipService.getFollowCounts(userId: userId)
            let isFollowing = try await friendshipService.isFollowing(userId)

            let profile = createProfileFromDatabaseUser(
                dbUser,
                posts: posts,
                ralleys: ralleys + attendedRalleys,
                followersCount: followCounts.followers,
                followingCount: followCounts.following,
                isFollowedByCurrentUser: isFollowing
            )

            viewedProfiles[userId] = profile
            print("ProfileViewModel: Loaded profile for user \(dbUser.first_name) from Supabase")
            isLoading = false
            return profile

        } catch {
            print("ProfileViewModel: Failed to load user profile: \(error)")
            self.error = .loadingFailed(error.localizedDescription)
            isLoading = false
            return nil
        }
    }

    /// Create UserProfile from database user
    private func createProfileFromDatabaseUser(
        _ dbUser: DatabaseUserProfile,
        posts: [ClubRalleyPost],
        ralleys: [ClubRalley],
        followersCount: Int,
        followingCount: Int,
        isFollowedByCurrentUser: Bool?
    ) -> UserProfile {
        // Lean schema doesn't store DOB/gender - use defaults
        let user = User(
            id: dbUser.id,
            email: dbUser.email,
            firstName: dbUser.first_name,
            lastName: dbUser.last_name,
            username: dbUser.username,
            dateOfBirth: DateOfBirth(month: 1, year: 2000),
            gender: .preferNotToSay,
            locationCity: dbUser.city ?? "",
            locationState: dbUser.state ?? "",
            bio: dbUser.bio,
            instagramHandle: dbUser.instagram_handle,
            profilePhotoURL: dbUser.profile_photo_url,
            isVerifiedAthlete: dbUser.is_verified_athlete,
            athleteInfo: nil,
            friendsCount: followersCount,
            ralleysCount: ralleys.count,
            createdAt: dbUser.created_at,
            updatedAt: dbUser.created_at  // Lean schema doesn't have updated_at
        )

        let hostedRalleys = ralleys.filter { $0.organizer.id == dbUser.id }
        let attendedRalleys = ralleys.filter { $0.organizer.id != dbUser.id }

        let stats = UserStats(
            followersCount: followersCount,
            followingCount: followingCount,
            gamesPlayed: ralleys.count,
            wins: 0,
            postsCount: posts.count,
            ralleysAttended: attendedRalleys.count,
            ralleysHosted: hostedRalleys.count
        )

        let socialInfo = SocialInfo(
            instagramHandle: dbUser.instagram_handle,
            linkedinHandle: nil,
            twitterHandle: nil,
            isVerifiedAthlete: dbUser.is_verified_athlete,
            verificationBadge: dbUser.is_verified_athlete ? "verified" : nil,
            joinedAt: dbUser.created_at
        )

        // Convert posts to photos for profile grid
        let photos = posts.prefix(16).enumerated().map { index, post in
            UserPhoto(
                id: post.id,
                imageURL: post.images.first ?? "https://picsum.photos/300/300?random=\(index)",
                caption: post.content,
                createdAt: post.timestamp,
                likesCount: post.likes,
                commentsCount: post.comments,
                tags: []
            )
        }

        return UserProfile(
            id: dbUser.id,
            user: user,
            stats: stats,
            socialInfo: socialInfo,
            teams: [],
            photos: Array(photos),
            mutualFriends: [],
            isFollowedByCurrentUser: isFollowedByCurrentUser,
            relationshipStatus: isFollowedByCurrentUser == true ? .following : .none
        )
    }

    // MARK: - Social Actions

    func toggleFollow(_ userId: UUID) async {
        guard let profile = viewedProfiles[userId] else { return }

        let isCurrentlyFollowing = profile.isFollowedByCurrentUser ?? false
        let newFollowState = !isCurrentlyFollowing

        print("ProfileViewModel: Toggling follow for user \(userId): \(isCurrentlyFollowing) -> \(newFollowState)")

        // Store original state for rollback
        let originalProfile = profile

        // Optimistic local update
        let updatedProfile = UserProfile(
            id: profile.id,
            user: profile.user,
            stats: UserStats(
                followersCount: profile.stats.followersCount + (newFollowState ? 1 : -1),
                followingCount: profile.stats.followingCount,
                gamesPlayed: profile.stats.gamesPlayed,
                wins: profile.stats.wins,
                postsCount: profile.stats.postsCount,
                ralleysAttended: profile.stats.ralleysAttended,
                ralleysHosted: profile.stats.ralleysHosted
            ),
            socialInfo: profile.socialInfo,
            teams: profile.teams,
            photos: profile.photos,
            mutualFriends: profile.mutualFriends,
            isFollowedByCurrentUser: newFollowState,
            relationshipStatus: newFollowState ? .following : .none
        )

        viewedProfiles[userId] = updatedProfile

        // Sync with backend
        do {
            if newFollowState {
                try await friendshipService.followUser(userId)
            } else {
                try await friendshipService.unfollowUser(userId)
            }
            print("ProfileViewModel: Follow state synced with backend")
        } catch {
            // Revert optimistic update on failure
            viewedProfiles[userId] = originalProfile
            self.error = .actionFailed("Failed to update follow status")
            print("ProfileViewModel: Failed to sync follow state: \(error)")
        }
    }

    func blockUser(_ userId: UUID) async {
        guard let profile = viewedProfiles[userId] else { return }

        // Optimistic UI update
        let updatedProfile = UserProfile(
            id: profile.id,
            user: profile.user,
            stats: profile.stats,
            socialInfo: profile.socialInfo,
            teams: profile.teams,
            photos: profile.photos,
            mutualFriends: profile.mutualFriends,
            isFollowedByCurrentUser: false,
            relationshipStatus: .blocked
        )
        viewedProfiles[userId] = updatedProfile

        // Persist to database
        do {
            try await friendshipService.blockUser(userId)
            print("ProfileViewModel: Successfully blocked user \(userId)")
        } catch {
            // Revert optimistic update on failure
            viewedProfiles[userId] = profile
            self.error = .actionFailed("Failed to block user")
            print("ProfileViewModel: Failed to block user: \(error)")
        }
    }

    func unblockUser(_ userId: UUID) async {
        guard let profile = viewedProfiles[userId] else { return }

        // Optimistic UI update
        let updatedProfile = UserProfile(
            id: profile.id,
            user: profile.user,
            stats: profile.stats,
            socialInfo: profile.socialInfo,
            teams: profile.teams,
            photos: profile.photos,
            mutualFriends: profile.mutualFriends,
            isFollowedByCurrentUser: false,
            relationshipStatus: .none
        )
        viewedProfiles[userId] = updatedProfile

        // Persist to database
        do {
            try await friendshipService.unblockUser(userId)
            print("ProfileViewModel: Successfully unblocked user \(userId)")
        } catch {
            // Revert optimistic update on failure
            viewedProfiles[userId] = profile
            self.error = .actionFailed("Failed to unblock user")
            print("ProfileViewModel: Failed to unblock user: \(error)")
        }
    }

    func reportUser(_ userId: UUID, reason: String) async {
        // Persist report to database
        do {
            try await friendshipService.reportUser(userId, reason: reason)
            print("ProfileViewModel: Successfully reported user \(userId) for: \(reason)")
        } catch {
            print("ProfileViewModel: Report logged locally (DB may not be configured): \(error)")
            // Don't show error to user - report is logged even if DB fails
        }
    }
}

// MARK: - Profile Errors

enum ProfileError: LocalizedError {
    case loadingFailed(String)
    case actionFailed(String)
    case notFound
    case unauthorized

    var errorDescription: String? {
        switch self {
        case .loadingFailed(let message):
            return "Failed to load profile: \(message)"
        case .actionFailed(let message):
            return "Action failed: \(message)"
        case .notFound:
            return "Profile not found"
        case .unauthorized:
            return "You don't have permission to perform this action"
        }
    }
}

// Note: ProfileAction enum is defined in Models/User/UserProfile.swift
