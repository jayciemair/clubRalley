//
//  RalleyService.swift
//  Club Ralley
//
//  Core service for ralley CRUD operations connecting app models to Supabase backend.
//  Handles ralley creation, retrieval, and location-based discovery.
//

import Foundation
import SwiftUI

/**
 * RalleyService: Bridge between RalleyManager and Supabase ralleys table
 *
 * Purpose: Handles core ralley-related database operations (CRUD)
 * Strategy: Real Supabase calls with mock fallbacks for reliability
 * Database: Maps ClubRalley model to 'ralleys' table
 */
// MARK: - Protocol

@MainActor
protocol RalleyServiceProtocol: ObservableObject {
    var isLoading: Bool { get }
    var lastError: SupabaseManager.SupabaseError? { get }
    func createRalley(_ ralley: ClubRalley) async throws -> ClubRalley
    func loadNearbyRalleys(latitude: Double, longitude: Double, radius: Double, limit: Int) async throws -> [ClubRalley]
    func loadMoreRalleys(currentCount: Int, limit: Int) async throws -> [ClubRalley]
    func loadUserRalleys(userId: UUID, limit: Int, offset: Int) async throws -> [ClubRalley]
    func loadAttendedRalleys(userId: UUID, limit: Int, offset: Int) async throws -> [ClubRalley]
    func loadRalley(id: UUID) async throws -> ClubRalley?
    func updateRalley(_ ralley: ClubRalley) async throws -> ClubRalley
    func deleteRalley(_ ralleyId: UUID) async throws
    func removeParticipant(userId: UUID, from ralleyId: UUID) async throws
}

@MainActor
class RalleyService: ObservableObject, RalleyServiceProtocol {

    // MARK: - Dependencies

    /// Supabase client for database operations
    let supabase = SupabaseManager.shared

    /// Friendship service for block filtering
    private let friendshipService: FriendshipService

    /// Shared blocked user state
    let sharedUserState: SharedUserState

    // MARK: - Published Properties for UI Feedback

    /// Loading state for UI spinners
    @Published var isLoading = false

    /// Last operation error for user feedback
    @Published var lastError: SupabaseManager.SupabaseError?

    // MARK: - Initialization

    init(friendshipService: FriendshipService, sharedUserState: SharedUserState) {
        self.friendshipService = friendshipService
        self.sharedUserState = sharedUserState
    }

    convenience init() {
        let fs = FriendshipService()
        self.init(friendshipService: fs, sharedUserState: SharedUserState(friendshipService: fs))
    }

    // MARK: - Ralley Creation

    /**
     * Create new ralley in Supabase database
     * @param ralley: ClubRalley to create
     * @returns: Created ralley with database ID and timestamps
     */
    func createRalley(_ ralley: ClubRalley) async throws -> ClubRalley {
        // Get user ID from SupabaseManager or fall back to SavedUserProfile
        var hostUserId: UUID?

        if let currentUser = supabase.currentUser {
            hostUserId = currentUser.id
        } else if let savedProfile = SavedUserProfile.loadFromStorage() {
            hostUserId = savedProfile.id
        }

        guard let userId = hostUserId else {
            throw SupabaseManager.SupabaseError.userNotFound
        }

        isLoading = true
        lastError = nil

        do {
            print("📝 RalleyService: Creating ralley '\(ralley.title)' for user \(userId)")

            // Map ClubRalley to database ralley structure
            let dbRalley = DatabaseRalley(
                host_user_id: userId,
                title: ralley.title,
                description: ralley.description,
                location_name: ralley.location.name,
                location_address: ralley.location.address,
                location_city: ralley.location.city,
                location_state: ralley.location.state,
                latitude: ralley.location.latitude,
                longitude: ralley.location.longitude,
                date_time: ralley.dateTime,
                sport_id: nil,
                category: mapSportToCategory(ralley.sport),
                max_participants: ralley.maxPlayers,
                current_participants: 1,
                is_public: ralley.visibility == .anyone,
                visibility: ralley.visibility.rawValue,
                join_type: ralley.joinType.rawValue
            )

            // Insert into Supabase ralleys table and get the ID back
            let ralleyId = try await supabase.insertReturningId(dbRalley, into: "ralleys")
            print("✅ RalleyService: Ralley created with ID \(ralleyId)")

            // Return the ralley with updated database info
            var updatedRalley = ralley
            // Note: id is let constant, database generates its own ID
            updatedRalley.currentPlayers = 1 // Host is first player

            isLoading = false
            return updatedRalley

        } catch let error as SupabaseManager.SupabaseError {
            isLoading = false
            lastError = error
            print("❌ RalleyService: Create failed with SupabaseError: \(error.localizedDescription ?? "unknown")")
            throw error
        } catch {
            isLoading = false
            let supabaseError = SupabaseManager.SupabaseError.networkError(error.localizedDescription)
            lastError = supabaseError
            print("❌ RalleyService: Create failed with error: \(error)")
            throw supabaseError
        }
    }

