//
//  SupabaseAuth.swift
//  Club Ralley
//
//  Authentication methods for SupabaseManager
//

import Foundation
import Supabase

// MARK: - Authentication Extension

extension SupabaseManager {

    /// Send OTP code to phone number via SMS
    /// - Parameter phone: Phone number in E.164 format (e.g. "+15551234567")
    func sendOTP(phone: String) async throws {
        guard let client = client, !useFallbackMode else {
            throw SupabaseError.networkError("Supabase not configured")
        }

        try await client.auth.signInWithOTP(phone: phone)
        print("✅ SupabaseManager: OTP sent to \(phone)")
    }

    /// Verify OTP code and authenticate user
    /// - Parameters:
    ///   - phone: Phone number in E.164 format (e.g. "+15551234567")
    ///   - code: 6-digit verification code
    /// - Returns: The authenticated user's UUID
    func verifyOTP(phone: String, code: String) async throws -> UUID {
        guard let client = client, !useFallbackMode else {
            throw SupabaseError.networkError("Supabase not configured")
        }

        let response = try await client.auth.verifyOTP(
            phone: phone,
            token: code,
            type: .sms
        )

        let userId: UUID
        switch response {
        case .session(let session):
            userId = session.user.id
        case .user(let user):
            userId = user.id
        }

        isAuthenticated = true
        currentUser = SupabaseUser(
            id: userId,
            email: "",
            firstName: "",
            lastName: ""
        )

        print("✅ SupabaseManager: OTP verified, userId: \(userId)")
        return userId
    }

    /// Restore existing session on app launch
    func restoreSession() async -> Bool {
        guard let client = client, !useFallbackMode else {
            return false
        }

        do {
            let session = try await client.auth.session
            isAuthenticated = true
            currentUser = SupabaseUser(
                id: session.user.id,
                email: session.user.email ?? "",
                firstName: "",
                lastName: ""
            )
            print("✅ SupabaseManager: Session restored for user: \(session.user.id)")
            return true
        } catch {
            print("📡 SupabaseManager: No existing session - \(error.localizedDescription)")
            isAuthenticated = false
            currentUser = nil
            return false
        }
    }

    /// Fetch user profile from users table
    func fetchUserProfile(userId: UUID) async throws -> SavedUserProfile? {
        guard let client = client, !useFallbackMode else {
            return nil
        }

        let response: [ClubUserResponse] = try await client.database
            .from("club_users")
            .select()
            .eq("id", value: userId.uuidString)
            .execute()
            .value

        guard let userData = response.first else {
            return nil
        }

        return SavedUserProfile(
            id: userData.id,
            email: userData.email,
            firstName: userData.first_name,
            lastName: userData.last_name,
            username: userData.username,
            phoneNumber: userData.phone_number ?? "",
            locationCity: userData.city ?? "",
            locationState: userData.state ?? "",
            profilePhotoURL: userData.profile_photo_url,
            selectedSports: [],
            createdAt: userData.created_at ?? Date()
        )
    }

    /// Set authenticated user (called by AuthenticationService)
    func setAuthenticatedUser(_ user: SupabaseUser) {
        isAuthenticated = true
        currentUser = user
    }

    /// Clear authenticated user (called by AuthenticationService on sign out)
    func clearAuthenticatedUser() {
        isAuthenticated = false
        currentUser = nil
    }

    /// Sign out current user and clear all cached data
    func signOut() async {
        if let client = client, !useFallbackMode {
            do {
                try await client.auth.signOut()
            } catch {
                print("❌ Supabase sign out error: \(error)")
            }
        }

        isAuthenticated = false
        currentUser = nil
    }

    /// Check current authentication status
    func checkAuthStatus() async {
        guard let client = client, !useFallbackMode else {
            isAuthenticated = false
            currentUser = nil
            return
        }

        do {
            let isAuth = await client.isAuthenticated()
            isAuthenticated = isAuth

            if isAuth {
                if let user = try await client.getCurrentUser() {
                    currentUser = SupabaseUser(
                        id: user.id,
                        email: user.email ?? "",
                        firstName: "",
                        lastName: ""
                    )
                }
            } else {
                currentUser = nil
            }
        } catch {
            isAuthenticated = false
            currentUser = nil
        }
    }
}

// MARK: - Internal Types

/// Database model for reading club users (internal to auth)
struct ClubUserResponse: Codable {
    let id: UUID
    let email: String
    let first_name: String
    let last_name: String
    let username: String
    let phone_number: String?
    let city: String?
    let state: String?
    let profile_photo_url: String?
    let is_verified_athlete: Bool?
    let friends_count: Int?
    let ralleys_count: Int?
    let created_at: Date?
}
