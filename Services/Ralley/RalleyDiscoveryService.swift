//
//  RalleyDiscoveryService.swift
//  Club Ralley
//
//  Discovery methods for RalleyService: nearby ralleys, user ralleys,
//  attended ralleys, and single-ralley lookup.
//

import Foundation
import SwiftUI

extension RalleyService {

    // MARK: - Ralley Discovery

    /**
     * Load nearby ralleys from database for discovery feed
     * Uses server-side location filtering when coordinates are provided
     * Filters out ralleys hosted by blocked users
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
        limit: Int = 20,
        offset: Int = 0
    ) async throws -> [ClubRalley] {
        isLoading = true
        lastError = nil

        do {
            // Refresh blocked users cache if needed (every 5 minutes)
            await sharedUserState.refreshBlockedUsersIfNeeded()

            // Try server-side location filtering first
            let ralleys: [DatabaseRalleyWithUser]
            do {
                ralleys = try await loadNearbyRalleysWithRPC(
                    latitude: latitude,
                    longitude: longitude,
                    radius: radius,
                    limit: limit
                )
            } catch {
                // Fallback: same filters (active, ordered, limited) so results are consistent
                print("⚠️ RalleyService: RPC failed, falling back to client-side filtering: \(error)")
                ralleys = try await supabase.query("ralleys")
                    .select("*, club_users(id, first_name, last_name, username, profile_photo_url)")
                    .eq("status", value: "active")
                    .order("date_time", ascending: true)
                    .range(from: offset, to: offset + limit - 1)
                    .execute()
            }

            // Check if current user is a verified college athlete
            let isCollegeAthlete = SavedUserProfile.loadFromStorage()?.playedCollegeSport == true

            // Map database results to app models, filter blocked users and enforce visibility
            let mappedRalleys = ralleys
                .filter { !self.sharedUserState.isBlocked($0.host_id) }
                .filter { dbRalley in
                    // Filter out college_athletes_only ralleys for non-athletes
                    if dbRalley.visibility == "college_athletes_only" && !isCollegeAthlete {
                        return false
                    }
                    return true
                }
                .compactMap { dbRalley in
                    mapDatabaseRalleyToApp(dbRalley)
                }

            isLoading = false
            print("✅ RalleyService: Loaded \(mappedRalleys.count) ralleys (filtered \(ralleys.count - mappedRalleys.count) blocked)")
            return mappedRalleys

        } catch let error as SupabaseManager.SupabaseError {
            isLoading = false
            lastError = error
            print("❌ RalleyService: Load nearby ralleys failed: \(error)")
            throw error

        } catch {
            isLoading = false
            let supabaseError = SupabaseManager.SupabaseError.networkError(error.localizedDescription)
            lastError = supabaseError
            print("❌ RalleyService: Load nearby ralleys failed with network error: \(error)")
            throw supabaseError
        }
    }

    /// Load nearby ralleys using server-side RPC function
    private func loadNearbyRalleysWithRPC(
        latitude: Double,
        longitude: Double,
        radius: Double,
        limit: Int
    ) async throws -> [DatabaseRalleyWithUser] {
        let params = NearbyRalleysParams(
            user_lat: Decimal(latitude),
            user_lon: Decimal(longitude),
            radius_km: Int(radius),
            max_results: limit
        )

        // Call RPC to get nearby ralleys with distance
        let nearbyRalleys: [DatabaseNearbyRalley] = try await supabase.rpc("get_nearby_ralleys", params: params)

        // Batch fetch full ralley data with user info
        let ralleyIds = nearbyRalleys.map { $0.id }
        guard !ralleyIds.isEmpty else { return [] }

        let fullRalleys: [DatabaseRalleyWithUser] = try await supabase.query("ralleys")
            .select("*, club_users(id, first_name, last_name, username, profile_photo_url)")
            .in("id", values: ralleyIds)
            .execute()

        return fullRalleys
    }

    /// Force refresh of blocked users cache
    func refreshBlockedUsers() async {
        await sharedUserState.forceRefresh()
    }

    /**
     * Load more ralleys for infinite scroll
     * @param currentCount: Current number of ralleys loaded
     * @param limit: Number of additional ralleys to load
     * @returns: Array of additional ralleys
     */
    func loadMoreRalleys(currentCount: Int, limit: Int = 20) async throws -> [ClubRalley] {
        return try await loadNearbyRalleys(limit: limit, offset: currentCount)
    }

    /**
     * Load ralleys for specific user (for profile view)
     * @param userId: User ID to load ralleys for
     * @returns: Array of user's ralleys
     */
    func loadUserRalleys(userId: UUID, limit: Int = 50, offset: Int = 0) async throws -> [ClubRalley] {
        isLoading = true
        lastError = nil

        do {
            let hostedRalleys = try await supabase.query("ralleys")
                .select("*, club_users(id, first_name, last_name, username, profile_photo_url)")
                .eq("host_id", value: userId)
                .range(from: offset, to: offset + limit - 1)
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
            throw error
        }
    }

    /**
     * Load ralleys that a user has attended/participated in (not hosted)
     * @param userId: User ID to load attended ralleys for
     * @returns: Array of attended ralleys
     */
    func loadAttendedRalleys(userId: UUID, limit: Int = 50, offset: Int = 0) async throws -> [ClubRalley] {
        isLoading = true
        lastError = nil

        do {
            // Get participations with pagination
            let participations: [DatabaseRalleyParticipantWithId] = try await supabase.query("ralley_participants")
                .select("*")
                .eq("user_id", value: userId)
                .eq("status", value: "joined")
                .range(from: offset, to: offset + limit - 1)
                .execute()

            // Batch load ralleys with .in() instead of N+1 loop
            let ralleyIds = participations.map { $0.ralley_id }
            guard !ralleyIds.isEmpty else {
                isLoading = false
                return []
            }

            let ralleys: [DatabaseRalleyWithUser] = try await supabase.query("ralleys")
                .select("*, club_users(id, first_name, last_name, username, profile_photo_url)")
                .in("id", values: ralleyIds)
                .execute()

            let attendedRalleys = ralleys
                .compactMap { mapDatabaseRalleyToApp($0) }
                .filter { $0.organizer.id != userId }

            isLoading = false
            print("RalleyService: Loaded \(attendedRalleys.count) attended ralleys from database")
            return attendedRalleys

        } catch {
            isLoading = false
            print("RalleyService: Load attended ralleys failed: \(error)")
            throw error
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
}
