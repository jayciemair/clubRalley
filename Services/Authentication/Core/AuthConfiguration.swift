//
//  AuthConfiguration.swift
//  Checkpoint
//
//  Configuration management for authentication providers
//

import Foundation

// MARK: - Auth Backend

/// Available authentication backend providers
public enum AuthBackend: String, CaseIterable {
    case supabase = "supabase"
    case awsCognito = "aws_cognito"
    case firebase = "firebase"

    var displayName: String {
        switch self {
        case .supabase: return "Supabase"
        case .awsCognito: return "AWS Cognito"
        case .firebase: return "Firebase"
        }
    }
}

// MARK: - Auth Configuration

/// Central configuration for authentication
public struct AuthConfiguration {

    // MARK: - Current Provider

    /// The currently active authentication backend
    /// Change this to switch providers
    public static var currentBackend: AuthBackend = .supabase

    // MARK: - Environment Detection

    /// Current environment
    public enum Environment: String {
        case development = "development"
        case staging = "staging"
        case production = "production"

        static var current: Environment {
            #if DEBUG
            return .development
            #else
            return .production
            #endif
        }
    }

    // MARK: - Supabase Configuration

    /// Supabase project URL
    public static var supabaseURL: String {
        // Use centralized configuration
        return AppConfig.Supabase.projectURL
    }

    /// Supabase anonymous key
    public static var supabaseAnonKey: String {
        // Use centralized configuration
        return AppConfig.Supabase.anonKey
    }

    // MARK: - Google Sign In Configuration

    /// Google OAuth Client ID
    public static var googleClientID: String {
        // Use centralized configuration
        return AppConfig.Google.clientID
    }

    /// Google reversed client ID for URL scheme
    public static var googleReversedClientID: String {
        // This is used for URL scheme configuration
        let components = googleClientID.components(separatedBy: ".")
        return components.reversed().joined(separator: ".")
    }

    // MARK: - AWS Cognito Configuration (Future)

    /// AWS Cognito User Pool ID
    public static var cognitoUserPoolId: String {
        if let poolId = Bundle.main.object(forInfoDictionaryKey: "AWS_COGNITO_USER_POOL_ID") as? String,
           !poolId.isEmpty {
            return poolId
        }
        return "your-cognito-user-pool-id"
    }

    /// AWS Cognito Client ID
    public static var cognitoClientId: String {
        if let clientId = Bundle.main.object(forInfoDictionaryKey: "AWS_COGNITO_CLIENT_ID") as? String,
           !clientId.isEmpty {
            return clientId
        }
        return "your-cognito-client-id"
    }

    /// AWS Region
    public static var awsRegion: String {
        if let region = Bundle.main.object(forInfoDictionaryKey: "AWS_REGION") as? String,
           !region.isEmpty {
            return region
        }
        return "us-east-1"
    }

    // MARK: - Feature Flags

    /// Whether to allow anonymous/skip authentication
    public static var allowAnonymousAuth: Bool {
        #if DEBUG
        return true  // Allow in development
        #else
        return false // Require auth in production
        #endif
    }

    /// Whether to show provider selection (future feature)
    public static var showProviderSelection: Bool = false

    /// Enable biometric authentication
    public static var enableBiometricAuth: Bool = true

    // MARK: - Validation

    /// Validate that required configuration is present
    public static func validate() throws {
        switch currentBackend {
        case .supabase:
            guard !supabaseURL.isEmpty,
                  !supabaseURL.contains("your-"),
                  supabaseURL.contains("supabase.co") else {
                throw CheckpointAuthError.configurationError("Invalid Supabase URL configuration")
            }

            guard !supabaseAnonKey.isEmpty,
                  !supabaseAnonKey.contains("your-") else {
                throw CheckpointAuthError.configurationError("Invalid Supabase anonymous key configuration")
            }

        case .awsCognito:
            guard !cognitoUserPoolId.isEmpty,
                  !cognitoUserPoolId.contains("your-") else {
                throw CheckpointAuthError.configurationError("Invalid Cognito User Pool ID configuration")
            }

            guard !cognitoClientId.isEmpty,
                  !cognitoClientId.contains("your-") else {
                throw CheckpointAuthError.configurationError("Invalid Cognito Client ID configuration")
            }

        case .firebase:
            throw CheckpointAuthError.notImplemented
        }

        // Validate Google Sign In if needed
        if !googleClientID.isEmpty && !googleClientID.contains("your-") {
            // Google Sign In is configured
        }
    }

    // MARK: - Debug Helpers

    /// Print current configuration (for debugging)
    public static func printConfiguration() {
        #if DEBUG
        #endif
    }
}