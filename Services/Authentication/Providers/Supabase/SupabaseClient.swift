//
//  SupabaseClient.swift
//  Checkpoint
//
//  Wrapper for Supabase client initialization and management
//

import Foundation
import Supabase

public typealias SupabaseAuthUser = Auth.User

// MARK: - Supabase Client Manager

/// Manages the Supabase client instance
@MainActor
public class SupabaseClientManager: ObservableObject {

    // MARK: - Singleton

    /// Shared instance of the Supabase client manager
    public static let shared = SupabaseClientManager()

    // MARK: - Properties

    /// The Supabase client instance
    public let client: SupabaseClient

    /// Auth client for easier access
    public var auth: AuthClient {
        client.auth
    }

    /// Whether the initial session check has completed
    @Published public private(set) var hasCompletedInitialSessionCheck = false

    // MARK: - Initialization

    private init() {
        print("🔵🔵🔵 helloWORLD SupabaseClientManager INIT START")
        print("🔵🔵🔵 helloWORLD - supabaseURL: \(AuthConfiguration.supabaseURL)")
        print("🔵🔵🔵 helloWORLD - anonKey: \(AuthConfiguration.supabaseAnonKey.prefix(30))...")

        // Get configuration from AuthConfiguration
        guard let url = URL(string: AuthConfiguration.supabaseURL) else {
            print("🔴🔴🔴 helloWORLD SupabaseClientManager FATAL - Invalid URL")
            fatalError("Invalid Supabase URL configuration: \(AuthConfiguration.supabaseURL)")
        }
        let key = AuthConfiguration.supabaseAnonKey

        // Initialize the Supabase client with simplified options
        self.client = SupabaseClient(
            supabaseURL: url,
            supabaseKey: key
        )

        print("🟢🟢🟢 helloWORLD SupabaseClientManager INIT SUCCESS - client created")

        // Setup auth state listener
        setupAuthStateListener()
    }

    // MARK: - Auth State Listener

    private func setupAuthStateListener() {
        // Listen for auth state changes
        Task {
            for await (event, session) in client.auth.authStateChanges {
                await handleAuthStateChange(event: event, session: session)
            }
        }
    }

    private func handleAuthStateChange(event: AuthChangeEvent, session: Session?) async {
        switch event {
        case .initialSession:
            await MainActor.run {
                hasCompletedInitialSessionCheck = true
            }

        case .signedIn:
            break

        case .signedOut:
            break

        case .passwordRecovery:
            break

        case .tokenRefreshed:
            break

        case .userUpdated:
            break

        case .mfaChallengeVerified:
            break

        default:
            break
        }
    }

    // MARK: - Helper Methods

    /// Get the current session
    internal func getCurrentSession() async throws -> Session? {
        return try await client.auth.session
    }

    /// Get the current user
    internal func getCurrentUser() async throws -> Auth.User? {
        guard let session = try await getCurrentSession() else {
            return nil
        }
        return session.user
    }

    /// Check if user is authenticated
    public func isAuthenticated() async -> Bool {
        do {
            let session = try await getCurrentSession()
            return session != nil
        } catch {
            return false
        }
    }

    // MARK: - Database Access

    /// Access to the database client
    public var database: PostgrestClient {
        client.database
    }

    /// Access to the storage client
    public var storage: SupabaseStorageClient {
        client.storage
    }

    /// Access to the functions client
    public var functions: FunctionsClient {
        client.functions
    }

    /// Access to the realtime client
    public var realtime: RealtimeClientV2 {
        client.realtimeV2
    }

    // MARK: - Validation

    /// Clear all stored authentication (for testing)
    public func clearStoredAuth() async {
        do {
            try await client.auth.signOut()
        } catch {
        }
    }

    /// Validate that Supabase is properly configured
    public static func validateConfiguration() throws {
        guard !AuthConfiguration.supabaseURL.isEmpty else {
            throw CheckpointAuthError.configurationError("Supabase URL is not configured")
        }

        guard !AuthConfiguration.supabaseAnonKey.isEmpty else {
            throw CheckpointAuthError.configurationError("Supabase anonymous key is not configured")
        }

        guard AuthConfiguration.supabaseURL.contains("supabase.co") ||
              AuthConfiguration.supabaseURL.contains("localhost") else {
            throw CheckpointAuthError.configurationError("Invalid Supabase URL format")
        }
    }
}

