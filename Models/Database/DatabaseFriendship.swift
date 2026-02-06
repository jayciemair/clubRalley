//
//  DatabaseFriendship.swift
//  Club Ralley
//
//  Friendship/follow relationship database models
//

import Foundation

// MARK: - Friendship Database Models

/// Database representation of friendship/following relationship
struct DatabaseFriendship: Codable {
    /// Database ID (optional for inserts)
    var id: UUID?

    /// ID of user who initiated the follow
    let user_id: UUID

    /// ID of user being followed
    let friend_id: UUID

    /// Relationship status (pending, accepted, blocked)
    let status: String

    /// When the relationship was created (optional for inserts)
    var created_at: Date?

    /// Convenience init for creating new friendships
    init(user_id: UUID, friend_id: UUID, status: String = "accepted") {
        self.id = nil
        self.user_id = user_id
        self.friend_id = friend_id
        self.status = status
        self.created_at = nil
    }
}
