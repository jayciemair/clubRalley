//
//  RalleyParticipationService.swift
//  Club Ralley
//
//  Service for ralley participation operations: joining, leaving, and request management.
//

import Foundation
import SwiftUI

/**
 * RalleyParticipationService: Handles ralley participation operations
 *
 * Purpose: Manages join/leave operations and join request management
 * Database: Uses ralley_participants table
 */
@MainActor
class RalleyParticipationService: ObservableObject {

    // MARK: - Dependencies

    /// Supabase client for database operations
    private let supabase = SupabaseManager.shared

    // MARK: - Published Properties

    /// Loading state for UI spinners
    @Published var isLoading = false

    /// Last operation error for user feedback
    @Published var lastError: SupabaseManager.SupabaseError?

    // MARK: - Join/Leave Operations

    /**
     * Join a ralley (add participant)
     * @param ralleyId: Ralley ID to join
     * @returns: Success status
     */
    func joinRalley(ralleyId: UUID) async throws -> Bool {
        guard supabase.isAuthenticated else {
            throw SupabaseManager.SupabaseError.notAuthenticated
        }

        guard let currentUser = supabase.currentUser else {
            throw SupabaseManager.SupabaseError.userNotFound
        }

        do {
            let participant = DatabaseRalleyParticipant(
                ralley_id: ralleyId,
                user_id: currentUser.id,
                status: "attending"
            )

            try await supabase.insert(participant, into: "ralley_participants")

            print("RalleyParticipationService: User joined ralley successfully")
            return true

        } catch {
            print("RalleyParticipationService: Join ralley failed: \(error)")
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
            try await supabase.delete(
                from: "ralley_participants",
                where: "ralley_id = '\(ralleyId)' AND user_id = '\(currentUser.id)'"
            )

            print("RalleyParticipationService: User left ralley successfully")
            return true

        } catch {
            print("RalleyParticipationService: Leave ralley failed: \(error)")
            throw SupabaseManager.SupabaseError.networkError(error.localizedDescription)
        }
    }

    // MARK: - Join Request Operations

    /**
     * Request to join a private ralley (requires captain approval)
     * @param ralleyId: Ralley ID to request to join
     * @returns: Success status
     */
    func requestToJoin(ralleyId: UUID) async throws -> Bool {
        guard supabase.isAuthenticated else {
            throw SupabaseManager.SupabaseError.notAuthenticated
        }

        guard let currentUser = supabase.currentUser else {
            throw SupabaseManager.SupabaseError.userNotFound
        }

        do {
            let participant = DatabaseRalleyParticipant(
                ralley_id: ralleyId,
                user_id: currentUser.id,
                status: "requested"
            )

            try await supabase.insert(participant, into: "ralley_participants")

            print("RalleyParticipationService: Join request submitted for ralley \(ralleyId)")
            return true

        } catch {
            print("RalleyParticipationService: Request to join failed: \(error)")
            throw SupabaseManager.SupabaseError.networkError(error.localizedDescription)
        }
    }

    /**
     * Approve a join request (captain only)
     * @param ralleyId: Ralley ID
     * @param userId: User ID to approve
     * @returns: Success status
     */
    func approveJoinRequest(ralleyId: UUID, userId: UUID) async throws -> Bool {
        guard supabase.isAuthenticated else {
            throw SupabaseManager.SupabaseError.notAuthenticated
        }

        do {
            try await supabase.update(
                table: "ralley_participants",
                set: ["status": "attending"],
                where: "ralley_id = '\(ralleyId)' AND user_id = '\(userId)'"
            )

            print("RalleyParticipationService: Approved join request for user \(userId)")
            return true

        } catch {
            print("RalleyParticipationService: Approve join request failed: \(error)")
            throw SupabaseManager.SupabaseError.networkError(error.localizedDescription)
        }
    }

    /**
     * Reject a join request (captain only)
     * @param ralleyId: Ralley ID
     * @param userId: User ID to reject
     * @returns: Success status
     */
    func rejectJoinRequest(ralleyId: UUID, userId: UUID) async throws -> Bool {
        guard supabase.isAuthenticated else {
            throw SupabaseManager.SupabaseError.notAuthenticated
        }

        do {
            try await supabase.delete(
                from: "ralley_participants",
                where: "ralley_id = '\(ralleyId)' AND user_id = '\(userId)' AND status = 'requested'"
            )

            print("RalleyParticipationService: Rejected join request for user \(userId)")
            return true

        } catch {
            print("RalleyParticipationService: Reject join request failed: \(error)")
            throw SupabaseManager.SupabaseError.networkError(error.localizedDescription)
        }
    }

