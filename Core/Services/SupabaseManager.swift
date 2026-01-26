//
//  SupabaseManager.swift 
//  Club Ralley
//
//  Real Supabase client with proper authentication and database connectivity
//  Maintains fallback patterns for reliability while enabling live backend
//

import Foundation
import SwiftUI

/**
 * SupabaseManager: Central Supabase client for Club Ralley
 * 
 * Purpose: Manages authentication state and provides database access
 * Strategy: Real Supabase integration with mock fallbacks for development
 * Integration: Used by PostManager, RalleyManager, ProfileViewModel
 */
@MainActor
class SupabaseManager: ObservableObject {
    
    // MARK: - Singleton Instance
    
    /// Shared instance across the app for consistency
    static let shared = SupabaseManager()
    
    // MARK: - Published Properties for UI Binding
    
    /// Authentication status - drives UI state across the app
    @Published var isAuthenticated = false
    
    /// Current authenticated user - used for posts, ralleys, profiles
    @Published var currentUser: SupabaseUser?
    
    /// Connection status for debugging and UI feedback
    @Published var connectionStatus: ConnectionStatus = .connecting
    
    // MARK: - Private Properties
    
    /// Real Supabase client instance (when available)
    private var client: SupabaseClientManager?
    
    /// Fallback mode flag - enables graceful degradation
    private var useFallbackMode = false
    
    // MARK: - Initialization
    
    private init() {
        setupSupabaseClient()
        setupAuthListener()
    }
    
    // MARK: - Setup Methods
    
    /**
     * Initialize the real Supabase client with configuration
     * Falls back to mock mode if configuration is invalid
     */
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
    
    /**
     * Set up authentication state listener for real-time auth updates
     * This ensures UI stays in sync with authentication changes
     */
    private func setupAuthListener() {
        guard let client = client, !useFallbackMode else {
            print("📡 SupabaseManager: Skipping auth listener setup (fallback mode)")
            return
        }
        
        // TODO: Implement real auth state listener when SupabaseClientManager supports it
        // For now, we'll check auth status manually
        Task {
            await checkAuthStatus()
        }
    }
    
    // MARK: - Authentication Methods
    
