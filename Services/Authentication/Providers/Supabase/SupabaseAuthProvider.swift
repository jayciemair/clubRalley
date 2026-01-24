//
//  SupabaseAuthProvider.swift
//  Checkpoint
//
//  Supabase implementation of the AuthProvider protocol
//

import Foundation
import Supabase

// MARK: - Supabase Auth Provider

/// Supabase implementation of the AuthProvider protocol
public class SupabaseAuthProvider: AuthProvider {

    // MARK: - Properties

    private let client: SupabaseClientManager

    // MARK: - Initialization

    public init() {
        self.client = SupabaseClientManager.shared
    }

    // MARK: - Authentication Methods

    /// Sign in with Apple ID token
    public func signInWithApple(idToken: String) async throws -> AuthSession {
        do {
            // Sign in with Apple using Supabase
            let session = try await client.auth.signInWithIdToken(
                credentials: .init(
                    provider: .apple,
                    idToken: idToken
                )
            )

            // Convert Supabase session to our AuthSession
            return try convertToAuthSession(session, provider: .apple)
        } catch {
            throw mapSupabaseError(error)
        }
    }

    /// Sign in with Google credentials
    public func signInWithGoogle(idToken: String, accessToken: String?) async throws -> AuthSession {
        do {
            // Sign in with Google using Supabase
            let credentials: OpenIDConnectCredentials

            if let accessToken = accessToken {
                credentials = .init(
                    provider: .google,
                    idToken: idToken,
                    accessToken: accessToken
                )
            } else {
                credentials = .init(
                    provider: .google,
                    idToken: idToken
                )
            }

            let session = try await client.auth.signInWithIdToken(credentials: credentials)

            // Convert Supabase session to our AuthSession
            return try convertToAuthSession(session, provider: .google)
        } catch {
            throw mapSupabaseError(error)
        }
    }

    /// Sign out the current user
    public func signOut() async throws {
        do {
            try await client.auth.signOut()
        } catch {
            throw mapSupabaseError(error)
        }
    }

    // MARK: - Session Management

    /// Get the current authenticated session
    public func getCurrentSession() async -> AuthSession? {
        do {
            let session = try await client.getCurrentSession()

            guard let session = session else {
                return nil
            }

            // Determine provider from user metadata
            let provider = detectProvider(from: session.user)

            let authSession = try? convertToAuthSession(session, provider: provider)
            return authSession
        } catch {
            return nil
        }
    }

    /// Refresh the current session
    public func refreshSession() async throws -> AuthSession? {
        do {
            let session = try await client.auth.refreshSession()

            // Determine provider from user metadata
            let provider = detectProvider(from: session.user)

            return try convertToAuthSession(session, provider: provider)
        } catch {
            throw mapSupabaseError(error)
        }
    }

    /// Check if the current session is valid
    public func isSessionValid() async -> Bool {
        return await client.isAuthenticated()
    }

    // MARK: - User Profile

    /// Get the current user's profile
    public func getUserProfile() async throws -> UserProfile? {
        do {
            guard let user = try await client.getCurrentUser() else {
                return nil
            }

            return convertToUserProfile(user)
        } catch {
            throw mapSupabaseError(error)
        }
    }

    /// Update the user's profile
    public func updateUserProfile(_ profile: UserProfile) async throws {
        do {
            // Update user metadata in Supabase
            let attributes = UserAttributes(
                data: [
                    "full_name": .string(profile.fullName ?? ""),
                    "first_name": .string(profile.firstName ?? ""),
                    "last_name": .string(profile.lastName ?? "")
                ]
            )

            _ = try await client.auth.update(user: attributes)
        } catch {
            throw mapSupabaseError(error)
        }
    }

    // MARK: - Account Management

