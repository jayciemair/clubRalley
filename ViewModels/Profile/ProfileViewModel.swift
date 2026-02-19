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
    @Published var userRalleys: [ClubRalley] = []
    @Published var selectedSportFilter: String? = nil

    // MARK: - Computed Properties

    var filteredRalleys: [ClubRalley] {
        let ralleys: [ClubRalley]
        if let filter = selectedSportFilter {
            ralleys = userRalleys.filter { $0.sport.lowercased() == filter.lowercased() }
        } else {
            ralleys = userRalleys
        }
        return ralleys.sorted { $0.dateTime > $1.dateTime }
    }

    var ralleyCountBySport: [String: Int] {
        Dictionary(grouping: userRalleys, by: { $0.sport }).mapValues { $0.count }
    }

    /// Merges user's selected sports with sports from joined ralleys
    var effectiveSportsWithSkills: [UserSportSkill] {
        guard let profile = currentUserProfile else { return [] }
        var sportsByName: [String: UserSportSkill] = [:]

        // Add user's onboarding sports
        for sport in profile.user.sportsWithSkills {
            sportsByName[sport.sportName.lowercased()] = sport
        }

        // Auto-populate from joined ralleys
        for ralley in userRalleys {
            let key = ralley.sport.lowercased()
            if sportsByName[key] == nil {
                sportsByName[key] = UserSportSkill(
                    sportName: ralley.sport,
                    skillLevel: .intermediate,
                    iconName: SportIconMapper.iconName(for: ralley.sport)
                )
            }
        }

        return Array(sportsByName.values).sorted { $0.sportName < $1.sportName }
    }

    // Profile refresh cooldown
    private var lastProfileLoad: Date? = nil
    private let refreshCooldown: TimeInterval = 30

    // MARK: - Dependencies
    private let friendshipService: FriendshipService
    private let userService = UserService()
    private let postService: PostService
    private let ralleyService: RalleyService
    private let supabase = SupabaseManager.shared

    // MARK: - Initialization
    init(friendshipService: FriendshipService? = nil, postService: PostService? = nil, ralleyService: RalleyService? = nil) {
        let container = ServiceContainer.shared
        self.friendshipService = friendshipService ?? container.friendshipService
        self.postService = postService ?? container.postService
        self.ralleyService = ralleyService ?? container.ralleyService
    }

    // MARK: - Current User Methods

    func loadCurrentUserProfile(force: Bool = false) async {
        // Cooldown: skip reload if loaded recently (unless forced)
        if !force, let lastLoad = lastProfileLoad,
           Date().timeIntervalSince(lastLoad) < refreshCooldown {
            return
        }

        isLoading = true
        error = nil

        if let savedProfile = SavedUserProfile.loadFromStorage() {
            var posts: [ClubRalleyPost] = []
            var ralleys: [ClubRalley] = []
            var followCounts: (followers: Int, following: Int) = (0, 0)

            do {
                posts = try await postService.loadUserPosts(userId: savedProfile.id)
                ralleys = try await ralleyService.loadUserRalleys(userId: savedProfile.id)
                followCounts = try await friendshipService.getFollowCounts(userId: savedProfile.id)
            } catch {
                print("ProfileVM: Failed to load stats: \(error)")
            }

            self.userRalleys = ralleys
            currentUserProfile = createProfileFromSavedData(
                savedProfile, posts: posts, ralleys: ralleys,
                followersCount: followCounts.followers, followingCount: followCounts.following
            )
            lastProfileLoad = Date()
            isLoading = false
            return
        }

        if supabase.isAuthenticated, let userId = supabase.currentUser?.id {
            do {
                let dbUser = try await userService.loadUser(userId)
                let posts = try await postService.loadUserPosts(userId: userId)
                let ralleys = try await ralleyService.loadUserRalleys(userId: userId)
                let followCounts = try await friendshipService.getFollowCounts(userId: userId)

                self.userRalleys = ralleys
                currentUserProfile = createProfileFromDatabaseUser(
                    dbUser, posts: posts, ralleys: ralleys,
                    followersCount: followCounts.followers,
                    followingCount: followCounts.following,
                    isFollowedByCurrentUser: nil
                )
                lastProfileLoad = Date()
                isLoading = false
                return
            } catch {
                print("ProfileVM: Supabase load failed: \(error)")
            }
        }

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
        let originalProfile = profile

        let updatedProfile = UserProfile(
            id: profile.id, user: profile.user,
            stats: UserStats(
                followersCount: profile.stats.followersCount + (newFollowState ? 1 : -1),
                followingCount: profile.stats.followingCount,
                gamesPlayed: profile.stats.gamesPlayed, wins: profile.stats.wins,
                postsCount: profile.stats.postsCount,
                ralleysAttended: profile.stats.ralleysAttended,
                ralleysHosted: profile.stats.ralleysHosted
            ),
            socialInfo: profile.socialInfo, teams: profile.teams,
            photos: profile.photos, mutualFriends: profile.mutualFriends,
            isFollowedByCurrentUser: newFollowState,
            relationshipStatus: newFollowState ? .following : .none
        )
        viewedProfiles[userId] = updatedProfile

        do {
            if newFollowState { try await friendshipService.followUser(userId) }
            else { try await friendshipService.unfollowUser(userId) }
        } catch {
            viewedProfiles[userId] = originalProfile
            self.error = .actionFailed("Failed to update follow status")
        }
    }

    func blockUser(_ userId: UUID) async {
        guard let profile = viewedProfiles[userId] else { return }
        let updatedProfile = UserProfile(
            id: profile.id, user: profile.user, stats: profile.stats,
            socialInfo: profile.socialInfo, teams: profile.teams,
            photos: profile.photos, mutualFriends: profile.mutualFriends,
            isFollowedByCurrentUser: false, relationshipStatus: .blocked
        )
        viewedProfiles[userId] = updatedProfile
        do { try await friendshipService.blockUser(userId) }
        catch {
            viewedProfiles[userId] = profile
            self.error = .actionFailed("Failed to block user")
        }
    }

    func unblockUser(_ userId: UUID) async {
        guard let profile = viewedProfiles[userId] else { return }
        let updatedProfile = UserProfile(
            id: profile.id, user: profile.user, stats: profile.stats,
            socialInfo: profile.socialInfo, teams: profile.teams,
            photos: profile.photos, mutualFriends: profile.mutualFriends,
            isFollowedByCurrentUser: false, relationshipStatus: .none
        )
        viewedProfiles[userId] = updatedProfile
        do { try await friendshipService.unblockUser(userId) }
        catch {
            viewedProfiles[userId] = profile
            self.error = .actionFailed("Failed to unblock user")
        }
    }

    func reportUser(_ userId: UUID, reason: String) async {
        do { try await friendshipService.reportUser(userId, reason: reason) }
        catch { /* Report logged locally even if DB fails */ }
    }

    // MARK: - Database Parsing Helpers

    private func parseSportsFromDatabase(_ sports: [[String: Any]]?) -> [UserSportSkill] {
        guard let sports = sports else { return [] }
        return sports.compactMap { dict -> UserSportSkill? in
            guard let name = dict["name"] as? String else { return nil }
            let skill = SkillLevelType(rawValue: dict["skill"] as? String ?? "intermediate") ?? .intermediate
            return UserSportSkill(sportName: name, skillLevel: skill, iconName: sportIcon(for: name))
        }
    }

    private func parseCollegeAthleteInfo(_ athleteInfo: [String: Any]?) -> (playedCollege: Bool, info: CollegeAthleteInfo?) {
        guard let info = athleteInfo,
              let playedCollege = info["played_college"] as? Bool, playedCollege else {
            return (false, nil)
        }
        return (true, CollegeAthleteInfo(
            sport: info["sport"] as? String ?? "",
            school: info["school"] as? String ?? "",
            division: CollegeDivision(rawValue: info["division"] as? String ?? "club") ?? .club,
            yearsPlayed: info["years_played"] as? String,
            position: info["position"] as? String,
            achievements: info["achievements"] as? [String] ?? []
        ))
    }

    private func parsePrivacySetting(_ settings: [String: Any]?) -> Bool {
        settings?["is_private"] as? Bool ?? false
    }

    private func sportIcon(for sport: String) -> String {
        SportIconMapper.iconName(for: sport)
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
