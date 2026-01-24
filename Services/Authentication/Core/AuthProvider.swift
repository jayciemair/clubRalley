//
//  AuthProvider.swift
//  Checkpoint
//
//  Protocol definition for authentication providers
//

import Foundation

// MARK: - AuthProvider Protocol

/// Protocol that all authentication providers must conform to
/// This ensures consistent interface regardless of backend (Supabase, AWS, Firebase, etc.)
public protocol AuthProvider {

    // MARK: - Authentication Methods

    /// Sign in with Apple ID token
    /// - Parameter idToken: The ID token from Apple Sign In
    /// - Returns: Authenticated session
    func signInWithApple(idToken: String) async throws -> AuthSession

    /// Sign in with Google credentials
    /// - Parameters:
    ///   - idToken: The ID token from Google Sign In
    ///   - accessToken: Optional access token from Google
    /// - Returns: Authenticated session
    func signInWithGoogle(idToken: String, accessToken: String?) async throws -> AuthSession

    /// Sign out the current user
    func signOut() async throws

    // MARK: - Session Management

    /// Get the current authenticated session if exists
    /// - Returns: Current session or nil if not authenticated
    func getCurrentSession() async -> AuthSession?

    /// Refresh the current session
    /// - Returns: Refreshed session or nil if refresh failed
    func refreshSession() async throws -> AuthSession?

    /// Check if the current session is valid
    /// - Returns: true if session exists and is not expired
    func isSessionValid() async -> Bool

    // MARK: - User Profile

    /// Get the current user's profile
    /// - Returns: User profile or nil if not authenticated
    func getUserProfile() async throws -> UserProfile?

    /// Update the user's profile
    /// - Parameter profile: Updated profile information
    func updateUserProfile(_ profile: UserProfile) async throws

    // MARK: - Account Management

    /// Delete the user's account
    /// This should handle all cleanup including remote deletion
    func deleteAccount() async throws

    /// Link an additional provider to existing account
    /// - Parameter request: Sign in request with provider credentials
    func linkProvider(_ request: SignInRequest) async throws

    // MARK: - Token Management

    /// Get the current access token
    /// - Returns: Current access token or nil
    func getAccessToken() async -> String?

    /// Get the current refresh token
    /// - Returns: Current refresh token or nil
    func getRefreshToken() async -> String?
}

// MARK: - Optional Protocol Extensions

public extension AuthProvider {

    /// Default implementation for session validity check
    func isSessionValid() async -> Bool {
        guard let session = await getCurrentSession() else {
            return false
        }
        return !session.isExpired
    }

    /// Default implementation for linking provider (not all providers support this)
    func linkProvider(_ request: SignInRequest) async throws {
        throw CheckpointAuthError.notImplemented
    }

    /// Default implementation for getting access token from session
    func getAccessToken() async -> String? {
        let session = await getCurrentSession()
        return session?.accessToken
    }

    /// Default implementation for getting refresh token from session
    func getRefreshToken() async -> String? {
        let session = await getCurrentSession()
        return session?.refreshToken
    }
}