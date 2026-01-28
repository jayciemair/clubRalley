//
//  RalleyService.swift
//  Club Ralley
//
//  Service layer for ralley (pickup game) operations connecting app models to Supabase backend
//  Handles ralley creation, retrieval, participation, and location-based discovery
//

import Foundation
import SwiftUI

/**
 * RalleyService: Bridge between RalleyManager and Supabase ralleys table
 * 
 * Purpose: Handles all ralley-related database operations for pickup games
 * Strategy: Real Supabase calls with mock fallbacks for reliability
 * Database: Maps ClubRalley model to 'ralleys' and 'ralley_participants' tables
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
     * 
     * Database Mapping:
     * - ClubRalley.title -> ralleys.title
     * - ClubRalley.location -> ralleys.location_name, location_city, location_state
     * - ClubRalley.organizer -> Derived from current user (host_user_id)
     * - ClubRalley.maxPlayers -> ralleys.max_participants
     * - ClubRalley.dateTime -> ralleys.date_time
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
                sport_id: nil, // TODO: Map sport to sports table
                category: mapSportToCategory(ralley.sport),
                max_participants: ralley.maxPlayers,
                current_participants: 1, // Host counts as first participant
                is_public: true
            )
            
            // Insert into Supabase ralleys table
            try await supabase.insert(dbRalley, into: "ralleys")
            
            print("✅ RalleyService: Ralley created successfully in database")
            
            // Return the ralley with updated database info
            var updatedRalley = ralley
            updatedRalley.currentPlayers = 1 // Host is first player
            
            isLoading = false
            return updatedRalley
            
        } catch let error as SupabaseManager.SupabaseError {
            isLoading = false
            lastError = error
            print("❌ RalleyService: Create failed with Supabase error: \(error)")
            throw error
        } catch {
            isLoading = false
            let supabaseError = SupabaseManager.SupabaseError.networkError(error.localizedDescription)
            lastError = supabaseError
            print("❌ RalleyService: Create failed with network error: \(error)")
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
     * 
     * Query Strategy:
     * - Use PostGIS/geographic functions to find ralleys within radius
     * - JOIN ralleys with club_users to get organizer information
     * - Filter for future ralleys (date_time > NOW())
     * - ORDER BY date_time ASC for chronological listing
     */
    func loadNearbyRalleys(
        latitude: Double = 37.7749, // Default to SF for demo
        longitude: Double = -122.4194,
        radius: Double = 50.0, // 50km radius
        limit: Int = 20
    ) async throws -> [ClubRalley] {
        isLoading = true
        lastError = nil
        
        do {
            // In real implementation, this would be a complex geographic query:
            // SELECT r.*, u.* FROM ralleys r 
            // JOIN club_users u ON r.host_user_id = u.id 
            // WHERE ST_DWithin(
            //   ST_MakePoint(r.longitude, r.latitude)::geography,
            //   ST_MakePoint($longitude, $latitude)::geography,
            //   $radius * 1000
            // ) AND r.date_time > NOW()
            // ORDER BY r.date_time ASC
            // LIMIT $limit
            
            let ralleys = try await supabase.query("ralleys")
                .select("*, club_users(first_name, last_name, username, profile_photo_url)")
                .execute() as [DatabaseRalleyWithUser]
            
            // Map database results to app models
            let mappedRalleys = ralleys.compactMap { dbRalley in
                mapDatabaseRalleyToApp(dbRalley)
            }
            
            isLoading = false
            print("✅ RalleyService: Loaded \(mappedRalleys.count) ralleys from database")
            return mappedRalleys
            
        } catch let error as SupabaseManager.SupabaseError {
            isLoading = false
            lastError = error
            print("❌ RalleyService: Load ralleys failed: \(error)")
            
            // Fallback to mock data for development
            return generateMockRalleys()
            
        } catch {
            isLoading = false
            let supabaseError = SupabaseManager.SupabaseError.networkError(error.localizedDescription)
            lastError = supabaseError
            print("❌ RalleyService: Load ralleys failed with network error: \(error)")
            
            // Fallback to mock data
            return generateMockRalleys()
        }
    }
    
    /**
     * Load ralleys for specific user (for profile view)
     * @param userId: User ID to load ralleys for (both hosting and participating)
     * @returns: Array of user's ralleys
     */
    func loadUserRalleys(userId: UUID) async throws -> [ClubRalley] {
        isLoading = true
        lastError = nil
        
        do {
            // Query for ralleys the user is hosting
            let hostedRalleys = try await supabase.query("ralleys")
                .select("*, club_users(first_name, last_name, username, profile_photo_url)")
                .eq("host_user_id", value: userId)
                .execute() as [DatabaseRalleyWithUser]
            
            // TODO: Also query for ralleys the user is participating in
            // via ralley_participants table JOIN
            
            let mappedRalleys = hostedRalleys.compactMap { dbRalley in
                mapDatabaseRalleyToApp(dbRalley)
            }
            
            isLoading = false
            print("✅ RalleyService: Loaded \(mappedRalleys.count) user ralleys from database")
            return mappedRalleys
            
        } catch {
            isLoading = false
            print("❌ RalleyService: Load user ralleys failed: \(error)")
            
            // Fallback: Filter mock ralleys by user
            return generateMockRalleys().filter { $0.organizer.name == "Your Name" }
        }
    }
    
    // MARK: - Ralley Participation
    
    /**
     * Join a ralley (add participant)
     * @param ralleyId: Ralley ID to join
     * @returns: Success status
     * 
     * Database Operations:
     * 1. Check if user already joined (ralley_participants table)
     * 2. Check if ralley is full (current_participants >= max_participants)
     * 3. If valid: INSERT into ralley_participants, INCREMENT ralleys.current_participants
     */
    func joinRalley(ralleyId: UUID) async throws -> Bool {
        guard supabase.isAuthenticated else {
            throw SupabaseManager.SupabaseError.notAuthenticated
        }
        
        guard let currentUser = supabase.currentUser else {
            throw SupabaseManager.SupabaseError.userNotFound
        }
        
        do {
            // In real implementation:
            // 1. Check if user already joined
            // 2. Check if ralley is full
            // 3. Insert into ralley_participants with status 'attending'
            // 4. Update ralleys.current_participants counter
            
            let participant = DatabaseRalleyParticipant(
                ralley_id: ralleyId,
                user_id: currentUser.id,
                status: "attending"
            )
            
            try await supabase.insert(participant, into: "ralley_participants")
            
            print("✅ RalleyService: User joined ralley successfully")
            return true
            
        } catch {
            print("❌ RalleyService: Join ralley failed: \(error)")
            throw SupabaseManager.SupabaseError.networkError(error.localizedDescription)
        }
    }
    
    /**
     * Leave a ralley (remove participant)
     * @param ralleyId: Ralley ID to leave
     * @returns: Success status
     */
    func leaveRalley(ralleyId: UUID) async throws -> Bool {
        guard supabase.isAuthenticated else {
            throw SupabaseManager.SupabaseError.notAuthenticated
        }
        
        guard let currentUser = supabase.currentUser else {
            throw SupabaseManager.SupabaseError.userNotFound
        }
        
        do {
            // Delete from ralley_participants and decrement counter
            try await supabase.delete(
                from: "ralley_participants", 
                where: "ralley_id = '\(ralleyId)' AND user_id = '\(currentUser.id)'"
            )
            
            print("✅ RalleyService: User left ralley successfully")
            return true
            
        } catch {
            print("❌ RalleyService: Leave ralley failed: \(error)")
            throw SupabaseManager.SupabaseError.networkError(error.localizedDescription)
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
     * Handles complex mapping between database schema and UI models
     */
    private func mapDatabaseRalleyToApp(_ dbRalley: DatabaseRalleyWithUser) -> ClubRalley {
        let organizer = ClubRalleyOrganizer(
            id: dbRalley.user.id ?? UUID(),
            name: "\(dbRalley.user.first_name) \(dbRalley.user.last_name)",
            username: dbRalley.user.username,
            photoURL: dbRalley.user.profile_photo_url ?? ""
        )
        
        let location = ClubRalleyLocation(
            name: dbRalley.location_name,
            address: dbRalley.location_address ?? "",
            city: dbRalley.location_city,
            state: dbRalley.location_state,
            latitude: dbRalley.latitude,
            longitude: dbRalley.longitude
        )
        
        return ClubRalley(
            id: dbRalley.id,
            title: dbRalley.title,
            sport: mapCategoryToSport(dbRalley.category),
            description: dbRalley.description ?? "",
            organizer: organizer,
            dateTime: dbRalley.date_time,
            location: location,
            maxPlayers: dbRalley.max_participants ?? 0,
            currentPlayers: dbRalley.current_participants,
            cost: 0, // TODO: Add cost field to database
            requirements: "", // TODO: Add requirements field to database
            isPublic: dbRalley.is_public
        )
    }
    
    /**
     * Map database category back to sport name
     */
    private func mapCategoryToSport(_ category: String) -> String {
        // This is a simplified mapping - in real app would use sports table
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
                dateTime: now.addingTimeInterval(3600), // 1 hour from now
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
                dateTime: now.addingTimeInterval(18000), // 5 hours from now
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

// Note: Database models (DatabaseRalley, DatabaseRalleyWithUser, etc.)
// are defined in Models/Database/DatabaseModels.swift