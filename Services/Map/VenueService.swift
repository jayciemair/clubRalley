//
//  VenueService.swift
//  Club Ralley
//
//  Service for loading venues from the Supabase venues table
//  and discovering new venues via the Overpass (OpenStreetMap) API
//

import Foundation

@MainActor
class VenueService {

    private let supabase = SupabaseManager.shared
    private let overpass = OverpassService()

    /// Cache staleness threshold — skip Overpass if OSM data is younger than this
    private static let cacheMaxAge: TimeInterval = 24 * 60 * 60 // 24 hours

    // MARK: - Venue Discovery (Overpass + Supabase)

    /// Discovers venues near a coordinate via Overpass, caches them in Supabase,
    /// and returns the full merged venue list.
    /// Falls back to Supabase-only data on any Overpass failure.
    func discoverVenues(
        latitude: Double,
        longitude: Double,
        city: String,
        state: String,
        radiusMeters: Int = 5000,
        forceRefresh: Bool = false
    ) async throws -> [Venue] {
        // 1. Load existing raw venues from Supabase
        let dbVenues = try await loadRawVenues(city: city, state: state)
        let existingVenues = dbVenues.map { toVenue($0) }

        // 2. Check cache staleness — skip Overpass if recent enough
        if !forceRefresh && hasRecentOSMData(in: dbVenues) {
            return existingVenues
        }

        // 3. Fetch from Overpass (gracefully falls back on failure)
        let osmVenues: [OverpassVenue]
        do {
            osmVenues = try await overpass.discoverVenues(
                latitude: latitude,
                longitude: longitude,
                radiusMeters: radiusMeters
            )
        } catch {
            print("VenueService: Overpass failed, returning cached data: \(error)")
            return existingVenues
        }

        guard !osmVenues.isEmpty else { return existingVenues }

        // 4. Deduplicate — skip OSM venues within 30m of existing manual venues
        let newVenues = osmVenues.filter { osm in
            !existingVenues.contains { existing in
                haversineDistance(
                    lat1: osm.latitude, lon1: osm.longitude,
                    lat2: existing.latitude, lon2: existing.longitude
                ) < 30
            }
        }

        guard !newVenues.isEmpty else { return existingVenues }

        // 5. Batch upsert to Supabase
        let now = ISO8601DateFormatter().string(from: Date())
        let inserts = newVenues.map { osm in
            DatabaseVenueInsert(
                name: osm.name,
                address: "",
                city: city,
                state: state,
                type: osm.type,
                latitude: Decimal(osm.latitude),
                longitude: Decimal(osm.longitude),
                sports: osm.sports,
                is_active: true,
                source: "osm",
                osm_id: osm.osmId,
                last_fetched_at: now
            )
        }

        do {
            try await upsertVenues(inserts)
        } catch {
            print("VenueService: Upsert failed, returning cached + in-memory OSM data: \(error)")
            let inMemory = newVenues.map { osm in
                Venue(
                    id: UUID(),
                    name: osm.name,
                    address: "",
                    city: city,
                    state: state,
                    type: mapType(osm.type),
                    latitude: osm.latitude,
                    longitude: osm.longitude,
                    sports: osm.sports,
                    isOpen: true
                )
            }
            return existingVenues + inMemory
        }

        // 6. Reload all venues from Supabase (now includes new OSM data)
        do {
            return try await loadVenues(city: city, state: state)
        } catch {
            return existingVenues
        }
    }

    // MARK: - Load Venues (Supabase Only)

    /// Load active venues from Supabase, optionally filtered by city/state
    func loadVenues(city: String? = nil, state: String? = nil) async throws -> [Venue] {
        let dbVenues = try await loadRawVenues(city: city, state: state)
        return dbVenues.map { toVenue($0) }
    }

    // MARK: - Private Helpers

    /// Load raw DatabaseVenue records from Supabase
    private func loadRawVenues(city: String? = nil, state: String? = nil) async throws -> [DatabaseVenue] {
        var query = supabase.query("venues")
            .select("*")
            .eq("is_active", value: true)

        if let city = city {
            query = query.eq("city", value: city)
        }
        if let state = state {
            query = query.eq("state", value: state)
        }

        return try await query.execute()
    }

    /// Convert a DatabaseVenue to the UI Venue model
    private func toVenue(_ db: DatabaseVenue) -> Venue {
        Venue(
            id: db.id,
            name: db.name,
            address: db.address,
            city: db.city,
            state: db.state,
            type: mapType(db.type),
            latitude: NSDecimalNumber(decimal: db.latitude).doubleValue,
            longitude: NSDecimalNumber(decimal: db.longitude).doubleValue,
            sports: db.sports,
            isOpen: db.is_active
        )
    }

    private func mapType(_ raw: String) -> LocationSuggestion.LocationType {
        switch raw.lowercased() {
        case "park": return .park
        case "court": return .court
        case "field": return .field
        case "gym": return .gym
        default: return .other
        }
    }

    /// Check if any existing venue has OSM data fetched within the cache window.
    private func hasRecentOSMData(in venues: [DatabaseVenue]) -> Bool {
        let formatter = ISO8601DateFormatter()
        let cutoff = Date().addingTimeInterval(-Self.cacheMaxAge)

        return venues.contains { db in
            guard db.source == "osm",
                  let fetchedStr = db.last_fetched_at,
                  let fetchedDate = formatter.date(from: fetchedStr) else {
                return false
            }
            return fetchedDate > cutoff
        }
    }

    /// Upsert venue inserts to Supabase, deduplicating on osm_id.
    private func upsertVenues(_ inserts: [DatabaseVenueInsert]) async throws {
        let client = SupabaseClientManager.shared

        try await client.database
            .from("venues")
            .upsert(inserts, onConflict: "osm_id")
            .execute()
    }

    /// Haversine distance in meters between two coordinates.
    private func haversineDistance(lat1: Double, lon1: Double, lat2: Double, lon2: Double) -> Double {
        let R = 6371000.0 // Earth radius in meters
        let dLat = (lat2 - lat1) * .pi / 180
        let dLon = (lon2 - lon1) * .pi / 180
        let a = sin(dLat / 2) * sin(dLat / 2) +
                cos(lat1 * .pi / 180) * cos(lat2 * .pi / 180) *
                sin(dLon / 2) * sin(dLon / 2)
        let c = 2 * atan2(sqrt(a), sqrt(1 - a))
        return R * c
    }
}
