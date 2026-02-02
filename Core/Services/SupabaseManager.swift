//
//  SupabaseManager.swift
//  Club Ralley
//
//  Central Supabase client coordinator for Club Ralley
//  Auth methods in SupabaseAuth.swift, Database methods in SupabaseDatabase.swift
//

import Foundation
import SwiftUI
import Supabase

/// SupabaseManager: Central Supabase client for Club Ralley
///
/// Purpose: Manages authentication state and provides database access
/// Strategy: Real Supabase integration with mock fallbacks for development
/// Integration: Used by PostManager, RalleyManager, ProfileViewModel
@MainActor
class SupabaseManager: ObservableObject {

    // MARK: - Singleton Instance

    static let shared = SupabaseManager()

    // MARK: - Published Properties

    /// Authentication status - drives UI state across the app
    @Published var isAuthenticated = false

    /// Current authenticated user
    @Published var currentUser: SupabaseUser?

    /// Connection status for debugging and UI feedback
    @Published var connectionStatus: ConnectionStatus = .connecting

    // MARK: - Internal Properties (accessible to extensions)

    var client: SupabaseClientManager?
    var useFallbackMode = false

    // MARK: - Initialization

    private init() {
        setupSupabaseClient()
        setupAuthListener()
    }

    // MARK: - Setup Methods

    private func setupSupabaseClient() {
        guard SupabaseConfig.isConfigured else {
            print("⚠️ SupabaseManager: Configuration invalid, using fallback mode")
            useFallbackMode = true
            connectionStatus = .fallback
            return
        }

        do {
            client = SupabaseClientManager.shared
            connectionStatus = .connected
            print("✅ SupabaseManager: Real client initialized successfully")
        } catch {
            print("❌ SupabaseManager: Client initialization failed: \(error)")
            useFallbackMode = true
            connectionStatus = .fallback
        }
    }

    private func setupAuthListener() {
        guard let _ = client, !useFallbackMode else {
            print("📡 SupabaseManager: Skipping auth listener setup (fallback mode)")
            return
        }

        Task {
            await checkAuthStatus()
        }
    }
}

// MARK: - Supporting Types

/// Simplified Supabase user type for app-wide use
struct SupabaseUser: Codable, Identifiable {
    let id: UUID
    let email: String
    let firstName: String
    let lastName: String

    var displayName: String {
        return "\(firstName) \(lastName)".trimmingCharacters(in: .whitespaces)
    }
}

/// Connection status for debugging and user feedback
enum ConnectionStatus {
    case connecting
    case connected
    case fallback

    var description: String {
        switch self {
        case .connecting: return "Connecting to backend..."
        case .connected: return "✅ Live backend connected"
        case .fallback: return "📱 Using offline mode"
        }
    }
}

// MARK: - Error Types

extension SupabaseManager {
    /// Error types for Supabase operations
    enum SupabaseError: LocalizedError {
        case notAuthenticated
        case userNotFound
        case networkError(String)
        case invalidData(String)
        case quotaExceeded
        case serverError(String)

        var errorDescription: String? {
            switch self {
            case .notAuthenticated:
                return "Please sign in to continue"
            case .userNotFound:
                return "User account not found"
            case .networkError(let message):
                return "Network error: \(message)"
            case .invalidData(let message):
                return "Data validation error: \(message)"
            case .quotaExceeded:
                return "Service temporarily unavailable"
            case .serverError(let message):
                return "Server error: \(message)"
            }
        }

        var userMessage: String {
            switch self {
            case .notAuthenticated:
                return "Please sign in to access this feature"
            case .userNotFound:
                return "Profile not found"
            case .networkError:
                return "Check your internet connection and try again"
            case .invalidData:
                return "Invalid information provided"
            case .quotaExceeded:
                return "Service busy, please try again later"
            case .serverError:
                return "Something went wrong, please try again"
            }
        }
    }
}
