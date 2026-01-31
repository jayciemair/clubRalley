//
//  ProfileViewModel.swift
//  Club Ralley
//
//  ViewModel for profile management and social interactions
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
    
    // MARK: - Current User Methods
    
    func loadCurrentUserProfile() async {
        isLoading = true
        error = nil
        
        // Use mock data directly for now - clean and simple!
        print("Loading current user profile with mock data")
        currentUserProfile = await generateMockCurrentUserProfile()
        
        // Simulate loading time for realistic UX
        try? await Task.sleep(nanoseconds: 500_000_000)
        
        isLoading = false
    }
    
    func isCurrentUser(_ userId: UUID) -> Bool {
        return currentUserProfile?.user.id == userId
    }
    
    // MARK: - Profile Loading
    
    func loadUserProfile(_ userId: UUID) async -> UserProfile? {
        if let cached = viewedProfiles[userId] {
            return cached
        }
        
        // Use mock data directly - clean and simple!
        print("Loading user profile with mock data for user: \(userId)")
        let mockProfile = await generateMockUserProfile(userId: userId)
        viewedProfiles[userId] = mockProfile
        
        // Simulate loading time for realistic UX
        try? await Task.sleep(nanoseconds: 300_000_000)
        
        return mockProfile
    }
    
    // MARK: - Social Actions
    
    func toggleFollow(_ userId: UUID) async {
        guard let profile = viewedProfiles[userId] else { return }

        let isCurrentlyFollowing = profile.isFollowedByCurrentUser ?? false
        let newFollowState = !isCurrentlyFollowing

        print("Toggling follow for user \(userId): \(isCurrentlyFollowing) -> \(newFollowState)")

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
            print("Follow state synced with backend")
        } catch {
            // Revert optimistic update on failure
            viewedProfiles[userId] = originalProfile
            self.error = .actionFailed("Failed to update follow status")
            print("Failed to sync follow state: \(error)")
        }
    }
    
    func blockUser(_ userId: UUID) async {
        guard let profile = viewedProfiles[userId] else { return }
        
        // For now, just update locally
        // TODO: Implement actual blocking in backend
        var updatedProfile = profile
        updatedProfile = UserProfile(
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
        
        // Simulate API call
        try? await Task.sleep(nanoseconds: 300_000_000)
    }
    
    func reportUser(_ userId: UUID, reason: String) async {
        // TODO: Implement actual reporting in backend
        // Simulate API call to report user
        try? await Task.sleep(nanoseconds: 500_000_000)
        
        // Show confirmation or handle response
        print("Reported user \(userId) for: \(reason)")
    }
    
    // MARK: - Development Helpers
    
    /// Load Gracie King profile for testing
    func loadGracieProfile() async {
        print("Loading Gracie King profile for testing")
        let gracieId = UUID() 
        let gracieProfile = await generateMockUserProfile(userId: gracieId)
        viewedProfiles[gracieId] = gracieProfile
    }
    
    // MARK: - Mock Data Generation
    
    private func generateMockCurrentUserProfile() async -> UserProfile {
        let user = User(
            id: UUID(),
            email: "current@example.com",
            firstName: "Your",
            lastName: "Name",
            username: "yourname",
            dateOfBirth: DateOfBirth(month: 6, year: 1998),
            gender: .female,
            locationCity: "Philadelphia",
            locationState: "PA",
            bio: "Love staying active and making new friends!",
            instagramHandle: "yourname",
            profilePhotoURL: "https://picsum.photos/200/200?random=1",
            isVerifiedAthlete: true,
            athleteInfo: AthleteInfo(
                sport: Sport(id: UUID(), name: "Tennis", category: .individual, iconName: "tennisball.fill", isPopular: true),
                school: School(id: UUID(), name: "Bucknell University", state: "PA", division: .d1, conference: "Patriot League", logoURL: nil),
                verificationStatus: .verified,
                verificationImageURL: nil,
                submittedAt: Date(),
                verifiedAt: Date()
            ),
            friendsCount: 156,
            ralleysCount: 23,
            createdAt: Date().addingTimeInterval(-86400 * 365), // 1 year ago
            updatedAt: Date()
        )
        
        let stats = UserStats(
            followersCount: 156,
            followingCount: 89,
            gamesPlayed: 45,
            wins: 32,
            postsCount: 28,
            ralleysAttended: 23,
            ralleysHosted: 8
        )
        
        let socialInfo = SocialInfo(
            instagramHandle: "yourname",
            linkedinHandle: "your-name",
            twitterHandle: nil,
            isVerifiedAthlete: true,
            verificationBadge: "verified",
            joinedAt: Date().addingTimeInterval(-86400 * 365)
        )
        
        let teams = [
            UserTeam(
                id: UUID(),
                name: "Varsity Tennis",
                sport: "Tennis",
                level: "D1",
                school: "Bucknell University",
                years: "2021-2025",
                imageURL: nil,
                isCurrentTeam: true,
                achievements: ["Conference Champion 2023"]
            ),
            UserTeam(
                id: UUID(),
                name: "Intramural Basketball",
                sport: "Basketball", 
                level: "Intramural",
                school: "Bucknell University",
                years: "2022-2024",
                imageURL: nil,
                isCurrentTeam: false,
                achievements: []
            )
        ]
        
        let photos = Array(1...16).map { index in
            UserPhoto(
                id: UUID(),
                imageURL: "https://picsum.photos/300/300?random=\(index + 100)",
                caption: index % 3 == 0 ? "Great practice session today! #tennis #bucknell" : nil,
                createdAt: Date().addingTimeInterval(-Double(index) * 86400),
                likesCount: Int.random(in: 10...80),
                commentsCount: Int.random(in: 0...20),
                tags: index % 2 == 0 ? ["tennis", "bucknell", "training"] : []
            )
        }
        
        return UserProfile(
            id: UUID(),
            user: user,
            stats: stats,
            socialInfo: socialInfo,
            teams: teams,
            photos: photos,
            mutualFriends: [],
            isFollowedByCurrentUser: nil, // Not applicable for current user
            relationshipStatus: .none
        )
    }
    
    private func generateMockUserProfile(userId: UUID) async -> UserProfile {
        // Generate mock profile similar to Figma design (Gracie King example)
        let user = User(
            id: userId,
            email: "gracie@example.com", 
            firstName: "Gracie",
            lastName: "King",
            username: "gking",
            dateOfBirth: DateOfBirth(month: 3, year: 2002),
            gender: .female,
            locationCity: "Chicago",
            locationState: "IL",
            bio: "Former D1 tennis player passionate about fitness and meeting new people!",
            instagramHandle: "Gking",
            profilePhotoURL: "https://picsum.photos/200/200?random=50",
            isVerifiedAthlete: true,
            athleteInfo: AthleteInfo(
                sport: Sport(id: UUID(), name: "Tennis", category: .individual, iconName: "tennisball.fill", isPopular: true),
                school: School(id: UUID(), name: "Bucknell University", state: "PA", division: .d1, conference: "Patriot League", logoURL: nil),
                verificationStatus: .verified,
                verificationImageURL: nil,
                submittedAt: Date(),
                verifiedAt: Date()
            ),
            friendsCount: 130,
            ralleysCount: 15,
            createdAt: Date().addingTimeInterval(-86400 * 200),
            updatedAt: Date()
        )
        
        let stats = UserStats(
            followersCount: 130,
            followingCount: 95,
            gamesPlayed: 20,
            wins: 10,
            postsCount: 18,
            ralleysAttended: 15,
            ralleysHosted: 3
        )
        
        let socialInfo = SocialInfo(
            instagramHandle: "Gking",
            linkedinHandle: "GracieKing",
            twitterHandle: nil,
            isVerifiedAthlete: true,
            verificationBadge: "verified",
            joinedAt: Date().addingTimeInterval(-86400 * 200)
        )
        
        let teams = [
            UserTeam(
                id: UUID(),
                name: "AVS Club",
                sport: "Volleyball",
                level: "Club",
                school: "Bucknell University",
                years: "2023-2025",
                imageURL: nil,
                isCurrentTeam: true,
                achievements: []
            ),
            UserTeam(
                id: UUID(),
                name: "Basketball Club",
                sport: "Basketball",
                level: "Intramural",
                school: "Bucknell University",
                years: "2021-2023",
                imageURL: nil,
                isCurrentTeam: false,
                achievements: []
            )
        ]
        
        let photos = Array(1...12).map { index in
            UserPhoto(
                id: UUID(),
                imageURL: "https://picsum.photos/300/300?random=\(index + 200)",
                caption: index % 4 == 0 ? "Amazing day on the court! #tennis #chicago" : nil,
                createdAt: Date().addingTimeInterval(-Double(index) * 86400 * 3),
                likesCount: Int.random(in: 15...60),
                commentsCount: Int.random(in: 1...12),
                tags: index % 3 == 0 ? ["tennis", "chicago", "weekend"] : []
            )
        }
        
        let mutualFriends = [
            MutualFriend(
                id: UUID(),
                user: User(
                    id: UUID(),
                    email: "mutual1@example.com",
                    firstName: "Sarah",
                    lastName: "Wilson", 
                    username: "sarahw",
                    dateOfBirth: DateOfBirth(month: 8, year: 2000),
                    gender: .female,
                    locationCity: "Chicago",
                    locationState: "IL",
                    bio: "",
                    instagramHandle: nil,
                    profilePhotoURL: "https://picsum.photos/100/100?random=300",
                    isVerifiedAthlete: false,
                    athleteInfo: nil,
                    friendsCount: 0,
                    ralleysCount: 0,
                    createdAt: Date(),
                    updatedAt: Date()
                )
            )
        ]
        
        return UserProfile(
            id: UUID(),
            user: user,
            stats: stats,
            socialInfo: socialInfo,
            teams: teams,
            photos: photos,
            mutualFriends: mutualFriends,
            isFollowedByCurrentUser: false,
            relationshipStatus: .none
        )
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

// MARK: - Profile Action Types

enum ProfileAction {
    case follow
    case unfollow
}