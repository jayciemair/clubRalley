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
        print("[supaTennis] 💾 insert() called — table: \(table), dataType: \(type(of: data))")
        print("[supaTennis] 💾 client nil? \(client == nil), fallback? \(useFallbackMode)")
        guard let client = client, !useFallbackMode else {
            print("[supaTennis] ❌ insert BLOCKED — offline/fallback mode, table: \(table)")
            throw SupabaseError.networkError("Not connected to database. Please check your connection and try again.")
        }

        do {
            let encoder = JSONEncoder()
            if let jsonData = try? encoder.encode(data),
               let jsonString = String(data: jsonData, encoding: .utf8) {
                print("[supaTennis] 💾 insert payload for \(table): \(jsonString)")
            }
            let _ = try await client.client.from(table).insert(data).execute()
            print("[supaTennis] ✅ insert SUCCESS into \(table)")
        } catch {
            print("[supaTennis] ❌ insert FAILED into \(table): \(error)")
            print("[supaTennis] ❌ insert error type: \(type(of: error))")
            print("[supaTennis] ❌ insert localizedDescription: \(error.localizedDescription)")
            throw SupabaseError.networkError(error.localizedDescription)
        }
    }

    /// Update existing record in database
    func update<T: Codable>(_ data: T, in table: String, where condition: String) async throws {
        guard let client = client, !useFallbackMode else {
            print("📱 SupabaseDatabase.update: Offline mode - cannot update \(table)")
            throw SupabaseError.networkError("Not connected to database. Please check your connection and try again.")
        }

        let filters = parseWhereCondition(condition)
        guard !filters.isEmpty else {
            throw SupabaseError.invalidData("Invalid condition format")
        }

        do {
            var query = try client.client.from(table).update(data)
            for (column, value) in filters {
                query = query.eq(column, value: value)
            }
            _ = try await query.execute()
        } catch {
            throw SupabaseError.networkError(error.localizedDescription)
        }
    }

    /// Delete record from database
    func delete(from table: String, where condition: String) async throws {
        guard let client = client, !useFallbackMode else {
            print("📱 SupabaseDatabase.delete: Offline mode - cannot delete from \(table)")
            throw SupabaseError.networkError("Not connected to database. Please check your connection and try again.")
        }

        let filters = parseWhereCondition(condition)
        guard !filters.isEmpty else {
            throw SupabaseError.invalidData("Invalid condition format")
        }

        do {
            var query = client.client.from(table).delete()
            for (column, value) in filters {
                query = query.eq(column, value: value)
            }
            _ = try await query.execute()
        } catch {
            throw SupabaseError.networkError(error.localizedDescription)
        }
    }

    /// Insert new record and return generated ID
    func insertReturningId<T: Codable>(_ data: T, into table: String) async throws -> UUID {
        print("[supaTennis] 💾 insertReturningId() called — table: \(table), dataType: \(type(of: data))")
        print("[supaTennis] 💾 client nil? \(client == nil), fallback? \(useFallbackMode)")
        guard let client = client, !useFallbackMode else {
            print("[supaTennis] ❌ insertReturningId BLOCKED — offline/fallback mode, table: \(table)")
            throw SupabaseError.networkError("Not connected to database. Please check your connection and try again.")
        }

        do {
            let encoder = JSONEncoder()
            if let jsonData = try? encoder.encode(data),
               let jsonString = String(data: jsonData, encoding: .utf8) {
                print("[supaTennis] 💾 insertReturningId payload for \(table): \(jsonString)")
            }
            let response: [DatabaseIdResponse] = try await client.client.from(table)
                .insert(data)
                .select("id")
                .execute()
                .value

            guard let id = response.first?.id else {
                throw SupabaseError.invalidData("No ID returned from insert")
            }
            print("[supaTennis] ✅ insertReturningId SUCCESS for \(table), id: \(id)")
            return id
        } catch let error as SupabaseError {
            print("[supaTennis] ❌ insertReturningId FAILED for \(table): \(error)")
            throw error
        } catch {
            print("[supaTennis] ❌ insertReturningId FAILED for \(table): \(error)")
            print("[supaTennis] ❌ error type: \(type(of: error))")
            print("[supaTennis] ❌ error detail: \(error.localizedDescription)")
            throw SupabaseError.networkError(error.localizedDescription)
        }
    }

    /// Update record with dictionary values
    /// Note: Prefer the typed update<T: Encodable>() overload for compile-time safety.
    func update(table: String, set: [String: Any], where condition: String) async throws {
        // Convert dictionary to JSON data, then use raw update
        guard let client = client, !useFallbackMode else {
            print("📱 SupabaseDatabase.update(dict): Offline mode - cannot update \(table)")
            throw SupabaseError.networkError("Not connected to database. Please check your connection and try again.")
        }

        let filters = parseWhereCondition(condition)
        guard !filters.isEmpty else {
            throw SupabaseError.invalidData("Invalid condition format")
        }

        // Convert to Codable wrapper
        let wrapper = DictionaryWrapper(set)

        do {
            var query = try client.client.from(table).update(wrapper)
            for (column, value) in filters {
                query = query.eq(column, value: value)
            }
            try await query.execute()
        } catch {
            throw SupabaseError.networkError(error.localizedDescription)
        }
    }

    /// Parse a SQL-style WHERE condition into (column, value) pairs.
    /// Supports compound conditions joined by AND, e.g.:
    ///   "ralley_id = 'abc' AND user_id = 'xyz'" → [("ralley_id", "abc"), ("user_id", "xyz")]
    ///   "user_id = 'abc' AND is_read = 'false'" → [("user_id", "abc"), ("is_read", "false")]
    private func parseWhereCondition(_ condition: String) -> [(column: String, value: String)] {
        let clauses = condition.components(separatedBy: " AND ")
        var filters: [(String, String)] = []

        for clause in clauses {
            let parts = clause.trimmingCharacters(in: .whitespaces).components(separatedBy: " = ")
            guard parts.count == 2 else { continue }

            let column = parts[0].trimmingCharacters(in: .whitespaces)
            var value = parts[1].trimmingCharacters(in: .whitespaces)

            // Remove quotes if present
            if value.hasPrefix("'") && value.hasSuffix("'") {
                value = String(value.dropFirst().dropLast())
            }

            filters.append((column, value))
        }

        return filters
    }

    /// Update record with Encodable type
    func update<T: Encodable>(_ data: T, in table: String, where condition: String) async throws {
        guard let client = client, !useFallbackMode else {
            print("📱 SupabaseDatabase.update: Offline mode - cannot update \(table)")
            throw SupabaseError.networkError("Not connected to database. Please check your connection and try again.")
        }

        let filters = parseWhereCondition(condition)
        guard !filters.isEmpty else {
            throw SupabaseError.invalidData("Invalid condition format")
        }

        do {
            var query = try client.client.from(table).update(data)
            for (column, value) in filters {
                query = query.eq(column, value: value)
            }
            try await query.execute()
        } catch {
            throw error
        }
    }

    /// Create a new Club Ralley user profile in the database
    /// Note: id and authId are typically the same (the Supabase auth user ID)
    func createClubUser(
        id: UUID,
        authId: UUID? = nil,
        email: String,
        firstName: String,
        lastName: String,
        username: String,
        city: String,
        state: String,
        profilePhotoURL: String?,
        isVerifiedAthlete: Bool? = nil,
        athleteInfo: ClubUserAthleteInfoJSON? = nil,
        sports: [String]? = nil
    ) async throws {
        print("[supaTennis] 👤 createClubUser() called")
        print("[supaTennis] 👤   id: \(id)")
        print("[supaTennis] 👤   authId: \(authId?.uuidString ?? "nil (will use id)")")
        print("[supaTennis] 👤   email: '\(email)'")
        print("[supaTennis] 👤   name: '\(firstName) \(lastName)'")
        print("[supaTennis] 👤   username: '\(username)'")
        print("[supaTennis] 👤   location: '\(city), \(state)'")
        print("[supaTennis] 👤   profilePhotoURL: \(profilePhotoURL ?? "nil")")
        print("[supaTennis] 👤   isVerifiedAthlete: \(isVerifiedAthlete?.description ?? "nil")")
        print("[supaTennis] 👤   athleteInfo: \(athleteInfo != nil ? "present" : "nil")")
        print("[supaTennis] 👤   sports: \(sports ?? [])")

        let userData = ClubUserInsert(
            id: id,
            auth_id: authId ?? id,
            email: email,
            first_name: firstName,
            last_name: lastName,
            username: username,
            city: city,
            state: state,
            profile_photo_url: profilePhotoURL,
            is_verified_athlete: isVerifiedAthlete,
            athlete_info: athleteInfo,
            sports: sports
        )

        print("[supaTennis] 👤 About to insert into club_users...")
        try await insert(userData, into: "club_users")
        print("[supaTennis] ✅ createClubUser() completed successfully")
    }
}

