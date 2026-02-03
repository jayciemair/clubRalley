//
//  DatabasePost.swift
//  Club Ralley
//
//  Post-related database models
//

import Foundation

// MARK: - Post Database Models

/// Database representation of post (matches Supabase posts table schema)
struct DatabasePost: Codable {
    let user_id: UUID
    let content: String
    let post_type: String
    let likes_count: Int
    let comments_count: Int
    let visibility: String
    let ralley_id: UUID?
    let tagged_user_ids: [UUID]?
    let link_url: String?
    let shares_count: Int

    init(
        user_id: UUID,
        content: String,
        post_type: String,
        likes_count: Int = 0,
        comments_count: Int = 0,
        visibility: String = "everyone",
        ralley_id: UUID? = nil,
        tagged_user_ids: [UUID]? = nil,
        link_url: String? = nil,
        shares_count: Int = 0
    ) {
        self.user_id = user_id
        self.content = content
        self.post_type = post_type
        self.likes_count = likes_count
        self.comments_count = comments_count
        self.visibility = visibility
        self.ralley_id = ralley_id
        self.tagged_user_ids = tagged_user_ids
        self.link_url = link_url
        self.shares_count = shares_count
    }
}

/// Database post with joined user information
struct DatabasePostWithUser: Codable {
    let id: UUID
    let user_id: UUID
    let content: String
    let post_type: String
    let likes_count: Int
    let comments_count: Int
    let shares_count: Int?
    let visibility: String?
    let ralley_id: UUID?
    let tagged_user_ids: [UUID]?
    let link_url: String?
    let original_post_id: UUID?
    let repost_comment: String?
    let created_at: Date
    let updated_at: Date
    let user: DatabaseUser

    enum CodingKeys: String, CodingKey {
        case id, user_id, content, post_type, likes_count, comments_count
        case shares_count, visibility, ralley_id, tagged_user_ids, link_url
        case original_post_id, repost_comment, created_at, updated_at
        case user = "club_users"
    }
}

/// Database representation of a repost
struct DatabaseRepost: Codable {
    let original_post_id: UUID
    let user_id: UUID
    let comment: String?

    init(original_post_id: UUID, user_id: UUID, comment: String? = nil) {
        self.original_post_id = original_post_id
        self.user_id = user_id
        self.comment = comment
    }
}

/// Database repost with joined information
struct DatabaseRepostWithUser: Codable {
    let id: UUID
    let original_post_id: UUID
    let user_id: UUID
    let comment: String?
    let created_at: Date
    let user: DatabaseUser

    enum CodingKeys: String, CodingKey {
        case id, original_post_id, user_id, comment, created_at
        case user = "club_users"
    }
}

/// Database representation of ralley post opt-out
struct DatabaseRalleyPostOptOut: Codable {
    let ralley_id: UUID
    let user_id: UUID
}

/// Database representation of a post report
struct DatabasePostReport: Codable {
    let post_id: UUID
    let reporter_id: UUID
    let reason: String
}

/// Database representation of a post like
struct DatabasePostLike: Codable {
    var id: UUID?
    let post_id: UUID
    let user_id: UUID
    var created_at: Date?

    init(post_id: UUID, user_id: UUID) {
        self.id = nil
        self.post_id = post_id
        self.user_id = user_id
        self.created_at = nil
    }

    enum CodingKeys: String, CodingKey {
        case id, post_id, user_id, created_at
    }
}
