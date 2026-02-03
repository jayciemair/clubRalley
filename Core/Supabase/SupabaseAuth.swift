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

    /// Sign up with email and password
    func signUp(email: String, password: String) async throws -> UUID {
        guard let client = client, !useFallbackMode else {
            throw SupabaseError.networkError("Supabase not configured")
        }

        let response = try await client.auth.signUp(
            email: email,
            password: password
        )

        let userId: UUID
        switch response {
        case .session(let session):
            userId = session.user.id
            isAuthenticated = true
        case .user(let user):
            userId = user.id
            isAuthenticated = true
        }

        currentUser = SupabaseUser(
            id: userId,
            email: email,
            firstName: "",
            lastName: ""
        )

        print("✅ SupabaseManager: User signed up successfully: \(email)")
        return userId
    }

    /// Sign in with email and password
    func signIn(email: String, password: String) async throws -> UUID {
        guard let client = client, !useFallbackMode else {
            throw SupabaseError.networkError("Supabase not configured")
        }

        let session = try await client.auth.signIn(
            email: email,
            password: password
        )

        isAuthenticated = true
        currentUser = SupabaseUser(
            id: session.user.id,
            email: session.user.email ?? email,
            firstName: "",
            lastName: ""
        )

        print("✅ SupabaseManager: User signed in successfully: \(email)")
        return session.user.id
    }

    /// Sign in with Google (OAuth)
    func signInWithGoogle(idToken: String) async throws -> UUID {
        guard let client = client, !useFallbackMode else {
            throw SupabaseError.networkError("Supabase not configured")
        }

        let session = try await client.auth.signInWithIdToken(
            credentials: .init(provider: .google, idToken: idToken)
        )

        isAuthenticated = true
        currentUser = SupabaseUser(
            id: session.user.id,
            email: session.user.email ?? "",
            firstName: "",
            lastName: ""
        )

        print("✅ SupabaseManager: User signed in with Google successfully")
        return session.user.id
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
            print("✅ SupabaseManager: Session restored for user: \(session.user.email ?? "unknown")")
            return true
        } catch {
            print("📡 SupabaseManager: No existing session - \(error.localizedDescription)")
            isAuthenticated = false
            currentUser = nil
            return false
        }
    }

    /// Fetch user profile from club_users table
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
            locationCity: userData.location_city ?? "",
            locationState: userData.location_state ?? "",
            profilePhotoURL: userData.profile_photo_url,
            selectedSports: [],
            createdAt: userData.created_at ?? Date()
        )
    }

    /// Set authenticated user (called by AuthenticationService)
    func setAuthenticatedUser(_ user: SupabaseUser) {
        isAuthenticated = true
        currentUser = user
        print("SupabaseManager: User authenticated: \(user.email)")
    }

    /// Clear authenticated user (called by AuthenticationService on sign out)
    func clearAuthenticatedUser() {
        isAuthenticated = false
        currentUser = nil
        print("SupabaseManager: User cleared")
    }

    /// Sign out current user and clear all cached data
    func signOut() async {
        if let client = client, !useFallbackMode {
            do {
                try await client.auth.signOut()
                print("🚪 Real Supabase sign out successful")
            } catch {
                print("❌ Supabase sign out error: \(error)")
            }
        }

        isAuthenticated = false
        currentUser = nil
        print("🧹 User session cleared locally")
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
            print("❌ SupabaseManager: Auth check failed: \(error)")
            isAuthenticated = false
            currentUser = nil
        }
    }

    /// Send password reset email
    /// - Parameter email: The email address to send the reset link to
    func resetPassword(email: String) async throws {
        guard let client = client, !useFallbackMode else {
            throw SupabaseError.networkError("Supabase not configured")
        }

        do {
            try await client.auth.resetPasswordForEmail(email)
            print("✅ SupabaseManager: Password reset email sent to: \(email)")
        } catch {
            print("❌ SupabaseManager: Password reset failed: \(error)")
            throw SupabaseError.networkError(error.localizedDescription)
        }
    }

    /// Update user password (after reset)
    /// - Parameter newPassword: The new password to set
    func updatePassword(newPassword: String) async throws {
        guard let client = client, !useFallbackMode else {
            throw SupabaseError.networkError("Supabase not configured")
        }

        do {
            try await client.auth.update(user: .init(password: newPassword))
            print("✅ SupabaseManager: Password updated successfully")
        } catch {
            print("❌ SupabaseManager: Password update failed: \(error)")
            throw SupabaseError.networkError(error.localizedDescription)
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
    let location_city: String?
    let location_state: String?
    let profile_photo_url: String?
    let is_verified_athlete: Bool?
    let friends_count: Int?
    let ralleys_count: Int?
    let created_at: Date?
}