    // MARK: - Ralley Update

    /**
     * Update an existing ralley in Supabase database
     * @param ralley: Updated ClubRalley data
     * @returns: Updated ralley
     */
    func updateRalley(_ ralley: ClubRalley) async throws -> ClubRalley {
        guard supabase.isAuthenticated else {
            throw SupabaseManager.SupabaseError.notAuthenticated
        }

        guard let currentUser = supabase.currentUser else {
            throw SupabaseManager.SupabaseError.userNotFound
        }

        // Verify user is the captain/host
        guard ralley.organizer.id == currentUser.id else {
            throw SupabaseManager.SupabaseError.invalidData("Only the captain can edit this ralley")
        }

        isLoading = true
        lastError = nil

        do {
            let updateData = DatabaseRalleyUpdate(
                title: ralley.title,
                description: ralley.description,
                location_name: ralley.location.name,
                location_address: ralley.location.address,
                location_city: ralley.location.city,
                location_state: ralley.location.state,
                latitude: ralley.location.latitude,
                longitude: ralley.location.longitude,
                date_time: ralley.dateTime,
                category: mapSportToCategory(ralley.sport),
                max_participants: ralley.maxPlayers,
                is_public: ralley.visibility == .anyone,
                visibility: ralley.visibility.rawValue,
                join_type: ralley.joinType.rawValue
            )

            try await supabase.update(updateData, in: "ralleys", where: "id = '\(ralley.id)'")

            print("RalleyService: Ralley updated successfully")
            isLoading = false
            return ralley

        } catch let error as SupabaseManager.SupabaseError {
            isLoading = false
            lastError = error
            print("RalleyService: Update failed with Supabase error: \(error)")
            throw error
        } catch {
            isLoading = false
            let supabaseError = SupabaseManager.SupabaseError.networkError(error.localizedDescription)
            lastError = supabaseError
            print("RalleyService: Update failed with network error: \(error)")
            throw supabaseError
        }
    }

    // MARK: - Ralley Delete

    /**
     * Delete a ralley from Supabase database
     * @param ralleyId: ID of the ralley to delete
     */
    func deleteRalley(_ ralleyId: UUID) async throws {
        guard supabase.isAuthenticated else {
            throw SupabaseManager.SupabaseError.notAuthenticated
        }

        guard let currentUser = supabase.currentUser else {
            throw SupabaseManager.SupabaseError.userNotFound
        }

        isLoading = true
        lastError = nil

        do {
            // Verify ownership before deleting
            let ralleys = try await supabase.query("ralleys")
                .select("host_id")
                .eq("id", value: ralleyId)
                .execute() as [DatabaseRalleyHostCheck]

            guard let ralley = ralleys.first else {
                throw SupabaseManager.SupabaseError.invalidData("Ralley not found")
            }

            guard ralley.host_id == currentUser.id else {
                throw SupabaseManager.SupabaseError.invalidData("Only the captain can delete this ralley")
            }

            // Delete associated participants first
            try? await supabase.delete(from: "ralley_participants", where: "ralley_id = '\(ralleyId)'")

            // Delete the ralley
            try await supabase.delete(from: "ralleys", where: "id = '\(ralleyId)'")

            print("RalleyService: Ralley deleted successfully")
            isLoading = false

        } catch let error as SupabaseManager.SupabaseError {
            isLoading = false
            lastError = error
            print("RalleyService: Delete failed with Supabase error: \(error)")
            throw error
        } catch {
            isLoading = false
            let supabaseError = SupabaseManager.SupabaseError.networkError(error.localizedDescription)
            lastError = supabaseError
            print("RalleyService: Delete failed with network error: \(error)")
            throw supabaseError
        }
    }

    // MARK: - Participant Management

