//
//  PostEngagementModels.swift
//  Club Ralley
//
//  Helper structs for PostEngagementService JSONB operations.
//  Actual posts table columns: id, user_id, content, image_url, ralley_id, likes_count, liked_by (jsonb), created_at
//

import Foundation

// MARK: - Helper Structs for JSONB Operations

/// Post with liked_by JSONB array (matches actual posts table schema)
struct PostWithLikes: Codable {
    let id: UUID
    var liked_by: [String]?
    var likes_count: Int

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        likes_count = try container.decodeIfPresent(Int.self, forKey: .likes_count) ?? 0

        // Handle liked_by as either array of strings or nil
        if let likesArray = try? container.decodeIfPresent([String].self, forKey: .liked_by) {
            liked_by = likesArray
        } else {
            liked_by = []
        }
    }
}

/// Update struct for post likes (matches actual posts columns: liked_by, likes_count)
struct PostLikesUpdate: Codable {
    let liked_by: [String]
    let likes_count: Int
}

/// Struct for getting post owner ID
struct DatabasePostOwner: Codable {
    let user_id: UUID
}

/// Struct for getting post with owner
struct DatabasePostWithOwner: Codable {
    let id: UUID
    let user_id: UUID
}

/// User who liked a post (fetched from club_users table)
struct PostLiker: Codable, Identifiable {
    let id: UUID
    let first_name: String
    let last_name: String
    let username: String
    let profile_photo_url: String?

    var fullName: String {
        "\(first_name) \(last_name)".trimmingCharacters(in: .whitespaces)
    }
}
