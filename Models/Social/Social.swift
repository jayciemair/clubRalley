//
//  Social.swift
//  Club Ralley
//
//  Social features models - friendships, posts, feed activity
//

import Foundation

// MARK: - Friendship Management

struct Friendship: Codable, Identifiable {
    let id: UUID
    let requesterId: UUID
    let addresseeId: UUID
    let status: FriendshipStatus
    let createdAt: Date
    let acceptedAt: Date?
    
    // User information (populated via joins)
    let requester: User?
    let addressee: User?
    
    enum CodingKeys: String, CodingKey {
        case id
        case requesterId = "requester_id"
        case addresseeId = "addressee_id"
        case status
        case createdAt = "created_at"
        case acceptedAt = "accepted_at"
        case requester
        case addressee
    }
}

enum FriendshipStatus: String, Codable, CaseIterable {
    case pending = "pending"
    case accepted = "accepted"
    case blocked = "blocked"
    
    var displayName: String {
        switch self {
        case .pending: return "Pending"
        case .accepted: return "Friends"
        case .blocked: return "Blocked"
        }
    }
}

struct FriendRequest: Codable, Identifiable {
    let id: UUID
    let fromUser: User
    let toUserId: UUID
    let createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case fromUser = "from_user"
        case toUserId = "to_user_id"
        case createdAt = "created_at"
    }
}

// MARK: - Social Feed Posts

struct Post: Codable, Identifiable {
    let id: UUID
    let userId: UUID
    let content: String
    let type: PostType
    let createdAt: Date
    let updatedAt: Date
    
    // Engagement metrics
    let likesCount: Int
    let commentsCount: Int
    
    // User relationship data
    let user: User?
    let isLikedByCurrentUser: Bool?
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case content
        case type
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case likesCount = "likes_count"
        case commentsCount = "comments_count"
        case user
        case isLikedByCurrentUser = "is_liked_by_current_user"
    }
}

enum PostType: String, Codable, CaseIterable {
    case text = "text"
    case ralleyUpdate = "ralley_update"
    case achievement = "achievement"
    case image = "image"
    case link = "link"
    case ralleyCompletion = "ralley_completion"

    var displayName: String {
        switch self {
        case .text: return "Text Post"
        case .ralleyUpdate: return "Ralley Update"
        case .achievement: return "Achievement"
        case .image: return "Photo"
        case .link: return "Link"
        case .ralleyCompletion: return "Ralley Completed"
        }
    }

    var iconName: String {
        switch self {
        case .text: return "text.alignleft"
        case .ralleyUpdate: return "sportscourt"
        case .achievement: return "trophy.fill"
        case .image: return "photo.fill"
        case .link: return "link"
        case .ralleyCompletion: return "checkmark.circle.fill"
        }
    }
}

struct PostLike: Codable, Identifiable {
    let id: UUID
    let postId: UUID
    let userId: UUID
    let createdAt: Date
    let user: User?
    
    enum CodingKeys: String, CodingKey {
        case id
        case postId = "post_id"
        case userId = "user_id"
        case createdAt = "created_at"
        case user
    }
}

struct PostComment: Codable, Identifiable {
    let id: UUID
    let postId: UUID
    let userId: UUID
    let content: String
    let createdAt: Date
    let user: User?
    
    enum CodingKeys: String, CodingKey {
        case id
        case postId = "post_id"
        case userId = "user_id"
        case content
        case createdAt = "created_at"
        case user
    }
}

// MARK: - Activity Feed

struct ActivityFeedItem: Codable, Identifiable {
    let id: UUID
    let type: ActivityType
    let userId: UUID
    let createdAt: Date
    let data: ActivityData
    
    // User information
    let user: User?
    
    enum CodingKeys: String, CodingKey {
        case id
        case type
        case userId = "user_id"
        case createdAt = "created_at"
        case data
        case user
    }
}

enum ActivityType: String, Codable, CaseIterable {
    case joinedRalley = "joined_ralley"
    case createdRalley = "created_ralley"
    case newFriend = "new_friend"
    case postedUpdate = "posted_update"
    
    var displayTemplate: String {
        switch self {
        case .joinedRalley: return "{user} joined a ralley"
        case .createdRalley: return "{user} created a new ralley"
        case .newFriend: return "{user} made a new friend"
        case .postedUpdate: return "{user} posted an update"
        }
    }
}

struct ActivityData: Codable {
    let ralleyId: UUID?
    let ralleyTitle: String?
    let friendId: UUID?
    let friendName: String?
    let postId: UUID?
    let postContent: String?
    
    enum CodingKeys: String, CodingKey {
        case ralleyId = "ralley_id"
        case ralleyTitle = "ralley_title"
        case friendId = "friend_id"
        case friendName = "friend_name"
        case postId = "post_id"
        case postContent = "post_content"
    }
}

// MARK: - User Preferences & Settings

struct UserPreferences: Codable {
    let userId: UUID
    let hobbies: [String]
    let availability: [AvailabilitySlot]
    let maxDistance: Int  // in miles
    let notificationSettings: NotificationSettings
    let privacySettings: PrivacySettings
    let updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case hobbies
        case availability
        case maxDistance = "max_distance"
        case notificationSettings = "notification_settings"
        case privacySettings = "privacy_settings"
        case updatedAt = "updated_at"
    }
}

struct AvailabilitySlot: Codable, Identifiable {
    let id: UUID
    let dayOfWeek: Int  // 1 = Monday, 7 = Sunday
    let startTime: String  // HH:mm format
    let endTime: String    // HH:mm format
    
    var dayName: String {
        let days = ["", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]
        return days[dayOfWeek]
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case dayOfWeek = "day_of_week"
        case startTime = "start_time"
        case endTime = "end_time"
    }
}

struct NotificationSettings: Codable {
    let ralleyInvites: Bool
    let friendRequests: Bool
    let ralleyReminders: Bool
    let socialUpdates: Bool
    let newMatches: Bool
    
    enum CodingKeys: String, CodingKey {
        case ralleyInvites = "ralley_invites"
        case friendRequests = "friend_requests"
        case ralleyReminders = "ralley_reminders"
        case socialUpdates = "social_updates"
        case newMatches = "new_matches"
    }
}

struct PrivacySettings: Codable {
    let profileVisibility: ProfileVisibility
    let showLocation: Bool
    let showAge: Bool
    let allowFriendRequests: Bool
    
    enum CodingKeys: String, CodingKey {
        case profileVisibility = "profile_visibility"
        case showLocation = "show_location"
        case showAge = "show_age"
        case allowFriendRequests = "allow_friend_requests"
    }
}

enum ProfileVisibility: String, Codable, CaseIterable {
    case everyone = "everyone"
    case friendsOnly = "friends_only"
    case privateProfile = "private"
    
    var displayName: String {
        switch self {
        case .everyone: return "Everyone"
        case .friendsOnly: return "Friends Only"
        case .privateProfile: return "Private"
        }
    }
}