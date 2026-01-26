//
//  SupabaseAuthProvider.swift
//  Checkpoint
//
//  Mock Supabase implementation of the AuthProvider protocol
//

import Foundation
import Supabase

// MARK: - Mock Supabase Auth Provider

/// Mock Supabase implementation of the AuthProvider protocol
public class SupabaseAuthProvider: AuthProvider {

    // MARK: - Properties
    
    private let client: SupabaseClient
    private var mockUser: AuthUserProfile?

    // MARK: - Initialization

    public init(client: SupabaseClient, useMockUser: Bool = true) {
        self.client = client
        if useMockUser {
            let now = Date()
            self.mockUser = AuthUserProfile(
                id: UUID().uuidString,
                email: "test@example.com",
                fullName: nil,
                firstName: "Test",
                lastName: "User",
                provider: .anonymous,
                createdAt: now,
                updatedAt: now
            )
        } else {
            self.mockUser = nil
        }
    }

    public convenience init(supabaseURL: URL, supabaseKey: String, useMockUser: Bool = true) {
        let client = SupabaseClient(supabaseURL: supabaseURL, supabaseKey: supabaseKey)
        self.init(client: client, useMockUser: useMockUser)
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
            let session = try await client.auth.session
            // Determine provider from user metadata
            let provider = detectProvider(from: session.user)
            return try convertToAuthSession(session, provider: provider)
        } catch {
            return nil
        }
    }

    /// Refresh the current session
    public func refreshSession() async throws -> AuthSession? {
        do {
            let session = try await client.auth.refreshSession()
            let provider = detectProvider(from: session.user)
            return try convertToAuthSession(session, provider: provider)
        } catch {
            throw mapSupabaseError(error)
        }
    }

    /// Check if the current session is valid
    public func isSessionValid() async -> Bool {
        do {
            _ = try await client.auth.session
            return true
        } catch {
            return false
        }
    }

    // MARK: - User Profile

    /// Get the current user's profile
    public func getUserProfile() async throws -> AuthUserProfile? {
        do {
            // Access the current session via async API to respect actor isolation
            let session = try await client.auth.session
            let user = session.user
            return convertToUserProfile(user)
        } catch {
            // If there's no session or another error occurs, propagate mapped error
            throw mapSupabaseError(error)
        }
    }

    /// Update the user's profile
    public func updateUserProfile(_ profile: AuthUserProfile) async throws {
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
            let session = try await client.auth.session
            return session.accessToken
        } catch {
            return nil
        }
    }

    /// Get the current refresh token
    public func getRefreshToken() async -> String? {
        do {
            let session = try await client.auth.session
            return session.refreshToken
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
            expiresAt: {
                // Supabase SDK variations:
                // - Some versions expose `expiresAt` as a non-optional TimeInterval (Double)
                // - Others expose it as an optional
                // Handle both by checking at runtime in a type-safe manner
                // If not available, default to distantFuture
                // First, try to read as optional via key-path using Mirror
                let mirror = Mirror(reflecting: session)
                if let child = mirror.children.first(where: { $0.label == "expiresAt" }) {
                    if let optional = child.value as? TimeInterval? {
                        if let value = optional {
                            return Date(timeIntervalSince1970: value)
                        } else {
                            return .distantFuture
                        }
                    } else if let value = child.value as? TimeInterval {
                        return Date(timeIntervalSince1970: value)
                    }
                }
                return .distantFuture
            }(),
            userMetadata: metadata
        )
    }

    /// Convert Supabase User to our AuthUserProfile
    private func convertToUserProfile(_ user: Auth.User) -> AuthUserProfile {
        // Extract names from metadata
        let fullName = user.userMetadata["full_name"]?.stringValue
        let firstName = user.userMetadata["first_name"]?.stringValue
        let lastName = user.userMetadata["last_name"]?.stringValue

        // Detect provider
        let provider = detectProvider(from: user)

        return AuthUserProfile(
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
    private func detectProvider(from user: Auth.User) -> AuthProviderType {
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