    /// Delete the user's account
    public func deleteAccount() async throws {
        do {
            // Call Edge Function to delete account
            // This anonymizes chat/journal data and deletes everything else
            // If the function fails, it will throw an error
            try await client.functions.invoke("delete-account")

            // Clear local cached session (same as sign out)
            // This prevents the SDK from trying to use the deleted user's token
            try await client.auth.signOut()
        } catch {
            throw mapSupabaseError(error)
        }
    }

    /// Link an additional provider to existing account
    public func linkProvider(_ request: SignInRequest) async throws {
        // Supabase doesn't directly support provider linking from client
        // This would need to be implemented server-side
        throw CheckpointAuthError.notImplemented
    }

    // MARK: - Token Management

    /// Get the current access token
    public func getAccessToken() async -> String? {
        do {
            let session = try await client.getCurrentSession()
            return session?.accessToken
        } catch {
            return nil
        }
    }

    /// Get the current refresh token
    public func getRefreshToken() async -> String? {
        do {
            let session = try await client.getCurrentSession()
            return session?.refreshToken
        } catch {
            return nil
        }
    }

    // MARK: - Helper Methods

    /// Convert Supabase Session to our AuthSession
    private func convertToAuthSession(_ session: Session, provider: AuthProviderType) throws -> AuthSession {
        // Extract user metadata
        var metadata: [String: String] = [:]

        let userMeta = session.user.userMetadata
        // Convert metadata to string dictionary
        for (key, value) in userMeta {
            metadata[key] = "\(value)"
        }

        return AuthSession(
            userId: session.user.id.uuidString,
            email: session.user.email,
            provider: provider,
            accessToken: session.accessToken,
            refreshToken: session.refreshToken,
            expiresAt: Date(timeIntervalSince1970: TimeInterval(session.expiresAt ?? 0)),
            userMetadata: metadata
        )
    }

    /// Convert Supabase User to our UserProfile
    private func convertToUserProfile(_ user: User) -> UserProfile {
        // Extract names from metadata
        let fullName = user.userMetadata["full_name"]?.stringValue
        let firstName = user.userMetadata["first_name"]?.stringValue
        let lastName = user.userMetadata["last_name"]?.stringValue

        // Detect provider
        let provider = detectProvider(from: user)

        return UserProfile(
            id: user.id.uuidString,
            email: user.email,
            fullName: fullName,
            firstName: firstName,
            lastName: lastName,
            provider: provider,
            createdAt: user.createdAt,
            updatedAt: user.updatedAt ?? user.createdAt
        )
    }

    /// Detect provider from user metadata
    private func detectProvider(from user: User) -> AuthProviderType {
        // Check app metadata for provider
        if let provider = user.appMetadata["provider"]?.stringValue {
            switch provider {
            case "apple":
                return .apple
            case "google":
                return .google
            case "email":
                return .email
            default:
                return .anonymous
            }
        }

        // Fallback to checking identities
        if let identities = user.identities, !identities.isEmpty {
            switch identities.first?.provider {
            case "apple":
                return .apple
            case "google":
                return .google
            case "email":
                return .email
            default:
                return .anonymous
            }
        }

        return .anonymous
    }

    /// Map Supabase errors to our CheckpointAuthError type
    private func mapSupabaseError(_ error: Error) -> CheckpointAuthError {
        // For now, map all errors generically
        // Supabase's error types have changed in v2

        let errorMessage = error.localizedDescription

        // Try to determine error type from message
        if errorMessage.lowercased().contains("invalid") ||
           errorMessage.lowercased().contains("unauthorized") {
            return .invalidCredentials
        } else if errorMessage.lowercased().contains("network") ||
                  errorMessage.lowercased().contains("connection") {
            return .networkError(errorMessage)
        } else if errorMessage.lowercased().contains("expired") ||
                  errorMessage.lowercased().contains("session") {
            return .sessionExpired
        }

        // Check for network errors
        if (error as NSError).domain == NSURLErrorDomain {
            return .networkError(error.localizedDescription)
        }

        // Generic error
        return .unknownError(error.localizedDescription)
    }
}