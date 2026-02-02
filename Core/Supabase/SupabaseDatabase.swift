//
//  SupabaseDatabase.swift
//  Club Ralley
//
//  Database operations for SupabaseManager
//

import Foundation
import Supabase

// MARK: - Database Extension

extension SupabaseManager {

    /// Generic query method for database operations
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

    /// Insert new record into database
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

    /// Update existing record in database
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

    /// Delete record from database
    func delete(from table: String, where condition: String) async throws {
        guard let client = client, !useFallbackMode else {
            print("Mock delete from \(table) (fallback mode)")
            return
        }

        do {
            _ = try await client.client.from(table).delete()
            print("Successfully deleted from \(table)")
        } catch {
            print("Delete failed for \(table): \(error)")
            throw SupabaseError.networkError(error.localizedDescription)
        }
    }

    /// Insert new record and return generated ID
    func insertReturningId<T: Codable>(_ data: T, into table: String) async throws -> UUID {
        guard let client = client, !useFallbackMode else {
            print("Mock insert into \(table) returning ID (fallback mode)")
            return UUID()
        }

        do {
            let response: [DatabaseIdResponse] = try await client.client.from(table)
                .insert(data)
                .select("id")
                .execute()
                .value

            guard let id = response.first?.id else {
                throw SupabaseError.invalidData("No ID returned from insert")
            }
            print("Successfully inserted into \(table) with ID: \(id)")
            return id
        } catch let error as SupabaseError {
            throw error
        } catch {
            print("Insert returning ID failed for \(table): \(error)")
            throw SupabaseError.networkError(error.localizedDescription)
        }
    }

    /// Update record with dictionary values (mock implementation)
    func update(table: String, set: [String: Any], where condition: String) async throws {
        print("Mock update in \(table) (development mode)")
    }

    /// Update record with Encodable type
    func update<T: Encodable>(_ data: T, in table: String, where condition: String) async throws {
        guard let client = client, !useFallbackMode else {
            print("SupabaseManager: Mock update in \(table) (fallback mode)")
            return
        }

        do {
            try await client.client.from(table)
                .update(data)
                .execute()
            print("SupabaseManager: Updated record in \(table)")
        } catch {
            print("SupabaseManager: Failed to update in \(table): \(error)")
            throw error
        }
    }

    /// Create a new Club Ralley user profile in the database
    func createClubUser(
        id: UUID,
        email: String,
        firstName: String,
        lastName: String,
        username: String,
        phoneNumber: String,
        locationCity: String,
        locationState: String,
        profilePhotoURL: String?
    ) async throws {
        let userData = ClubUserInsert(
            id: id,
            email: email,
            first_name: firstName,
            last_name: lastName,
            username: username,
            phone_number: phoneNumber,
            location_city: locationCity,
            location_state: locationState,
            profile_photo_url: profilePhotoURL,
            is_verified_athlete: false,
            friends_count: 0,
            ralleys_count: 0
        )

        try await insert(userData, into: "club_users")
    }
}

// MARK: - Helper Structs

/// Database model for inserting club users
struct ClubUserInsert: Codable {
    let id: UUID
    let email: String
    let first_name: String
    let last_name: String
    let username: String
    let phone_number: String
    let location_city: String
    let location_state: String
    let profile_photo_url: String?
    let is_verified_athlete: Bool
    let friends_count: Int
    let ralleys_count: Int
}

/// Helper struct for returning IDs from inserts
struct DatabaseIdResponse: Codable {
    let id: UUID
}