// MARK: - Helper Structs

/// Wrapper to make [String: Any] Encodable for Supabase updates
struct DictionaryWrapper: Encodable {
    private let values: [String: Any]

    init(_ values: [String: Any]) {
        self.values = values
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: DynamicCodingKey.self)
        for (key, value) in values {
            let codingKey = DynamicCodingKey(stringValue: key)
            if let boolVal = value as? Bool {
                try container.encode(boolVal, forKey: codingKey)
            } else if let intVal = value as? Int {
                try container.encode(intVal, forKey: codingKey)
            } else if let doubleVal = value as? Double {
                try container.encode(doubleVal, forKey: codingKey)
            } else if let strVal = value as? String {
                try container.encode(strVal, forKey: codingKey)
            }
        }
    }

    private struct DynamicCodingKey: CodingKey {
        var stringValue: String
        var intValue: Int? { nil }
        init(stringValue: String) { self.stringValue = stringValue }
        init?(intValue: Int) { nil }
    }
}

/// Codable struct that maps to the `athlete_info` JSONB column in club_users
struct ClubUserAthleteInfoJSON: Codable {
    let school: String?
    let sport: String?
    let division: String?
    let years_played: String?
    let position: String?
    let played_college: Bool?
    let verified: Bool?
    let verification_image_url: String?
    let verification_notes: String?
}

