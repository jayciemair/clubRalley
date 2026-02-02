//
//  DatabaseComment.swift
//  Club Ralley
//
//  Comment-related database models
//

import Foundation

// MARK: - Comment Database Models

/// Database representation of a comment (for INSERT operations)
struct DatabaseComment: Codable {
    let post_id: UUID
    let user_id: UUID
    let content: String
}

/// Database comment with joined user information
struct DatabaseCommentWithUser: Codable {
    let id: UUID
    let post_id: UUID
    let user_id: UUID
    let content: String
    let created_at: Date
    let user: DatabaseUser

    enum CodingKeys: String, CodingKey {
        case id, post_id, user_id, content, created_at
        case user = "club_users"
    }
}
