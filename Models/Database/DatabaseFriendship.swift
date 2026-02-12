//
//  DatabaseFriendship.swift
//  Club Ralley
//
//  Friendship/follow relationship database models
//

import Foundation

// MARK: - Friendship Database Models

/// Database representation of friendship/following relationship
/// Maps to Supabase friendships table with requester_id/addressee_id columns
struct DatabaseFriendship: Codable {
    /// Database ID (optional for inserts)
    var id: UUID?

    /// ID of user who initiated the follow (maps to requester_id in database)
    let requester_id: UUID

    /// ID of user being followed (maps to addressee_id in database)
    let addressee_id: UUID

    /// Relationship status (pending, accepted, blocked)
    let status: String

    /// When the relationship was created (optional for inserts)
    var created_at: Date?

    /// When the relationship was accepted (optional)
    var accepted_at: Date?

    // MARK: - Computed Properties for Backwards Compatibility

    /// Alias for requester_id (backwards compatibility)
    var user_id: UUID { requester_id }

    /// Alias for addressee_id (backwards compatibility)
    var friend_id: UUID { addressee_id }

    /// Convenience init for creating new friendships
    init(user_id: UUID, friend_id: UUID, status: String = "accepted") {
        self.id = nil
        self.requester_id = user_id
        self.addressee_id = friend_id
        self.status = status
        self.created_at = nil
        self.accepted_at = nil
    }

    enum CodingKeys: String, CodingKey {
        case id
        case requester_id
        case addressee_id
        case status
        case created_at
        case accepted_at
    }
}