    /**
     * Remove a participant from a ralley
     * @param userId: ID of the user to remove
     * @param ralleyId: ID of the ralley
     */
    func removeParticipant(userId: UUID, from ralleyId: UUID) async throws {
        guard supabase.isAuthenticated else {
            throw SupabaseManager.SupabaseError.notAuthenticated
        }

        guard let currentUser = supabase.currentUser else {
            throw SupabaseManager.SupabaseError.userNotFound
        }

        isLoading = true
        lastError = nil

        do {
            // Verify current user is captain
            let ralleys = try await supabase.query("ralleys")
                .select("host_id")
                .eq("id", value: ralleyId)
                .execute() as [DatabaseRalleyHostCheck]

            guard let ralley = ralleys.first, ralley.host_id == currentUser.id else {
                throw SupabaseManager.SupabaseError.invalidData("Only the captain can remove participants")
            }

            // Remove the participant
            try await supabase.delete(
                from: "ralley_participants",
                where: "ralley_id = '\(ralleyId)' AND user_id = '\(userId)'"
            )

            // Note: Participant count is derived from the ralley_participants table
            // No need to maintain a separate counter

            print("RalleyService: Participant removed successfully")
            isLoading = false

        } catch let error as SupabaseManager.SupabaseError {
            isLoading = false
            lastError = error
            throw error
        } catch {
            isLoading = false
            let supabaseError = SupabaseManager.SupabaseError.networkError(error.localizedDescription)
            lastError = supabaseError
            throw supabaseError
        }
    }

    // MARK: - Helper Methods

    /**
     * Map sport name to database category
     */
    private func mapSportToCategory(_ sport: String) -> String {
        switch sport.lowercased() {
        case "basketball", "football", "soccer", "volleyball", "baseball":
            return "sports"
        case "yoga", "running", "cycling", "gym":
            return "fitness"
        case "hiking", "surfing", "climbing":
            return "outdoor"
        default:
            return "recreational"
        }
    }

    /**
     * Map database ralley result to app model
     */
    func mapDatabaseRalleyToApp(_ dbRalley: DatabaseRalleyWithUser) -> ClubRalley {
        let organizerData = ClubRalleyOrganizer(
            id: dbRalley.organizer.id ?? UUID(),
            name: "\(dbRalley.organizer.first_name) \(dbRalley.organizer.last_name)",
            username: dbRalley.organizer.username,
            photoURL: dbRalley.organizer.profile_photo_url ?? ""
        )

        // Convert optional Decimal to Double
        let lat = dbRalley.latitude.map { NSDecimalNumber(decimal: $0).doubleValue } ?? 0.0
        let lon = dbRalley.longitude.map { NSDecimalNumber(decimal: $0).doubleValue } ?? 0.0

        let location = ClubRalleyLocation(
            name: dbRalley.location_name ?? "Location",
            address: dbRalley.location_address ?? "",
            city: dbRalley.location_city,
            state: dbRalley.location_state,
            latitude: lat,
            longitude: lon
        )

        // Determine if current user is captain
        let isCaptain = supabase.currentUser?.id == dbRalley.host_id

        // Parse visibility and join type from database
        let visibility = RalleyVisibility(rawValue: dbRalley.visibility ?? "anyone") ?? .anyone
        let joinType = RalleyJoinType(rawValue: dbRalley.join_type ?? "open") ?? .open

        return ClubRalley(
            id: dbRalley.id,
            title: dbRalley.title,
            sport: mapCategoryToSport(dbRalley.category),
            description: dbRalley.description ?? "",
            organizer: organizerData,
            dateTime: dbRalley.date_time,
            location: location,
            maxPlayers: dbRalley.max_participants ?? 0,
            currentPlayers: dbRalley.current_participants,
            cost: 0,
            requirements: "",
            isPublic: dbRalley.is_public,
            visibility: visibility,
            joinType: joinType,
            isCaptain: isCaptain,
            chatId: nil,
            pendingRequestsCount: 0
        )
    }

    /**
     * Map database category back to sport name
     */
    private func mapCategoryToSport(_ category: String) -> String {
        switch category {
        case "sports": return "Basketball"
        case "fitness": return "Fitness"
        case "outdoor": return "Hiking"
        default: return "Sports"
        }
    }
}

// MARK: - RPC Helper Structs

/// Parameters for get_nearby_ralleys RPC function
struct NearbyRalleysParams: Encodable {
    let user_lat: Decimal?
    let user_lon: Decimal?
    let radius_km: Int
    let max_results: Int
}

/// Result from get_nearby_ralleys RPC function
struct DatabaseNearbyRalley: Codable {
    let id: UUID
    let host_id: UUID
    let title: String
    let description: String?
    let sport: String?
    let skill_level: String?
    let location_name: String?
    let location_address: String?
    let city: String?
    let state: String?
    let latitude: Decimal?
    let longitude: Decimal?
    let date_time: Date
    let duration_minutes: Int?
    let max_participants: Int?
    let current_participants: Int?
    let is_public: Bool?
    let status: String?
    let created_at: Date?
    let updated_at: Date?
    let distance_km: Decimal?
}
