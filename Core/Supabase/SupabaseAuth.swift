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
        print("[supaTennis] 📱 sendOTP() called with phone: \(phone)")
        print("[supaTennis] 📱 client nil? \(client == nil), fallback? \(useFallbackMode)")
        guard let client = client, !useFallbackMode else {
            print("[supaTennis] ❌ sendOTP BLOCKED — no client or fallback mode")
            throw SupabaseError.networkError("Supabase not configured")
        }

        do {
            try await client.auth.signInWithOTP(phone: phone)
            print("[supaTennis] ✅ OTP sent successfully to \(phone)")
        } catch {
            print("[supaTennis] ❌ sendOTP FAILED: \(error)")
            print("[supaTennis] ❌ sendOTP error type: \(type(of: error))")
            print("[supaTennis] ❌ sendOTP localizedDescription: \(error.localizedDescription)")
            throw error
        }
    }

    /// Verify OTP code and authenticate user
    /// - Parameters:
    ///   - phone: Phone number in E.164 format (e.g. "+15551234567")
    ///   - code: 6-digit verification code
    /// - Returns: The authenticated user's UUID
    func verifyOTP(phone: String, code: String) async throws -> UUID {
        print("[supaTennis] 🔐 verifyOTP() called — phone: \(phone), code length: \(code.count)")
        print("[supaTennis] 🔐 client nil? \(client == nil), fallback? \(useFallbackMode)")
        guard let client = client, !useFallbackMode else {
            print("[supaTennis] ❌ verifyOTP BLOCKED — no client or fallback mode")
            throw SupabaseError.networkError("Supabase not configured")
        }

        do {
            let response = try await client.auth.verifyOTP(
                phone: phone,
                token: code,
                type: .sms
            )

            let userId: UUID
            switch response {
            case .session(let session):
                userId = session.user.id
                print("[supaTennis] ✅ verifyOTP got SESSION — userId: \(userId)")
            case .user(let user):
                userId = user.id
                print("[supaTennis] ✅ verifyOTP got USER (no session) — userId: \(userId)")
            }

            isAuthenticated = true
            currentUser = SupabaseUser(
                id: userId,
                email: "",
                firstName: "",
                lastName: ""
            )

            print("[supaTennis] ✅ verifyOTP complete — isAuthenticated: \(isAuthenticated)")
            return userId
        } catch {
            print("[supaTennis] ❌ verifyOTP FAILED: \(error)")
            print("[supaTennis] ❌ verifyOTP error type: \(type(of: error))")
            throw error
        }
    }

    /// Restore existing session on app launch
    func restoreSession() async -> Bool {
        print("[supaTennis] 🔄 restoreSession() called — client nil? \(client == nil), fallback? \(useFallbackMode)")
        guard let client = client, !useFallbackMode else {
            print("[supaTennis] ⚠️ restoreSession returning false — no client or fallback")
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
            print("[supaTennis] ✅ restoreSession SUCCESS — userId: \(session.user.id)")
            return true
        } catch {
            print("[supaTennis] ❌ restoreSession FAILED: \(error.localizedDescription)")
            isAuthenticated = false
            currentUser = nil
            return false
        }
    }

    /// Fetch user profile from users table
    func fetchUserProfile(userId: UUID) async throws -> SavedUserProfile? {
        print("[supaTennis] 🔍 fetchUserProfile() called — userId: \(userId)")
        print("[supaTennis] 🔍 client nil? \(client == nil), fallback? \(useFallbackMode)")
        guard let client = client, !useFallbackMode else {
            print("[supaTennis] ⚠️ fetchUserProfile returning nil — no client or fallback")
            return nil
        }

        do {
            let response: [ClubUserResponse] = try await client.database
                .from("club_users")
                .select()
                .eq("id", value: userId.uuidString)
                .execute()
                .value

            print("[supaTennis] 🔍 fetchUserProfile got \(response.count) rows from club_users")

            guard let userData = response.first else {
                print("[supaTennis] ⚠️ fetchUserProfile — no matching user found")
                return nil
            }

            print("[supaTennis] ✅ fetchUserProfile found user: \(userData.username), email: \(userData.email)")
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
        } catch {
            print("[supaTennis] ❌ fetchUserProfile FAILED: \(error)")
            throw error
        }
    }

    // MARK: - Anonymous Auth

    /// Sign in anonymously (for development — Twilio SMS auth coming later)
    func signInAnonymously() async throws -> UUID {
        print("[supaTennis] 🔑 signInAnonymously() called")
        guard let client = client, !useFallbackMode else {
            print("[supaTennis] ❌ signInAnonymously BLOCKED — no client or fallback mode")
            throw SupabaseError.networkError("Supabase not configured")
        }

        do {
            let session = try await client.auth.signInAnonymously()
            let userId = session.user.id
            isAuthenticated = true
            currentUser = SupabaseUser(
                id: userId,
                email: "",
                firstName: "",
                lastName: ""
            )
            print("[supaTennis] ✅ signInAnonymously SUCCESS — userId: \(userId)")
            return userId
        } catch {
            print("[supaTennis] ❌ signInAnonymously FAILED: \(error)")
            throw error
        }
    }

    // MARK: - Email Auth

    /// Sign up with email and password
    func signUpWithEmail(email: String, password: String) async throws -> UUID {
        print("[supaTennis] 📧 signUpWithEmail() called — email: \(email)")
        guard let client = client, !useFallbackMode else {
            print("[supaTennis] ❌ signUpWithEmail BLOCKED — no client or fallback mode")
            throw SupabaseError.networkError("Supabase not configured")
        }

        do {
            let response = try await client.auth.signUp(email: email, password: password)
            let userId = response.user.id
            isAuthenticated = true
            currentUser = SupabaseUser(
                id: userId,
                email: email,
                firstName: "",
                lastName: ""
            )
            print("[supaTennis] ✅ signUpWithEmail SUCCESS — userId: \(userId)")
            return userId
        } catch {
            print("[supaTennis] ❌ signUpWithEmail FAILED: \(error)")
            print("[supaTennis] ❌ signUpWithEmail localizedDescription: \(error.localizedDescription)")
            throw error
        }
    }

    /// Sign in with email and password
    func signInWithEmail(email: String, password: String) async throws -> UUID {
        print("[supaTennis] 📧 signInWithEmail() called — email: \(email)")
        guard let client = client, !useFallbackMode else {
            print("[supaTennis] ❌ signInWithEmail BLOCKED — no client or fallback mode")
            throw SupabaseError.networkError("Supabase not configured")
        }

        do {
            let session = try await client.auth.signIn(email: email, password: password)
            let userId = session.user.id
            isAuthenticated = true
            currentUser = SupabaseUser(
                id: userId,
                email: email,
                firstName: "",
                lastName: ""
            )
            print("[supaTennis] ✅ signInWithEmail SUCCESS — userId: \(userId)")
            return userId
        } catch {
            print("[supaTennis] ❌ signInWithEmail FAILED: \(error)")
            throw error
        }
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
