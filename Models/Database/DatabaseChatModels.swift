//
//  DatabaseChatModels.swift
//  Club Ralley
//
//  Database models for chat-related operations.
//  Note: Most chat models are now defined in their respective service files
//  to match the lean 8-table schema.
//

import Foundation

// MARK: - Pending Request Database Models

/**
 * Database ralley participant with user info for pending requests
 * Uses ralley_participants table (exists in lean schema)
 */
struct DatabasePendingRequestWithUser: Codable {
    let id: UUID
    let ralley_id: UUID
    let user_id: UUID
    let status: String
    let joined_at: Date
    let user: DatabaseUser

    // Backwards compatibility
    var created_at: Date { joined_at }

    enum CodingKeys: String, CodingKey {
        case id
        case ralley_id
        case user_id
        case status
        case joined_at
        case user = "club_users"
    }
}

// NOTE: Other chat/messaging database models are defined in:
// - Services/ChatService.swift (group chat messages)
// - Services/MessagingService.swift (direct messages)
// This avoids duplication and keeps models close to their usage.