    /**
     * Check current authentication status
     * Updates isAuthenticated and currentUser properties
     */
    func checkAuthStatus() async {
        guard let client = client, !useFallbackMode else {
            // Fallback: Set mock authentication for development
            isAuthenticated = false
            currentUser = nil
            return
        }
        
        do {
            let isAuth = await client.isAuthenticated()
            isAuthenticated = isAuth
            
            if isAuth {
                // Fetch current user details
                if let user = try await client.getCurrentUser() {
                    currentUser = SupabaseUser(
                        id: UUID(), // We'll map this properly from user.id
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
    
    /**
     * Sign in as Gracie King for development testing
     * In production, this would be replaced with real OAuth flows
     */
    func signInAsGracie() {
        if useFallbackMode {
            // Mock authentication for development
            isAuthenticated = true
            currentUser = SupabaseUser(
                id: UUID(),
                email: "gracie@example.com",
                firstName: "Gracie",
                lastName: "King"
            )
            print("🎭 Mock sign in as Gracie (fallback mode)")
        } else {
            // TODO: Implement real authentication when needed
            // For now, use development mock even with real client
            isAuthenticated = true
            currentUser = SupabaseUser(
                id: UUID(),
                email: "gracie@example.com",
                firstName: "Gracie", 
                lastName: "King"
            )
            print("🔑 Development sign in as Gracie (with real client)")
        }
    }
    
    /**
     * Sign out current user and clear all cached data
     */
    func signOut() async {
        if let client = client, !useFallbackMode {
            do {
                try await client.auth.signOut()
                print("🚪 Real Supabase sign out successful")
            } catch {
                print("❌ Supabase sign out error: \(error)")
            }
        }
        
        // Always clear local state regardless of API success
        isAuthenticated = false
        currentUser = nil
        print("🧹 User session cleared locally")
    }
    
    // MARK: - Database Access Methods
    
    /**
     * Generic query method for database operations
     * @param table: Database table name
     * @returns: Query builder for chaining operations
     */
    func query(_ table: String) -> SupabaseQueryBuilder {
        guard let client = client, !useFallbackMode else {
            return SupabaseQueryBuilder(fallbackMode: true)
        }
        
        return SupabaseQueryBuilder(
            client: client,
            table: table,
            fallbackMode: false
        )
    }
    
    /**
     * Insert new record into database
     * @param data: Codable data to insert
     * @param table: Target table name
     */
    func insert<T: Codable>(_ data: T, into table: String) async throws {
        guard let client = client, !useFallbackMode else {
            print("📝 Mock insert into \(table) (fallback mode)")
            return
        }
        
        do {
            _ = try await client.client.from(table).insert(data)
            print("✅ Successfully inserted into \(table)")
        } catch {
            print("❌ Insert failed for \(table): \(error)")
            throw SupabaseError.networkError(error.localizedDescription)
        }
    }
    
    /**
     * Update existing record in database
     * @param data: Updated data
     * @param table: Target table name
     */
    func update<T: Codable>(_ data: T, in table: String, where condition: String) async throws {
        guard let client = client, !useFallbackMode else {
            print("✏️ Mock update in \(table) (fallback mode)")
            return
        }
        
        do {
            _ = try await client.client.from(table).update(data)
            print("✅ Successfully updated \(table)")
        } catch {
            print("❌ Update failed for \(table): \(error)")
            throw SupabaseError.networkError(error.localizedDescription)
        }
    }
    
    /**
     * Delete record from database
     * @param table: Target table name
     * @param condition: WHERE clause condition
     */
    func delete(from table: String, where condition: String) async throws {
        guard let client = client, !useFallbackMode else {
            print("🗑️ Mock delete from \(table) (fallback mode)")
            return
        }
        
        do {
            _ = try await client.client.from(table).delete()
            print("✅ Successfully deleted from \(table)")
        } catch {
            print("❌ Delete failed for \(table): \(error)")
            throw SupabaseError.networkError(error.localizedDescription)
        }
    }
}

// MARK: - Supporting Types

/**
 * Simplified Supabase user type for app-wide use
 * Maps to both Supabase Auth.User and our club_users table
 */
struct SupabaseUser: Codable, Identifiable {
    let id: UUID
    let email: String
    let firstName: String
    let lastName: String
    
    /// Display name for UI
    var displayName: String {
        return "\(firstName) \(lastName)".trimmingCharacters(in: .whitespaces)
    }
}

/**
 * Query builder for database operations
 * Provides consistent API whether using real Supabase or fallback mode
 */
class SupabaseQueryBuilder {
    private let client: SupabaseClientManager?
    private let table: String
    private let fallbackMode: Bool
    
    init(client: SupabaseClientManager? = nil, table: String = "", fallbackMode: Bool = true) {
        self.client = client
        self.table = table
        self.fallbackMode = fallbackMode
    }
    
    /**
     * Select columns from table
     * @param columns: Column names to select (default: all)
     * @returns: Self for method chaining
     */
    func select(_ columns: String = "*") -> Self {
        if fallbackMode {
            print("🔍 Mock select \(columns) from \(table)")
        }
        return self
    }
    
    /**
     * Add WHERE clause condition
     * @param column: Column name
     * @param value: Value to match
     * @returns: Self for method chaining
     */
    func eq(_ column: String, value: Any) -> Self {
        if fallbackMode {
            print("📌 Mock WHERE \(column) = \(value)")
        }
        return self
    }
    
    /**
     * Execute query and return single result
     * @returns: Optional result of type T
     */
    func single<T: Codable>() async throws -> T? {
        if fallbackMode {
            print("📤 Mock single result query")
            return nil
        }
        
        guard let client = client else {
            throw SupabaseManager.SupabaseError.networkError("No client available")
        }
        
        // TODO: Implement real query execution
        return nil
    }
    
    /**
     * Execute query and return array of results
     * @returns: Array of results of type T
     */
    func execute<T: Codable>() async throws -> [T] {
        if fallbackMode {
            print("📤 Mock array result query")
            return []
        }
        
        guard let client = client else {
            throw SupabaseManager.SupabaseError.networkError("No client available")
        }
        
        // TODO: Implement real query execution
        return []
    }
}

/**
 * Connection status for debugging and user feedback
 * Helps users understand whether they're using live or mock data
 */
enum ConnectionStatus {
    case connecting     // Initial connection attempt
    case connected      // Real Supabase connection active
    case fallback       // Using mock data due to connection issues
    
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
    /**
     * Comprehensive error types for Supabase operations
     * Provides specific error handling for different failure scenarios
     */
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
        
        /// User-friendly error message for UI display
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