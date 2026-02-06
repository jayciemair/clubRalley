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
        print("🔵 helloWORLD QUERY_START - table: \(table), client: \(client != nil), fallbackMode: \(useFallbackMode)")

        guard let client = client, !useFallbackMode else {
            print("🔴 helloWORLD QUERY - returning fallback QueryBuilder for \(table)")
            return SupabaseQueryBuilder(fallbackMode: true)
        }

        print("🟢 helloWORLD QUERY - returning real QueryBuilder for \(table)")
        return SupabaseQueryBuilder(
            client: client,
            table: table,
            fallbackMode: false
        )
    }

    /// Insert new record into database
    func insert<T: Codable>(_ data: T, into table: String) async throws {
        print("🔵 helloWORLD INSERT START - table: \(table)")
        print("🔵 helloWORLD INSERT DATA: \(data)")

        guard let client = client, !useFallbackMode else {
            print("🔴 helloWORLD INSERT SKIPPED - fallback mode for table: \(table)")
            return
        }

        do {
            // Explicitly call .execute() to ensure the query runs
            let response = try await client.client.from(table).insert(data).execute()
            print("🟢 helloWORLD INSERT SUCCESS - table: \(table), status: \(response.status)")
        } catch {
            print("🔴 helloWORLD INSERT FAILED - table: \(table), error: \(error)")
            print("🔴 helloWORLD INSERT ERROR DETAILS: \(String(describing: error))")
            throw SupabaseError.networkError(error.localizedDescription)
        }
    }

    /// Update existing record in database
    func update<T: Codable>(_ data: T, in table: String, where condition: String) async throws {
        print("🔵 helloWORLD UPDATE START - table: \(table), condition: \(condition)")
        print("🔵 helloWORLD UPDATE DATA: \(data)")

        guard let client = client, !useFallbackMode else {
            print("🔴 helloWORLD UPDATE SKIPPED - fallback mode for table: \(table)")
            return
        }

        // Parse the condition to extract column, operator, and value
        let parts = condition.components(separatedBy: " = ")
        guard parts.count == 2 else {
            print("🔴 helloWORLD UPDATE - Invalid condition format: \(condition)")
            throw SupabaseError.invalidData("Invalid condition format")
        }

        let column = parts[0].trimmingCharacters(in: .whitespaces)
        var value = parts[1].trimmingCharacters(in: .whitespaces)

        // Remove quotes if present
        if value.hasPrefix("'") && value.hasSuffix("'") {
            value = String(value.dropFirst().dropLast())
        }

        print("🔵 helloWORLD UPDATE - Parsed: column=\(column), value=\(value)")

        do {
            _ = try await client.client.from(table)
                .update(data)
                .eq(column, value: value)
                .execute()
            print("🟢 helloWORLD UPDATE SUCCESS - table: \(table)")
        } catch {
            print("🔴 helloWORLD UPDATE FAILED - table: \(table), error: \(error)")
            throw SupabaseError.networkError(error.localizedDescription)
        }
    }

    /// Delete record from database
    func delete(from table: String, where condition: String) async throws {
        print("🔵 helloWORLD DELETE START - table: \(table), condition: \(condition)")

        guard let client = client, !useFallbackMode else {
            print("🔴 helloWORLD DELETE SKIPPED - fallback mode for table: \(table)")
            return
        }

        do {
            _ = try await client.client.from(table).delete()
            print("🟢 helloWORLD DELETE SUCCESS - table: \(table)")
        } catch {
            print("🔴 helloWORLD DELETE FAILED - table: \(table), error: \(error)")
            throw SupabaseError.networkError(error.localizedDescription)
        }
    }

    /// Insert new record and return generated ID
    func insertReturningId<T: Codable>(_ data: T, into table: String) async throws -> UUID {
        print("🔵 helloWORLD INSERT_RETURNING_ID START - table: \(table)")
        print("🔵 helloWORLD INSERT_RETURNING_ID DATA: \(data)")

        guard let client = client, !useFallbackMode else {
            print("🔴 helloWORLD INSERT_RETURNING_ID SKIPPED - fallback mode for table: \(table)")
            return UUID()
        }

        do {
            let response: [DatabaseIdResponse] = try await client.client.from(table)
                .insert(data)
                .select("id")
                .execute()
                .value

            guard let id = response.first?.id else {
                print("🔴 helloWORLD INSERT_RETURNING_ID FAILED - no ID returned for table: \(table)")
                throw SupabaseError.invalidData("No ID returned from insert")
            }
            print("🟢 helloWORLD INSERT_RETURNING_ID SUCCESS - table: \(table), id: \(id)")
            return id
        } catch let error as SupabaseError {
            throw error
        } catch {
            print("🔴 helloWORLD INSERT_RETURNING_ID FAILED - table: \(table), error: \(error)")
            throw SupabaseError.networkError(error.localizedDescription)
        }
    }

    /// Update record with dictionary values (mock implementation)
    func update(table: String, set: [String: Any], where condition: String) async throws {
        print("🔵 helloWORLD UPDATE_DICT START - table: \(table), condition: \(condition)")
        print("🔵 helloWORLD UPDATE_DICT DATA: \(set)")
        print("🔴 helloWORLD UPDATE_DICT SKIPPED - mock implementation")
    }

    /// Update record with Encodable type
    func update<T: Encodable>(_ data: T, in table: String, where condition: String) async throws {
        print("🔵 helloWORLD UPDATE_ENCODABLE START - table: \(table), condition: \(condition)")
        print("🔵 helloWORLD UPDATE_ENCODABLE DATA: \(data)")

        guard let client = client, !useFallbackMode else {
            print("🔴 helloWORLD UPDATE_ENCODABLE SKIPPED - fallback mode for table: \(table)")
            return
        }

        // Parse the condition to extract column, operator, and value
        // Format expected: "column = 'value'" or "column = value"
        let parts = condition.components(separatedBy: " = ")
        guard parts.count == 2 else {
            print("🔴 helloWORLD UPDATE_ENCODABLE - Invalid condition format: \(condition)")
            throw SupabaseError.invalidData("Invalid condition format")
        }

        let column = parts[0].trimmingCharacters(in: .whitespaces)
        var value = parts[1].trimmingCharacters(in: .whitespaces)

        // Remove quotes if present
        if value.hasPrefix("'") && value.hasSuffix("'") {
            value = String(value.dropFirst().dropLast())
        }

        print("🔵 helloWORLD UPDATE_ENCODABLE - Parsed: column=\(column), value=\(value)")

        do {
            try await client.client.from(table)
                .update(data)
                .eq(column, value: value)
                .execute()
            print("🟢 helloWORLD UPDATE_ENCODABLE SUCCESS - table: \(table)")
        } catch {
            print("🔴 helloWORLD UPDATE_ENCODABLE FAILED - table: \(table), error: \(error)")
            throw error
        }
    }

    /// Create a new Club Ralley user profile in the database (lean 6-table schema)
    func createClubUser(
        id: UUID,
        email: String,
        firstName: String,
        lastName: String,
        username: String,
        city: String,
        state: String,
        profilePhotoURL: String?
    ) async throws {
        print("🔵 helloWORLD CREATE_CLUB_USER START")
        print("🔵 helloWORLD CREATE_CLUB_USER - id: \(id), email: \(email), username: \(username)")
        print("🔵 helloWORLD CREATE_CLUB_USER - name: \(firstName) \(lastName)")
        print("🔵 helloWORLD CREATE_CLUB_USER - location: \(city), \(state)")

        let userData = ClubUserInsert(
            id: id,
            email: email,
            first_name: firstName,
            last_name: lastName,
            username: username,
            city: city,
            state: state,
            profile_photo_url: profilePhotoURL,
            friends_count: 0,
            ralleys_count: 0
        )

        print("🔵 helloWORLD CREATE_CLUB_USER - Inserting into 'users' table...")
        try await insert(userData, into: "club_users")
        print("🟢 helloWORLD CREATE_CLUB_USER COMPLETE")
    }
}

// MARK: - Helper Structs

/// Database model for inserting users (matches users table schema)
struct ClubUserInsert: Codable {
    let id: UUID
    let email: String
    let first_name: String
    let last_name: String
    let username: String
    let city: String
    let state: String
    let profile_photo_url: String?
    let friends_count: Int
    let ralleys_count: Int
}

/// Helper struct for returning IDs from inserts
struct DatabaseIdResponse: Codable {
    let id: UUID
}
