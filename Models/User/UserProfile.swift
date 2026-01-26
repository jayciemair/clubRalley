//
//  UserProfile.swift
//  Club Ralley
//
//  Extended user profile models with social features and athlete info
//

import Foundation

// MARK: - User Profile with Social Features

struct UserProfile: Codable, Identifiable {
    let id: UUID
    let user: User
    let stats: UserStats
    let socialInfo: SocialInfo
    let teams: [UserTeam]
    let photos: [UserPhoto]
    let mutualFriends: [MutualFriend]
    let isFollowedByCurrentUser: Bool?
    let relationshipStatus: RelationshipStatus
    
    enum CodingKeys: String, CodingKey {
        case id
        case user
        case stats
        case socialInfo = "social_info"
        case teams
        case photos
        case mutualFriends = "mutual_friends"
        case isFollowedByCurrentUser = "is_followed_by_current_user"
        case relationshipStatus = "relationship_status"
    }
}

struct UserStats: Codable {
    let followersCount: Int
    let followingCount: Int
    let gamesPlayed: Int
    let wins: Int
    let postsCount: Int
    let ralleysAttended: Int
    let ralleysHosted: Int
    
    enum CodingKeys: String, CodingKey {
        case followersCount = "followers_count"
        case followingCount = "following_count"
        case gamesPlayed = "games_played"
        case wins
        case postsCount = "posts_count"
        case ralleysAttended = "ralleys_attended"
        case ralleysHosted = "ralleys_hosted"
    }
}

struct SocialInfo: Codable {
    let instagramHandle: String?
    let linkedinHandle: String?
    let twitterHandle: String?
    let isVerifiedAthlete: Bool
    let verificationBadge: String?
    let joinedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case instagramHandle = "instagram_handle"
        case linkedinHandle = "linkedin_handle"
        case twitterHandle = "twitter_handle"
        case isVerifiedAthlete = "is_verified_athlete"
        case verificationBadge = "verification_badge"
        case joinedAt = "joined_at"
    }
}

struct UserTeam: Codable, Identifiable {
    let id: UUID
    let name: String
    let sport: String
    let level: String // "D1", "D2", "Club", etc.
    let school: String?
    let years: String? // "2021-2025"
    let imageURL: String?
    let isCurrentTeam: Bool
    let achievements: [String]
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case sport
        case level
        case school
        case years
        case imageURL = "image_url"
        case isCurrentTeam = "is_current_team"
        case achievements
    }
}

struct UserPhoto: Codable, Identifiable {
    let id: UUID
    let imageURL: String
    let caption: String?
    let createdAt: Date
    let likesCount: Int
    let commentsCount: Int
    let tags: [String]
    
    enum CodingKeys: String, CodingKey {
        case id
        case imageURL = "image_url"
        case caption
        case createdAt = "created_at"
        case likesCount = "likes_count"
        case commentsCount = "comments_count"
        case tags
    }
}

struct MutualFriend: Codable, Identifiable {
    let id: UUID
    let user: User
    
    var displayName: String {
        user.firstName
    }
    
    var profileImageURL: String? {
        user.profilePhotoURL
    }
}

enum RelationshipStatus: String, Codable {
    case none = "none"
    case following = "following"
    case followedBy = "followed_by"
    case mutual = "mutual"
    case blocked = "blocked"
    
    var displayText: String {
        switch self {
        case .none: return ""
        case .following: return "Following"
        case .followedBy: return "Follows you"
        case .mutual: return "Mutual"
        case .blocked: return "Blocked"
        }
    }
}

// MARK: - Profile Actions

enum ProfileAction {
    case follow
    case unfollow
    case message
    case block
    case report
    case share
}

struct ProfileActionRequest: Codable {
    let targetUserId: UUID
    let action: String // follow, unfollow, etc.
    
    enum CodingKeys: String, CodingKey {
        case targetUserId = "target_user_id"
        case action
    }
}

// MARK: - Enhanced Athlete Info

struct AthleteCredentials: Codable {
    let level: AthleteLevel
    let sport: String
    let school: String
    let classYear: String
    let achievements: [Achievement]
    let stats: AthleteStats?
    
    enum CodingKeys: String, CodingKey {
        case level
        case sport
        case school
        case classYear = "class_year"
        case achievements
        case stats
    }
}

enum AthleteLevel: String, Codable, CaseIterable {
    case d1 = "D1"
    case d2 = "D2"
    case d3 = "D3"
    case naia = "NAIA"
    case juco = "JUCO"
    case club = "Club"
    case intramural = "Intramural"
    case professional = "Professional"
    
    var displayName: String {
        rawValue
    }
    
    var prestige: Int {
        switch self {
        case .professional: return 10
        case .d1: return 9
        case .d2: return 8
        case .d3: return 7
        case .naia: return 6
        case .juco: return 5
        case .club: return 4
        case .intramural: return 3
        }
    }
}

struct Achievement: Codable, Identifiable {
    let id: UUID
    let title: String
    let description: String
    let year: String?
    let icon: String
    let category: AchievementCategory
    
    enum CodingKeys: String, CodingKey {
        case id
        case title
        case description
        case year
        case icon
        case category
    }
}

enum AchievementCategory: String, Codable {
    case individual = "individual"
    case team = "team"
    case academic = "academic"
    case leadership = "leadership"
    case community = "community"
    
    var displayName: String {
        switch self {
        case .individual: return "Individual"
        case .team: return "Team"
        case .academic: return "Academic"
        case .leadership: return "Leadership"
        case .community: return "Community"
        }
    }
}

struct AthleteStats: Codable {
    let gamesPlayed: Int
    let wins: Int
    let losses: Int
    let seasonStats: [String: Double] // sport-specific stats
    let careerHighlights: [String]
    
    var winPercentage: Double {
        guard gamesPlayed > 0 else { return 0.0 }
        return Double(wins) / Double(gamesPlayed)
    }
    
    enum CodingKeys: String, CodingKey {
        case gamesPlayed = "games_played"
        case wins
        case losses
        case seasonStats = "season_stats"
        case careerHighlights = "career_highlights"
    }
}