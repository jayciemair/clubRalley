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
    /// ID of user who initiated the follow
    let user_id: UUID

    /// ID of user being followed
    let friend_id: UUID

    /// Relationship status (pending, accepted, blocked)
    let status: String
}
