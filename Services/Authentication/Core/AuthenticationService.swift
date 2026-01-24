//
//  AuthenticationService.swift
//  Checkpoint
//
//  Main authentication facade providing a unified interface for all auth providers
//

import Foundation
import SwiftUI
import Combine

// MARK: - Authentication Service

/// Main authentication service that provides a provider-agnostic interface
/// This is the primary interface for authentication throughout the app
@MainActor
public class AuthenticationService: ObservableObject {

    // MARK: - Singleton

    /// Shared instance of the authentication service
    public static let shared = AuthenticationService()

    // MARK: - Published Properties

    /// Current authentication state
    @Published public private(set) var authState: CheckpointAuthState = .unauthenticated

    /// Current authenticated session
    @Published public private(set) var currentSession: AuthSession?

    /// Current user profile
    @Published public private(set) var currentProfile: UserProfile?

    /// Whether user has completed onboarding (from Supabase users table)
    @Published public private(set) var hasCompletedOnboarding: Bool? = nil

    /// Whether user is authenticated
    @Published public private(set) var isAuthenticated: Bool = false

    /// Whether authentication is in progress
    @Published public private(set) var isLoading: Bool = false

    /// Current error if any
    @Published public private(set) var currentError: CheckpointAuthError?

    /// Whether the initial session check has completed
    @Published public private(set) var hasCompletedInitialCheck: Bool = false

    // MARK: - Properties

    /// The current authentication provider
    private var provider: AuthProvider

    /// Cancellables for Combine subscriptions
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization

    private init() {
        // Initialize with the configured provider
        switch AuthConfiguration.currentBackend {
        case .supabase:
            self.provider = SupabaseAuthProvider()
        case .awsCognito:
            // Future: self.provider = CognitoAuthProvider()
            fatalError("AWS Cognito provider not yet implemented")
        case .firebase:
            // Future: self.provider = FirebaseAuthProvider()
            fatalError("Firebase provider not yet implemented")
        }

        // Check for existing session on initialization
        Task {
            await checkExistingSession()
        }
    }

    // MARK: - Provider Management

    /// Switch to a different authentication provider
    /// Warning: This will sign out the current user
    public func switchProvider(_ newProvider: AuthProvider) async {
        // Sign out from current provider
        try? await signOut()

        // Switch provider
        self.provider = newProvider

        // Check for session with new provider
        await checkExistingSession()
    }

    // MARK: - Authentication Methods

    /// Sign in with Apple
    public func signInWithApple(idToken: String) async throws {
        await setAuthState(.authenticating)

        do {
            let session = try await provider.signInWithApple(idToken: idToken)
            await handleSuccessfulAuth(session: session)
        } catch {
            let authError = error as? CheckpointAuthError ?? .unknownError(error.localizedDescription)
            await setAuthState(.error(authError))

            // Log error to Supabase (no user ID available yet during sign in)
            if let session = await provider.getCurrentSession(),
               let userId = UUID(uuidString: session.userId) {
                await ErrorLoggingService.shared.logError(
                    userId: userId,
                    type: .authSignInFailed,
                    error: authError,
                    context: ["provider": "apple"]
                )
            }

            throw authError
        }
    }

    /// Sign in with Google
    public func signInWithGoogle(idToken: String, accessToken: String? = nil) async throws {
        await setAuthState(.authenticating)

        do {
            let session = try await provider.signInWithGoogle(
                idToken: idToken,
                accessToken: accessToken
            )
            await handleSuccessfulAuth(session: session)
        } catch {
            let authError = error as? CheckpointAuthError ?? .unknownError(error.localizedDescription)
            await setAuthState(.error(authError))

            // Log error to Supabase
            if let session = await provider.getCurrentSession(),
               let userId = UUID(uuidString: session.userId) {
                await ErrorLoggingService.shared.logError(
                    userId: userId,
                    type: .authSignInFailed,
                    error: authError,
                    context: ["provider": "google"]
                )
            }

            throw authError
        }
    }

