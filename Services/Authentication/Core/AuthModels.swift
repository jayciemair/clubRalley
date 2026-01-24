//
//  AuthModels.swift
//  Checkpoint
//
//  Shared authentication models and types used across all providers
//

import Foundation

// MARK: - Authentication Session

/// Represents an authenticated user session, provider-agnostic
public struct AuthSession: Codable, Equatable {
    let userId: String
    let email: String?
    let provider: AuthProviderType
    let accessToken: String?
    let refreshToken: String?
    let expiresAt: Date?
    let userMetadata: [String: String]

    var isExpired: Bool {
        guard let expiresAt = expiresAt else { return false }
        return Date() > expiresAt
    }
}

// MARK: - Provider Types

/// Supported authentication providers
public enum AuthProviderType: String, Codable, CaseIterable {
    case apple = "apple"
    case google = "google"
    case email = "email"
    case anonymous = "anonymous"

    var displayName: String {
        switch self {
        case .apple: return "Apple"
        case .google: return "Google"
        case .email: return "Email"
        case .anonymous: return "Anonymous"
        }
    }
}

// MARK: - User Profile

/// User profile information
public struct UserProfile: Codable, Equatable {
    var id: String
    var email: String?
    var fullName: String?
    var firstName: String?
    var lastName: String?
    var provider: AuthProviderType
    var createdAt: Date
    var updatedAt: Date

    /// Computed display name
    var displayName: String {
        if let fullName = fullName, !fullName.isEmpty {
            return fullName
        }
        if let firstName = firstName, !firstName.isEmpty {
            if let lastName = lastName, !lastName.isEmpty {
                return "\(firstName) \(lastName)"
            }
            return firstName
        }
        if let email = email {
            return email.components(separatedBy: "@").first ?? "User"
        }
        return "User"
    }
}

// MARK: - Authentication State

/// Current authentication state for Checkpoint
public enum CheckpointAuthState: Equatable {
    case unauthenticated
    case authenticating
    case authenticated(session: AuthSession)
    case error(CheckpointAuthError)

    var isAuthenticated: Bool {
        if case .authenticated = self {
            return true
        }
        return false
    }

    var isLoading: Bool {
        if case .authenticating = self {
            return true
        }
        return false
    }
}

// MARK: - Authentication Errors

/// Authentication-related errors for Checkpoint app
public enum CheckpointAuthError: LocalizedError, Equatable {
    case invalidCredentials
    case networkError(String)
    case sessionExpired
    case userCancelled
    case providerError(String)
    case configurationError(String)
    case unknownError(String)
    case notImplemented

    public var errorDescription: String? {
        switch self {
        case .invalidCredentials:
            return "Invalid credentials provided"
        case .networkError(let message):
            return "Network error: \(message)"
        case .sessionExpired:
            return "Your session has expired. Please sign in again."
        case .userCancelled:
            return "Sign in was cancelled"
        case .providerError(let message):
            return "Provider error: \(message)"
        case .configurationError(let message):
            return "Configuration error: \(message)"
        case .unknownError(let message):
            return "An error occurred: \(message)"
        case .notImplemented:
            return "This feature is not yet implemented"
        }
    }

    public var recoverySuggestion: String? {
        switch self {
        case .invalidCredentials:
            return "Please check your credentials and try again"
        case .networkError:
            return "Please check your internet connection and try again"
        case .sessionExpired:
            return "Please sign in again to continue"
        case .userCancelled:
            return "You can try signing in again when ready"
        case .providerError:
            return "Please try again or contact support if the issue persists"
        case .configurationError:
            return "Please contact support for assistance"
        case .unknownError:
            return "Please try again later"
        case .notImplemented:
            return "This feature will be available in a future update"
        }
    }
}

// MARK: - Sign In Request

/// Request data for authentication
public struct SignInRequest {
    let provider: AuthProviderType
    let idToken: String?
    let accessToken: String?
    let nonce: String?
    let authorizationCode: String?

    init(
        provider: AuthProviderType,
        idToken: String? = nil,
        accessToken: String? = nil,
        nonce: String? = nil,
        authorizationCode: String? = nil
    ) {
        self.provider = provider
        self.idToken = idToken
        self.accessToken = accessToken
        self.nonce = nonce
        self.authorizationCode = authorizationCode
    }
}

// MARK: - Token Response

/// Response containing authentication tokens
public struct TokenResponse: Codable {
    let accessToken: String
    let refreshToken: String?
    let idToken: String?
    let expiresIn: Int
    let tokenType: String

    var expiresAt: Date {
        Date().addingTimeInterval(TimeInterval(expiresIn))
    }
}