    /**
     * Load pending join requests for a ralley (captain only)
     * @param ralleyId: Ralley ID
     * @returns: Array of pending requests with user info
     */
    func loadPendingRequests(ralleyId: UUID) async throws -> [PendingJoinRequest] {
        guard supabase.isAuthenticated else {
            throw SupabaseManager.SupabaseError.notAuthenticated
        }

        do {
            let requests: [DatabaseRalleyPendingRequest] = try await supabase.query("ralley_participants")
                .select("*, club_users(first_name, last_name, username, profile_photo_url)")
                .eq("ralley_id", value: ralleyId)
                .eq("status", value: "requested")
                .execute()

            return requests.map { req in
                PendingJoinRequest(
                    id: req.id,
                    ralleyId: req.ralley_id,
                    userId: req.user_id,
                    userName: "\(req.user.first_name) \(req.user.last_name)",
                    userUsername: req.user.username,
                    userPhotoURL: req.user.profile_photo_url,
                    mutualCount: 0,
                    requestedAt: req.created_at
                )
            }

        } catch {
            print("RalleyParticipationService: Load pending requests failed: \(error)")
            return []
        }
    }

    /**
     * Get count of pending requests for a ralley
     * @param ralleyId: Ralley ID
     * @returns: Number of pending requests
     */
    func getPendingRequestsCount(ralleyId: UUID) async throws -> Int {
        do {
            let requests: [DatabaseRalleyParticipant] = try await supabase.query("ralley_participants")
                .select("*")
                .eq("ralley_id", value: ralleyId)
                .eq("status", value: "requested")
                .execute()

            return requests.count
        } catch {
            return 0
        }
    }

    /**
     * Check if current user has a pending request for a ralley
     * @param ralleyId: Ralley ID
     * @returns: True if user has pending request
     */
    func hasPendingRequest(ralleyId: UUID) async throws -> Bool {
        guard let currentUser = supabase.currentUser else { return false }

        do {
            let requests: [DatabaseRalleyParticipant] = try await supabase.query("ralley_participants")
                .select("*")
                .eq("ralley_id", value: ralleyId)
                .eq("user_id", value: currentUser.id)
                .eq("status", value: "requested")
                .execute()

            return !requests.isEmpty
        } catch {
            return false
        }
    }

    /**
     * Get all attendees for a ralley
     * @param ralleyId: Ralley ID
     * @returns: Array of attendees with user info
     */
    func getAttendees(ralleyId: UUID) async throws -> [RalleyAttendee] {
        do {
            let participants: [DatabaseParticipantWithUser] = try await supabase.query("ralley_participants")
                .select("*, club_users(id, first_name, last_name, username, profile_photo_url)")
                .eq("ralley_id", value: ralleyId)
                .eq("status", value: "attending")
                .execute()

            return participants.map { p in
                RalleyAttendee(
                    id: p.user_id,
                    name: "\(p.user.first_name) \(p.user.last_name)",
                    username: p.user.username,
                    photoURL: p.user.profile_photo_url,
                    joinedAt: p.created_at
                )
            }
        } catch {
            print("RalleyParticipationService: Get attendees failed: \(error)")
            return []
        }
    }
}

// MARK: - Supporting Models

/**
 * Represents an attendee of a ralley
 */
struct RalleyAttendee: Identifiable, Codable {
    let id: UUID
    let name: String
    let username: String
    let photoURL: String?
    let joinedAt: Date
}

/**
 * Database model for participant with user info
 */
struct DatabaseParticipantWithUser: Codable {
    let id: UUID
    let ralley_id: UUID
    let user_id: UUID
    let status: String
    let created_at: Date
    let user: DatabaseRalleyUser

    enum CodingKeys: String, CodingKey {
        case id
        case ralley_id
        case user_id
        case status
        case created_at
        case user = "club_users"
    }
}

/**
 * Database model for ralley pending request with user info
 */
struct DatabaseRalleyPendingRequest: Codable {
    let id: UUID
    let ralley_id: UUID
    let user_id: UUID
    let status: String
    let created_at: Date
    let user: DatabaseRalleyUser

    enum CodingKeys: String, CodingKey {
        case id
        case ralley_id
        case user_id
        case status
        case created_at
        case user = "club_users"
    }
}