    /// Sign out the current user
    public func signOut() async throws {
        print("[debugFlowTransition] 🚪 AuthenticationService.signOut() CALLED")

        // Capture user ID before signing out
        let userId = currentSession?.userId
        print("[debugFlowTransition] 🚪 Current user ID: \(userId ?? "nil")")

        do {
            print("[debugFlowTransition] 🚪 Calling provider.signOut()...")
            try await provider.signOut()

            // Use the same reliable clear method as the debug button
            print("[debugFlowTransition] 🚪 Clearing stored auth...")
            await SupabaseClientManager.shared.clearStoredAuth()
            UserDefaults.standard.removeObject(forKey: "supabase.auth.token")
            UserDefaults.standard.synchronize()

            // Clean up all blocking systems
            print("[debugFlowTransition] 🚪 Cleaning up blocking systems...")
            await cleanupBlockingSystems()

            // Clear cached subscription status so new account starts fresh
            print("[debugFlowTransition] 🚪 Clearing cached subscription status...")
            UserDefaults.standard.removeObject(forKey: "lastKnownSubscriptionStatus")

            print("[debugFlowTransition] 🚪 Clearing auth state...")
            await clearAuthState()
            print("[debugFlowTransition] ✅ Sign out complete - authState set to .unauthenticated")
        } catch {
            print("[debugFlowTransition] ❌ Sign out failed: \(error.localizedDescription)")
            let authError = error as? CheckpointAuthError ?? .unknownError(error.localizedDescription)

            // Log error to Supabase
            if let userIdString = userId,
               let uuid = UUID(uuidString: userIdString) {
                await ErrorLoggingService.shared.logError(
                    userId: uuid,
                    type: .authSignOutFailed,
                    error: authError,
                    context: [:]
                )
            }

            throw authError
        }
    }

    /// Clean up when signing out
    private func cleanupBlockingSystems() async {
        // Protection cleanup removed - no longer using blocking systems
    }

    // MARK: - Session Management

    /// Check for existing session on app launch
    public func checkExistingSession() async {
        // Mark the start of the check
        defer {
            // Always mark as complete when this function finishes
            Task { @MainActor in
                self.hasCompletedInitialCheck = true
            }
        }

        let session = await provider.getCurrentSession()

        guard let session = session else {
            await clearAuthState()
            return
        }

        // Check if session is expired
        if session.isExpired {
            // Try to refresh
            do {
                if let refreshedSession = try await provider.refreshSession() {
                    await handleSuccessfulAuth(session: refreshedSession)
                } else {
                    await clearAuthState()
                }
            } catch {
                await clearAuthState()
            }
        } else {
            await handleSuccessfulAuth(session: session)
        }
    }

    /// Refresh the current session
    public func refreshSession() async throws {
        guard isAuthenticated else {
            throw CheckpointAuthError.sessionExpired
        }

        let userId = currentSession?.userId

        do {
            if let session = try await provider.refreshSession() {
                await handleSuccessfulAuth(session: session)
            } else {
                throw CheckpointAuthError.sessionExpired
            }
        } catch {
            let authError = error as? CheckpointAuthError ?? .unknownError(error.localizedDescription)
            if authError == .sessionExpired {
                await clearAuthState()
            }

            // Log error to Supabase
            if let userIdString = userId,
               let uuid = UUID(uuidString: userIdString) {
                await ErrorLoggingService.shared.logError(
                    userId: uuid,
                    type: .authSessionRefreshFailed,
                    error: authError,
                    context: [:]
                )
            }

            throw authError
        }
    }

    // MARK: - User Profile

    /// Get the current user's profile
    public func getUserProfile() async throws -> UserProfile? {
        return try await provider.getUserProfile()
    }

    /// Update the user's profile
    public func updateUserProfile(_ profile: UserProfile) async throws {
        try await provider.updateUserProfile(profile)

        // Update local profile
        self.currentProfile = profile
    }

    /// Fetch and update the current profile
    public func fetchCurrentProfile() async {
        guard isAuthenticated else { return }

        do {
            let profile = try await getUserProfile()
            self.currentProfile = profile
        } catch {
        }
    }

    // MARK: - Account Management

