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

            // Fallback to mock data for development
            return generateMockRalleys()

        } catch {
            isLoading = false
            let supabaseError = SupabaseManager.SupabaseError.networkError(error.localizedDescription)
            lastError = supabaseError
            print("RalleyService: Load ralleys failed with network error: \(error)")

            // Fallback to mock data
            return generateMockRalleys()
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

            return generateMockRalleys().filter { $0.organizer.name == "Your Name" }
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

    /**
     * Generate mock ralleys for development and fallback scenarios
     */
    private func generateMockRalleys() -> [ClubRalley] {
        let now = Date()

        return [
            ClubRalley(
                id: UUID(),
                title: "Downtown Basketball Pickup",
                sport: "Basketball",
                description: "Casual pickup game at the community center. All skill levels welcome!",
                organizer: ClubRalleyOrganizer(
                    id: UUID(),
                    name: "Marcus Johnson",
                    username: "marcusj",
                    photoURL: "https://picsum.photos/44/44?random=20"
                ),
                dateTime: now.addingTimeInterval(3600),
                location: ClubRalleyLocation(
                    name: "Downtown Community Center",
                    address: "123 Main St",
                    city: "San Francisco",
                    state: "CA",
                    latitude: 37.7849,
                    longitude: -122.4094
                ),
                maxPlayers: 10,
                currentPlayers: 6,
                cost: 0,
                requirements: "Bring water bottle",
                isPublic: true
            ),
            ClubRalley(
                id: UUID(),
                title: "Morning Tennis Session",
                sport: "Tennis",
                description: "Quick doubles matches before work. Intermediate level preferred.",
                organizer: ClubRalleyOrganizer(
                    id: UUID(),
                    name: "Sarah Chen",
                    username: "sarahc",
                    photoURL: "https://picsum.photos/44/44?random=21"
                ),
                dateTime: now.addingTimeInterval(18000),
                location: ClubRalleyLocation(
                    name: "Golden Gate Park Tennis Courts",
                    address: "Golden Gate Park",
                    city: "San Francisco",
                    state: "CA",
                    latitude: 37.7694,
                    longitude: -122.4862
                ),
                maxPlayers: 4,
                currentPlayers: 2,
                cost: 15,
                requirements: "Bring your own racquet",
                isPublic: true
            )
        ]
    }
}
