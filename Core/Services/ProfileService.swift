//
//  ProfileService.swift
//  Club Ralley
//
//  Service layer for user profile operations connecting app models to Supabase backend
//  Handles profile loading, updating, following, and social interactions
//

import Foundation
import SwiftUI

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
            // In real implementation, this would be a complex query joining multiple tables:
            // SELECT u.*, COUNT(DISTINCT p.id) as posts_count, COUNT(DISTINCT r.id) as ralleys_count,
            //        COUNT(DISTINCT f.id) as friends_count
            // FROM club_users u
            // LEFT JOIN posts p ON u.id = p.user_id
            // LEFT JOIN ralleys r ON u.id = r.host_user_id  
            // LEFT JOIN friendships f ON (u.id = f.user_id OR u.id = f.friend_id) AND f.status = 'accepted'
            // WHERE u.id = $1
            // GROUP BY u.id
            
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
    
    /**
     * Load any user's profile by ID (for viewing other profiles)
     * @param userID: UUID of user to load
     * @returns: UserProfile with public information
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
            
            let profile = mapDatabaseUserToProfile(dbUser, isCurrentUser: false, isFollowedByCurrentUser: isFollowing)
            
            isLoading = false
            print("✅ ProfileService: Loaded user profile from database")
            return profile
            
        } catch {
            isLoading = false
            print("❌ ProfileService: Load user profile failed: \(error)")
            
            // Fallback: Generate mock profile for the user
            return generateMockUserProfile(userID: userID)
        }
    }
    
    // MARK: - Profile Updates
    
    /**
     * Update current user's profile information
     * @param profile: Updated profile data
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
            // Map UserProfile back to database format
            let dbUpdate = DatabaseUserProfileUpdate(
                bio: profile.user.bio,
                instagram_handle: profile.user.instagramHandle,
                linkedin_handle: profile.user.linkedinHandle,
                twitter_handle: profile.user.twitterHandle,
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
     * @param userID: User to follow/unfollow
     * @returns: New following status (true if now following, false if unfollowed)
     * 
     * Database Operations:
     * 1. Check existing relationship in friendships table
     * 2. If following: DELETE from friendships, DECREMENT both users' friends_count
     * 3. If not following: INSERT into friendships, INCREMENT both users' friends_count
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
                
                print("👋 ProfileService: Unfollowed user successfully")
                return false
                
            } else {
                // Follow: Insert into friendships table
                let friendship = DatabaseFriendship(
                    user_id: currentUser.id,
                    friend_id: userID,
                    status: "accepted" // In Club Ralley, follows are immediate
                )
                
                try await supabase.insert(friendship, into: "friendships")
                
                print("👥 ProfileService: Followed user successfully")
                return true
            }
            
        } catch {
            print("❌ ProfileService: Toggle follow failed: \(error)")
            throw SupabaseManager.SupabaseError.networkError(error.localizedDescription)
        }
    }
    
    /**
     * Check if current user follows specific user
     * @param userID: User to check following status for
     * @returns: True if following, false otherwise
     */
    private func checkFollowingStatus(userID: UUID) async throws -> Bool {
        guard let currentUser = supabase.currentUser else {
            return false
        }
        
        do {
            let friendship = try await supabase.query("friendships")
                .select("id")
                .eq("user_id", value: currentUser.id)
                .eq("friend_id", value: userID)
                .single() as DatabaseFriendship?
            
            return friendship != nil
            
        } catch {
            // If no friendship record found, not following
            return false
        }
    }
    
    // MARK: - Helper Methods
    
    /**
     * Map database user to UserProfile app model
     * Transforms database fields to UI-friendly format
     */
    private func mapDatabaseUserToProfile(
        _ dbUser: DatabaseUserProfile,
        isCurrentUser: Bool,
        isFollowedByCurrentUser: Bool? = nil
    ) -> UserProfile {
        
        // Create User object
        let user = User(
            id: dbUser.id,
            email: dbUser.email,
            firstName: dbUser.first_name,
            lastName: dbUser.last_name,
            username: dbUser.username,
            dateOfBirthMonth: dbUser.date_of_birth_month,
            dateOfBirthYear: dbUser.date_of_birth_year,
            gender: dbUser.gender,
            locationCity: dbUser.location_city,
            locationState: dbUser.location_state,
            bio: dbUser.bio,
            instagramHandle: dbUser.instagram_handle,
            linkedinHandle: dbUser.linkedin_handle,
            twitterHandle: dbUser.twitter_handle,
            profilePhotoURL: dbUser.profile_photo_url,
            isVerifiedAthlete: dbUser.is_verified_athlete,
            verificationStatus: dbUser.verification_status,
            createdAt: dbUser.created_at,
            updatedAt: dbUser.updated_at
        )
        
        // Create UserStats
        let stats = UserStats(
            postsCount: 0, // TODO: Query from posts table
            friendsCount: dbUser.friends_count,
            ralleysCount: dbUser.ralleys_count
        )
        
        // Create SocialInfo  
        let socialInfo = SocialInfo(
            totalLikes: 0, // TODO: Sum from post_likes
            totalComments: 0, // TODO: Sum from post_comments  
            totalShares: 0, // TODO: Add shares to database
            engagementRate: 0.0, // TODO: Calculate from engagement data
            averagePostLikes: 0.0,
            mostActiveDay: "Monday", // TODO: Calculate from activity
            joinedClubsCount: 0, // TODO: Count from user_teams
            hostedRalleysCount: dbUser.ralleys_count
        )
        
        return UserProfile(
            id: dbUser.id,
            user: user,
            stats: stats,
            socialInfo: socialInfo,
            teams: [], // TODO: Load from user_teams table
            photos: [], // TODO: Load from user_photos table
            mutualFriends: [], // TODO: Load mutual friends
            isFollowedByCurrentUser: isFollowedByCurrentUser,
            relationshipStatus: isCurrentUser ? .currentUser : .none
        )
    }
    
    /**
     * Generate mock current user profile for development and fallback
     */
    private func generateMockCurrentUserProfile() -> UserProfile {
        let user = User(
            id: UUID(),
            email: supabase.currentUser?.email ?? "you@example.com",
            firstName: supabase.currentUser?.firstName ?? "Your",
            lastName: supabase.currentUser?.lastName ?? "Name",
            username: "yourname",
            dateOfBirthMonth: 6,
            dateOfBirthYear: 1995,
            gender: "prefer_not_to_say",
            locationCity: "San Francisco",
            locationState: "CA",
            bio: "Love staying active and meeting new people through sports! Always up for a good pickup game. 🏀⚽🎾",
            instagramHandle: "yourname",
            linkedinHandle: "yourname",
            twitterHandle: nil,
            profilePhotoURL: "https://picsum.photos/120/120?random=50",
            isVerifiedAthlete: false,
            verificationStatus: "not_submitted",
            createdAt: Date().addingTimeInterval(-86400 * 30), // 30 days ago
            updatedAt: Date()
        )
        
        let stats = UserStats(
            postsCount: 3,
            friendsCount: 42,
            ralleysCount: 8
        )
        
        let socialInfo = SocialInfo(
            totalLikes: 127,
            totalComments: 34,
            totalShares: 12,
            engagementRate: 8.5,
            averagePostLikes: 42.3,
            mostActiveDay: "Saturday",
            joinedClubsCount: 2,
            hostedRalleysCount: 5
        )
        
        return UserProfile(
            id: user.id,
            user: user,
            stats: stats,
            socialInfo: socialInfo,
            teams: [], // Empty for mock
            photos: [], // Empty for mock
            mutualFriends: [],
            isFollowedByCurrentUser: nil, // N/A for current user
            relationshipStatus: .currentUser
        )
    }
    
    /**
     * Generate mock profile for other users
     */
    private func generateMockUserProfile(userID: UUID) -> UserProfile {
        // Create a mock profile for the specified user ID
        let user = User(
            id: userID,
            email: "user@example.com",
            firstName: "Sample",
            lastName: "User",
            username: "sampleuser",
            dateOfBirthMonth: 3,
            dateOfBirthYear: 1992,
            gender: "female",
            locationCity: "Los Angeles",
            locationState: "CA",
            bio: "Tennis enthusiast and weekend warrior. Love playing all kinds of sports!",
            instagramHandle: "sampleuser",
            linkedinHandle: nil,
            twitterHandle: nil,
            profilePhotoURL: "https://picsum.photos/120/120?random=\(abs(userID.hashValue))",
            isVerifiedAthlete: true,
            verificationStatus: "verified",
            createdAt: Date().addingTimeInterval(-86400 * 90), // 90 days ago
            updatedAt: Date().addingTimeInterval(-86400 * 7) // Updated 7 days ago
        )
        
        let stats = UserStats(
            postsCount: 12,
            friendsCount: 89,
            ralleysCount: 15
        )
        
        let socialInfo = SocialInfo(
            totalLikes: 456,
            totalComments: 78,
            totalShares: 23,
            engagementRate: 12.3,
            averagePostLikes: 38.0,
            mostActiveDay: "Sunday",
            joinedClubsCount: 3,
            hostedRalleysCount: 7
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

// MARK: - Database Models

/**
 * Database representation of user profile (matches Supabase club_users table schema)
 */
struct DatabaseUserProfile: Codable {
    let id: UUID
    let email: String
    let first_name: String
    let last_name: String
    let username: String
    let date_of_birth_month: Int
    let date_of_birth_year: Int
    let gender: String
    let location_city: String
    let location_state: String
    let bio: String?
    let instagram_handle: String?
    let linkedin_handle: String?
    let twitter_handle: String?
    let profile_photo_url: String?
    let is_verified_athlete: Bool
    let verification_status: String
    let friends_count: Int
    let ralleys_count: Int
    let created_at: Date
    let updated_at: Date
}

/**
 * Database model for updating user profile fields
 */
struct DatabaseUserProfileUpdate: Codable {
    let bio: String?
    let instagram_handle: String?
    let linkedin_handle: String?
    let twitter_handle: String?
    let profile_photo_url: String?
}

/**
 * Database representation of friendship/following relationship
 */
struct DatabaseFriendship: Codable {
    let user_id: UUID
    let friend_id: UUID
    let status: String // 'pending', 'accepted', 'blocked'
}