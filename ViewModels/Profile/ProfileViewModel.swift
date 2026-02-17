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
        print("🔵 DEBUG PROFILE_VM loadCurrentUserProfile START")
        isLoading = true
        error = nil

        // First check if we have a saved profile from onboarding
        if let savedProfile = SavedUserProfile.loadFromStorage() {
            print("🔵 DEBUG PROFILE_VM - Found saved profile: \(savedProfile.firstName) \(savedProfile.lastName)")
            print("🔵 DEBUG PROFILE_VM - userId: \(savedProfile.id)")
            print("🔵 DEBUG PROFILE_VM - email: \(savedProfile.email)")
            print("🔵 DEBUG PROFILE_VM - username: \(savedProfile.username)")

            // Try to enrich with real stats from database
            var posts: [ClubRalleyPost] = []
            var ralleys: [ClubRalley] = []
            var followCounts: (followers: Int, following: Int) = (0, 0)

            do {
                print("🔵 DEBUG PROFILE_VM - Loading posts...")
                posts = try await postService.loadUserPosts(userId: savedProfile.id)
                print("🔵 DEBUG PROFILE_VM - Loaded \(posts.count) posts")

                print("🔵 DEBUG PROFILE_VM - Loading ralleys...")
                ralleys = try await ralleyService.loadUserRalleys(userId: savedProfile.id)
                print("🔵 DEBUG PROFILE_VM - Loaded \(ralleys.count) ralleys")

                print("🔵 DEBUG PROFILE_VM - Loading follow counts...")
                followCounts = try await friendshipService.getFollowCounts(userId: savedProfile.id)
                print("🔵 DEBUG PROFILE_VM - Followers: \(followCounts.followers), Following: \(followCounts.following)")
            } catch {
                print("🔴 DEBUG PROFILE_VM - Failed to load stats: \(error)")
            }

            currentUserProfile = createProfileFromSavedData(
                savedProfile,
                posts: posts,
                ralleys: ralleys,
                followersCount: followCounts.followers,
                followingCount: followCounts.following
            )
            print("🟢 DEBUG PROFILE_VM - Created profile from saved data")
            isLoading = false
            return
        }

        print("🔵 DEBUG PROFILE_VM - No saved profile, trying Supabase...")
        print("🔵 DEBUG PROFILE_VM - isAuthenticated: \(supabase.isAuthenticated)")
        print("🔵 DEBUG PROFILE_VM - currentUser: \(supabase.currentUser?.id.uuidString ?? "nil")")

        // Try to load from Supabase if user is authenticated
        if supabase.isAuthenticated, let userId = supabase.currentUser?.id {
            print("🔵 DEBUG PROFILE_VM - Loading from Supabase for userId: \(userId)")
            do {
                print("🔵 DEBUG PROFILE_VM - Calling userService.loadUser...")
                let dbUser = try await userService.loadUser(userId)
                print("🔵 DEBUG PROFILE_VM - Loaded user: \(dbUser.first_name) \(dbUser.last_name)")

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
                print("🟢 DEBUG PROFILE_VM - Loaded profile from Supabase")
                isLoading = false
                return
            } catch {
                print("🔴 DEBUG PROFILE_VM - Supabase load FAILED: \(error)")
            }
        }

        // No profile available - user needs to complete onboarding
        print("🔴 DEBUG PROFILE_VM - No user profile available")
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
        // Parse sports with skills from saved data
        let sportsWithSkills = saved.selectedSports.map { sportName in
            UserSportSkill(
                sportName: sportName,
                skillLevel: .intermediate,  // Default, would come from saved data
                iconName: sportIcon(for: sportName)
            )
        }

        // Convert saved college athlete info to model type
        let collegeInfo: CollegeAthleteInfo? = {
            guard let info = saved.collegeAthleteInfo else { return nil }
            return CollegeAthleteInfo(
                sport: info.sport,
                school: info.school,
                division: CollegeDivision(rawValue: info.division) ?? .club,
                yearsPlayed: info.yearsPlayed,
                position: info.position
            )
        }()

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
            bio: saved.bio,
            instagramHandle: saved.instagramHandle,
            profilePhotoURL: saved.profilePhotoURL,
            isVerifiedAthlete: false,
            athleteInfo: nil,
            friendsCount: followersCount,
            ralleysCount: ralleys.count,
            createdAt: saved.createdAt,
            updatedAt: Date(),
            isPrivateAccount: saved.isPrivateAccount ?? false,
            sportsWithSkills: sportsWithSkills,
            playedCollegeSport: saved.playedCollegeSport ?? false,
            collegeAthleteInfo: collegeInfo
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
            instagramHandle: saved.instagramHandle,
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
        // Parse sports from JSONB
        let sportsWithSkills = parseSportsFromDatabase(dbUser.sports)

        // Parse college athlete info from athlete_info JSONB
        let (playedCollege, collegeInfo) = parseCollegeAthleteInfo(dbUser.athlete_info)

        // Parse privacy setting from settings JSONB
        let isPrivate = parsePrivacySetting(dbUser.settings)

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
            updatedAt: dbUser.created_at,  // Lean schema doesn't have updated_at
            isPrivateAccount: isPrivate,
            sportsWithSkills: sportsWithSkills,
            playedCollegeSport: playedCollege,
            collegeAthleteInfo: collegeInfo
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

    // MARK: - Database Parsing Helpers

    /// Parse sports array from JSONB [[String: Any]]?
    private func parseSportsFromDatabase(_ sports: [[String: Any]]?) -> [UserSportSkill] {
        guard let sports = sports else { return [] }

        return sports.compactMap { sportDict -> UserSportSkill? in
            guard let name = sportDict["name"] as? String else { return nil }
            let skillString = sportDict["skill"] as? String ?? "intermediate"
            let skillLevel = SkillLevelType(rawValue: skillString) ?? .intermediate

            return UserSportSkill(
                sportName: name,
                skillLevel: skillLevel,
                iconName: sportIcon(for: name)
            )
        }
    }

    /// Parse college athlete info from athlete_info JSONB
    private func parseCollegeAthleteInfo(_ athleteInfo: [String: Any]?) -> (playedCollege: Bool, info: CollegeAthleteInfo?) {
        guard let info = athleteInfo else { return (false, nil) }

        let playedCollege = info["played_college"] as? Bool ?? false
        guard playedCollege else { return (false, nil) }

        let sport = info["sport"] as? String ?? ""
        let school = info["school"] as? String ?? ""
        let divisionString = info["division"] as? String ?? "club"
        let division = CollegeDivision(rawValue: divisionString) ?? .club
        let yearsPlayed = info["years_played"] as? String
        let position = info["position"] as? String
        let achievements = info["achievements"] as? [String] ?? []

        let collegeInfo = CollegeAthleteInfo(
            sport: sport,
            school: school,
            division: division,
            yearsPlayed: yearsPlayed,
            position: position,
            achievements: achievements
        )

        return (true, collegeInfo)
    }

    /// Parse privacy setting from settings JSONB
    private func parsePrivacySetting(_ settings: [String: Any]?) -> Bool {
        guard let settings = settings else { return false }
        return settings["is_private"] as? Bool ?? false
    }

    /// Get SF Symbol icon for a sport name
    private func sportIcon(for sport: String) -> String {
        switch sport.lowercased() {
        case "tennis": return "tennisball.fill"
        case "basketball": return "basketball.fill"
        case "soccer", "football": return "soccerball"
        case "volleyball": return "volleyball.fill"
        case "baseball": return "baseball.fill"
        case "golf": return "figure.golf"
        case "swimming": return "figure.pool.swim"
        case "pickleball": return "figure.pickleball"
        case "running": return "figure.run"
        case "cycling": return "figure.outdoor.cycle"
        case "hiking": return "figure.hiking"
        case "yoga": return "figure.yoga"
        case "crossfit", "fitness": return "dumbbell.fill"
        case "lacrosse": return "figure.lacrosse"
        case "hockey": return "hockey.puck.fill"
        case "skiing": return "figure.skiing.downhill"
        case "snowboarding": return "figure.snowboarding"
        case "surfing": return "figure.surfing"
        case "boxing": return "figure.boxing"
        case "martial arts", "mma": return "figure.martial.arts"
        case "rowing": return "figure.rowing"
        case "climbing": return "figure.climbing"
        default: return "sportscourt.fill"
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
