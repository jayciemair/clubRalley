//
//  PostEngagementModels.swift
//  Club Ralley
//
//  Helper structs for PostEngagementService JSONB operations.
//  Extracted from PostEngagementService.swift to keep file sizes manageable.
//

import Foundation

// MARK: - Helper Structs for JSONB Operations

/// Post with likes JSONB array
struct PostWithLikes: Codable {
    let id: UUID
    var likes: [String]?
    var likes_count: Int
    var comments_count: Int
    var shares_count: Int?

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        likes_count = try container.decodeIfPresent(Int.self, forKey: .likes_count) ?? 0
        comments_count = try container.decodeIfPresent(Int.self, forKey: .comments_count) ?? 0
        shares_count = try container.decodeIfPresent(Int.self, forKey: .shares_count)

        // Handle likes as either array of strings or nil
        if let likesArray = try? container.decodeIfPresent([String].self, forKey: .likes) {
            likes = likesArray
        } else {
            likes = []
        }
    }
}

/// Update struct for post likes
struct PostLikesUpdate: Codable {
    let likes: [String]
    let likes_count: Int
}

/// Update struct for post comments count
struct PostCommentsCountUpdate: Codable {
    let comments_count: Int
}

/// Update struct for post shares count
struct PostSharesUpdate: Codable {
    let shares_count: Int
}

/// Insert struct for creating a repost
struct DatabaseRepostInsert: Codable {
    let user_id: UUID
    let content: String
    let post_type: String
    let visibility: String
    let original_post_id: UUID
    let repost_comment: String?
}

/// Simple struct for counting reposts
struct DatabaseRepostCount: Codable {
    let id: UUID
}

/// Struct for getting post owner ID
struct DatabasePostOwner: Codable {
    let user_id: UUID
}

/// Struct for getting post with owner and comments count
struct DatabasePostWithOwner: Codable {
    let id: UUID
    let comments_count: Int
    let user_id: UUID
}
