//
//  DatabaseNotification.swift
//  Club Ralley
//
//  Notification-related database models
//

import Foundation

// MARK: - Notification Database Models

/// Database representation of a notification
struct DatabaseNotification: Codable {
    let id: UUID
    let user_id: UUID
    let type: String
    let actor_id: UUID?
    let post_id: UUID?
    let ralley_id: UUID?
    let message: String
    let is_read: Bool
    let created_at: Date

    enum CodingKeys: String, CodingKey {
        case id, user_id, type, actor_id, post_id
        case ralley_id, message, is_read, created_at
    }
}

/// Database notification with actor user information
struct DatabaseNotificationWithUser: Codable {
    let id: UUID
    let user_id: UUID
    let type: String
    let actor_id: UUID?
    let post_id: UUID?
    let ralley_id: UUID?
    let message: String
    let is_read: Bool
    let created_at: Date
    let actor: DatabaseUser?

    enum CodingKeys: String, CodingKey {
        case id, user_id, type, actor_id, post_id
        case ralley_id, message, is_read, created_at
        case actor = "club_users"
    }
}
