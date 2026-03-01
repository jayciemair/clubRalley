//
//  DatabasePost.swift
//  Club Ralley
//
//  Post-related database models
//

import Foundation

// MARK: - Post Database Models

/// Database representation of post (matches Supabase posts table schema)
/// Actual columns: id, user_id, content, image_url, ralley_id, likes_count, liked_by, created_at
struct DatabasePost: Codable {
    let user_id: UUID
    let content: String
    let image_url: String?
    let ralley_id: UUID?
    let likes_count: Int
    let liked_by: [String]
    let post_type: String
    let sport: String?

    init(
        user_id: UUID,
        content: String,
        likes_count: Int = 0,
        ralley_id: UUID? = nil,
        image_url: String? = nil,
        liked_by: [String] = [],
        post_type: String = "text",
        sport: String? = nil
    ) {
        self.user_id = user_id
        self.content = content
        self.ralley_id = ralley_id
        self.likes_count = likes_count
        self.image_url = image_url
        self.liked_by = liked_by
        self.post_type = post_type
        self.sport = sport
    }
}

/// Database post with joined user information
/// Actual columns: id, user_id, content, image_url, ralley_id, likes_count, liked_by, created_at
struct DatabasePostWithUser: Codable {
    let id: UUID
    let user_id: UUID
    let content: String
    let image_url: String?
    let ralley_id: UUID?
    let likes_count: Int
    let liked_by: [UUID]?
    let created_at: Date
    let post_type: String?
    let sport: String?
    let user: DatabaseUser

    // Computed properties for backwards compatibility with app models
    var resolvedPostType: String { post_type ?? (image_url != nil ? "image" : "text") }
    var comments_count: Int { 0 }
    var shares_count: Int? { 0 }
    var visibility: String? { "everyone" }
    var tagged_user_ids: [UUID]? { nil }
    var link_url: String? { nil }
    var original_post_id: UUID? { nil }
    var repost_comment: String? { nil }
    var updated_at: Date { created_at }

    enum CodingKeys: String, CodingKey {
        case id, user_id, content, image_url, ralley_id
        case likes_count, liked_by, created_at, post_type, sport
        case user = "club_users"
    }
}

/// Database representation of a repost (insert model — matches reposts table columns)
struct DatabaseRepost: Codable {
    let original_post_id: UUID
    let user_id: UUID
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