    /// Delete the current user's account
    public func deleteAccount() async throws {
        print("[debugFlowTransition] 🗑️ AuthenticationService.deleteAccount() CALLED")

        guard isAuthenticated else {
            throw CheckpointAuthError.sessionExpired
        }

        do {
            print("[debugFlowTransition] 🗑️ Calling provider.deleteAccount()...")
            try await provider.deleteAccount()
            print("[debugFlowTransition] 🗑️ Provider deleteAccount completed")

            // Clean up all blocking systems (same as sign out)
            print("[debugFlowTransition] 🗑️ Cleaning up blocking systems...")
            await cleanupBlockingSystems()

            print("[debugFlowTransition] 🗑️ Clearing auth state...")
            await clearAuthState()
            print("[debugFlowTransition] ✅ Account deletion complete - authState set to .unauthenticated")
        } catch {
            print("[debugFlowTransition] ❌ Account deletion failed: \(error.localizedDescription)")
            let authError = error as? CheckpointAuthError ?? .unknownError(error.localizedDescription)
            throw authError
        }
    }

    // MARK: - Anonymous Authentication

    /// Continue as anonymous user (skip authentication)
    public func continueAsAnonymous() async {
        guard AuthConfiguration.allowAnonymousAuth else {
            await setAuthState(.error(.configurationError("Anonymous authentication is not allowed")))
            return
        }

        // Create anonymous session
        let anonymousSession = AuthSession(
            userId: UUID().uuidString,
            email: nil,
            provider: .anonymous,
            accessToken: nil,
            refreshToken: nil,
            expiresAt: nil,
            userMetadata: ["anonymous": "true"]
        )

        await handleSuccessfulAuth(session: anonymousSession)
    }

    // MARK: - Token Management

    /// Get the current access token
    public func getAccessToken() async -> String? {
        return await provider.getAccessToken()
    }

    /// Get the current refresh token
    public func getRefreshToken() async -> String? {
        return await provider.getRefreshToken()
    }

    // MARK: - Private Helpers

    /// Handle successful authentication
    private func handleSuccessfulAuth(session: AuthSession) async {
        self.currentSession = session
        self.isAuthenticated = true
        await setAuthState(.authenticated(session: session))

        // Fetch user profile
        await fetchCurrentProfile()

        // Fetch/create user profile in Supabase and get onboarding status
        await fetchOrCreateSupabaseProfile()
    }

    /// Clear authentication state
    private func clearAuthState() async {
        self.currentSession = nil
        self.currentProfile = nil
        self.hasCompletedOnboarding = nil
        self.isAuthenticated = false
        await setAuthState(.unauthenticated)
    }

    /// Update authentication state
    private func setAuthState(_ state: CheckpointAuthState) async {
        self.authState = state
        self.isLoading = state.isLoading
        self.currentError = {
            if case .error(let error) = state {
                return error
            }
            return nil
        }()
    }

    // MARK: - Error Handling

    /// Clear current error
    public func clearError() {
        self.currentError = nil
        if case .error = authState {
            self.authState = .unauthenticated
        }
    }

    // MARK: - Configuration

    /// Validate authentication configuration
    public static func validateConfiguration() throws {
        try AuthConfiguration.validate()
    }

    /// Print debug configuration
    public static func printDebugInfo() {
        #if DEBUG
        AuthConfiguration.printConfiguration()
        #endif
    }

    // MARK: - Supabase User Profile Integration

    /// Fetch or create user profile in Supabase users table
    private func fetchOrCreateSupabaseProfile() async {
        guard let session = currentSession,
              let userId = UUID(uuidString: session.userId) else {
            await MainActor.run {
                self.hasCompletedOnboarding = false
            }
            return
        }

        do {
            // When we create the user here, it means they just completed onboarding and signed up
            // So pass hasCompletedOnboarding = true
            let userProfile = try await UserProfileService.shared.getOrCreateUserProfile(
                userId: userId,
                email: session.email,
                hasCompletedOnboarding: true
            )

            // CRITICAL: Update on main thread to trigger @Published
            await MainActor.run {
                self.hasCompletedOnboarding = userProfile.hasCompletedOnboarding
            }

        } catch {
            // Fallback to local UserDefaults as backup
            let localStatus = OnboardingTypeManager.shared.hasCompletedOnboarding(for: .software)
            await MainActor.run {
                self.hasCompletedOnboarding = localStatus
            }
        }
    }

    /// Refresh onboarding status from Supabase
    public func refreshOnboardingStatus() async {
        await fetchOrCreateSupabaseProfile()
    }
}