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
@MainActor
class RalleyService: ObservableObject {

    // MARK: - Dependencies

    /// Supabase client for database operations
    private let supabase = SupabaseManager.shared

    // MARK: - Published Properties for UI Feedback

    /// Loading state for UI spinners
    @Published var isLoading = false

    /// Last operation error for user feedback
    @Published var lastError: SupabaseManager.SupabaseError?

    // MARK: - Ralley Creation

    /**
     * Create new ralley in Supabase database
     * @param ralley: ClubRalley to create
     * @returns: Created ralley with database ID and timestamps
     */
    func createRalley(_ ralley: ClubRalley) async throws -> ClubRalley {
        guard supabase.isAuthenticated else {
            throw SupabaseManager.SupabaseError.notAuthenticated
        }

        guard let currentUser = supabase.currentUser else {
            throw SupabaseManager.SupabaseError.userNotFound
        }

        isLoading = true
        lastError = nil

        do {
            // Map ClubRalley to database ralley structure
            let dbRalley = DatabaseRalley(
                host_user_id: currentUser.id,
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

            // Insert into Supabase ralleys table
            try await supabase.insert(dbRalley, into: "ralleys")

            print("RalleyService: Ralley created successfully in database")

            // Return the ralley with updated database info
            var updatedRalley = ralley
            updatedRalley.currentPlayers = 1 // Host is first player

            isLoading = false
            return updatedRalley

        } catch let error as SupabaseManager.SupabaseError {
            isLoading = false
            lastError = error
            print("RalleyService: Create failed with Supabase error: \(error)")
            throw error
        } catch {
            isLoading = false
            let supabaseError = SupabaseManager.SupabaseError.networkError(error.localizedDescription)
            lastError = supabaseError
            print("RalleyService: Create failed with network error: \(error)")
            throw supabaseError
        }
    }

    // MARK: - Ralley Discovery

    /**
     * Load nearby ralleys from database for discovery feed
     * @param latitude: User's current latitude
     * @param longitude: User's current longitude
     * @param radius: Search radius in kilometers
     * @param limit: Maximum number of ralleys to retrieve
     * @returns: Array of nearby ralleys with organizer information
     */
    func loadNearbyRalleys(
        latitude: Double = 37.7749,
        longitude: Double = -122.4194,
        radius: Double = 50.0,
        limit: Int = 20
    ) async throws -> [ClubRalley] {
        isLoading = true
        lastError = nil

        do {
            let ralleys = try await supabase.query("ralleys")
                .select("*, club_users(id, first_name, last_name, username, profile_photo_url)")
                .execute() as [DatabaseRalleyWithUser]

            // Map database results to app models
            let mappedRalleys = ralleys.compactMap { dbRalley in
                mapDatabaseRalleyToApp(dbRalley)
            }

            isLoading = false
            print("RalleyService: Loaded \(mappedRalleys.count) ralleys from database")
            return mappedRalleys

        } catch let error as SupabaseManager.SupabaseError {
            isLoading = false
            lastError = error
            print("RalleyService: Load ralleys failed: \(error)")

            // Return empty array - let UI show empty state
            return []

        } catch {
            isLoading = false
            let supabaseError = SupabaseManager.SupabaseError.networkError(error.localizedDescription)
            lastError = supabaseError
            print("RalleyService: Load ralleys failed with network error: \(error)")

            // Return empty array - let UI show empty state
            return []
        }
    }

    /**
     * Load ralleys for specific user (for profile view)
     * @param userId: User ID to load ralleys for
     * @returns: Array of user's ralleys
     */
    func loadUserRalleys(userId: UUID) async throws -> [ClubRalley] {
        isLoading = true
        lastError = nil

        do {
            let hostedRalleys = try await supabase.query("ralleys")
                .select("*, club_users(id, first_name, last_name, username, profile_photo_url)")
                .eq("host_user_id", value: userId)
                .execute() as [DatabaseRalleyWithUser]

            let mappedRalleys = hostedRalleys.compactMap { dbRalley in
                mapDatabaseRalleyToApp(dbRalley)
            }

            isLoading = false
            print("RalleyService: Loaded \(mappedRalleys.count) user ralleys from database")
            return mappedRalleys

        } catch {
            isLoading = false
            print("RalleyService: Load user ralleys failed: \(error)")

            // Return empty array - let UI show empty state
            return []
        }
    }

    /**
     * Load ralleys that a user has attended/participated in (not hosted)
     * @param userId: User ID to load attended ralleys for
     * @returns: Array of attended ralleys
     */
    func loadAttendedRalleys(userId: UUID) async throws -> [ClubRalley] {
        isLoading = true
        lastError = nil

        do {
            // First get all ralley participations for this user
            let participations: [DatabaseRalleyParticipantWithId] = try await supabase.query("ralley_participants")
                .select("*")
                .eq("user_id", value: userId)
                .eq("status", value: "attending")
                .execute()

            // Then load the actual ralleys
            var attendedRalleys: [ClubRalley] = []
            for participation in participations {
                if let ralley = try await loadRalley(id: participation.ralley_id) {
                    // Only include if user is not the host
                    if ralley.organizer.id != userId {
                        attendedRalleys.append(ralley)
                    }
                }
            }

            isLoading = false
            print("RalleyService: Loaded \(attendedRalleys.count) attended ralleys from database")
            return attendedRalleys

        } catch {
            isLoading = false
            print("RalleyService: Load attended ralleys failed: \(error)")
            return []
        }
    }

    /**
     * Load a single ralley by ID
     * @param ralleyId: Ralley ID to load
     * @returns: The ralley if found
     */
    func loadRalley(id: UUID) async throws -> ClubRalley? {
        isLoading = true
        lastError = nil

        do {
            let ralleys = try await supabase.query("ralleys")
                .select("*, club_users(id, first_name, last_name, username, profile_photo_url)")
                .eq("id", value: id)
                .execute() as [DatabaseRalleyWithUser]

            isLoading = false

            if let dbRalley = ralleys.first {
                return mapDatabaseRalleyToApp(dbRalley)
            }
            return nil

        } catch {
            isLoading = false
            print("RalleyService: Load ralley failed: \(error)")
            return nil
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
                .select("host_user_id")
                .eq("id", value: ralleyId)
                .execute() as [DatabaseRalleyHostCheck]

            guard let ralley = ralleys.first else {
                throw SupabaseManager.SupabaseError.invalidData("Ralley not found")
            }

            guard ralley.host_user_id == currentUser.id else {
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
                .select("host_user_id")
                .eq("id", value: ralleyId)
                .execute() as [DatabaseRalleyHostCheck]

            guard let ralley = ralleys.first, ralley.host_user_id == currentUser.id else {
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
    private func mapDatabaseRalleyToApp(_ dbRalley: DatabaseRalleyWithUser) -> ClubRalley {
        let organizerData = ClubRalleyOrganizer(
            id: dbRalley.organizer.id ?? UUID(),
            name: "\(dbRalley.organizer.first_name) \(dbRalley.organizer.last_name)",
            username: dbRalley.organizer.username,
            photoURL: dbRalley.organizer.profile_photo_url ?? ""
        )

        let location = ClubRalleyLocation(
            name: dbRalley.location_name,
            address: dbRalley.location_address ?? "",
            city: dbRalley.location_city,
            state: dbRalley.location_state,
            latitude: dbRalley.latitude,
            longitude: dbRalley.longitude
        )

        // Determine if current user is captain
        let isCaptain = supabase.currentUser?.id == dbRalley.host_user_id

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
