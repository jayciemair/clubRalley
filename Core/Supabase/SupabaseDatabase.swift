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

        // Parse the condition to extract column, operator, and value
        let parts = condition.components(separatedBy: " = ")
        guard parts.count == 2 else {
            throw SupabaseError.invalidData("Invalid condition format")
        }

        let column = parts[0].trimmingCharacters(in: .whitespaces)
        var value = parts[1].trimmingCharacters(in: .whitespaces)

        // Remove quotes if present
        if value.hasPrefix("'") && value.hasSuffix("'") {
            value = String(value.dropFirst().dropLast())
        }

        do {
            _ = try await client.client.from(table)
                .update(data)
                .eq(column, value: value)
                .execute()
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

        // Parse the condition to extract column and value
        let parts = condition.components(separatedBy: " = ")
        guard parts.count >= 2 else {
            throw SupabaseError.invalidData("Invalid condition format")
        }

        let column = parts[0].trimmingCharacters(in: .whitespaces)
        var value = parts[1].trimmingCharacters(in: .whitespaces)

        // Remove quotes if present
        if value.hasPrefix("'") && value.hasSuffix("'") {
            value = String(value.dropFirst().dropLast())
        }

        do {
            _ = try await client.client.from(table)
                .delete()
                .eq(column, value: value)
                .execute()
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

    /// Update record with dictionary values (mock implementation)
    func update(table: String, set: [String: Any], where condition: String) async throws {
        // Not implemented - use typed update instead
    }

    /// Update record with Encodable type
    func update<T: Encodable>(_ data: T, in table: String, where condition: String) async throws {
        guard let client = client, !useFallbackMode else {
            print("📱 SupabaseDatabase.update: Offline mode - cannot update \(table)")
            throw SupabaseError.networkError("Not connected to database. Please check your connection and try again.")
        }

        // Parse the condition to extract column, operator, and value
        let parts = condition.components(separatedBy: " = ")
        guard parts.count == 2 else {
            throw SupabaseError.invalidData("Invalid condition format")
        }

        let column = parts[0].trimmingCharacters(in: .whitespaces)
        var value = parts[1].trimmingCharacters(in: .whitespaces)

        // Remove quotes if present
        if value.hasPrefix("'") && value.hasSuffix("'") {
            value = String(value.dropFirst().dropLast())
        }

        do {
            try await client.client.from(table)
                .update(data)
                .eq(column, value: value)
                .execute()
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
        profilePhotoURL: String?
    ) async throws {
        print("[supaTennis] 👤 createClubUser() called")
        print("[supaTennis] 👤   id: \(id)")
        print("[supaTennis] 👤   authId: \(authId?.uuidString ?? "nil (will use id)")")
        print("[supaTennis] 👤   email: '\(email)'")
        print("[supaTennis] 👤   name: '\(firstName) \(lastName)'")
        print("[supaTennis] 👤   username: '\(username)'")
        print("[supaTennis] 👤   location: '\(city), \(state)'")
        print("[supaTennis] 👤   profilePhotoURL: \(profilePhotoURL ?? "nil")")

        let userData = ClubUserInsert(
            id: id,
            auth_id: authId ?? id,
            email: email,
            first_name: firstName,
            last_name: lastName,
            username: username,
            city: city,
            state: state,
            profile_photo_url: profilePhotoURL
        )

        print("[supaTennis] 👤 About to insert into club_users...")
        try await insert(userData, into: "club_users")
        print("[supaTennis] ✅ createClubUser() completed successfully")
    }
}

// MARK: - Helper Structs

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