/// Database model for inserting users (matches users table schema)
struct ClubUserInsert: Codable {
    let id: UUID
    let auth_id: UUID  // Links to Supabase auth.users.id for RLS
    let email: String
    let first_name: String
    let last_name: String
    let username: String
    let city: String
    let state: String
    let profile_photo_url: String?
    let is_verified_athlete: Bool?
    let athlete_info: ClubUserAthleteInfoJSON?
    let sports: [String]?
}

/// Helper struct for returning IDs from inserts
struct DatabaseIdResponse: Codable {
    let id: UUID
}

// MARK: - RPC Extension

extension SupabaseManager {

    /// Call an RPC function with parameters
    func rpc<T: Decodable, P: Encodable>(_ functionName: String, params: P) async throws -> T {
        guard let client = client, !useFallbackMode else {
            throw SupabaseError.networkError("RPC not available in fallback mode")
        }

        do {
            let response: T = try await client.client.rpc(functionName, params: params).execute().value
            return response
        } catch {
            throw SupabaseError.networkError(error.localizedDescription)
        }
    }

    /// Call an RPC function without parameters
    func rpc<T: Decodable>(_ functionName: String) async throws -> T {
        guard let client = client, !useFallbackMode else {
            throw SupabaseError.networkError("RPC not available in fallback mode")
        }

        do {
            let response: T = try await client.client.rpc(functionName).execute().value
            return response
        } catch {
            throw SupabaseError.networkError(error.localizedDescription)
        }
    }
}
