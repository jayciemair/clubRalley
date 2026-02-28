//
//  ClubRalleyModels.swift
//  Club Ralley
//
//  UI models for ralleys and posts in the Club Ralley app.
//  These models are optimized for display and differ from database models.
//

import Foundation

// MARK: - ClubRalley Model

/**
 * ClubRalley: Simplified UI model for ralley display and creation
 *
 * Purpose: Provides a streamlined representation of ralleys for the UI layer.
 * This model is optimized for view rendering and user interaction.
 *
 * Relationship: Maps to/from the database Ralley model via RalleyService.
 * The service layer handles conversion between this UI model and the
 * database schema (snake_case fields, nested objects, etc.)
 *
 * Usage:
 * - RalleyManager uses this for local state management
 * - FindRalleysView displays cards using this model
 * - Profile views show user's created ralleys
 * - RalleyCreationView creates new instances
 *
 * Example:
 * ```swift
 * let ralley = ClubRalley(
 *     id: UUID(),
 *     title: "Basketball Pickup",
 *     sport: "Basketball",
 *     description: "Friendly game, all welcome!",
 *     organizer: organizer,
 *     dateTime: Date().addingTimeInterval(3600),
 *     location: location,
 *     maxPlayers: 10,
 *     currentPlayers: 3,
 *     cost: 0,
 *     requirements: "",
 *     isPublic: true
 * )
 * ```
 */
struct ClubRalley: Identifiable, Codable {

    // MARK: - Core Properties

    /// Unique identifier for the ralley (matches database UUID)
    var id: UUID

    /// Display title for the ralley (e.g., "Saturday Morning Hoops")
    var title: String

    /// Sport type for categorization and display
    /// Common values: "Basketball", "Tennis", "Soccer", "Volleyball", "Running"
    var sport: String

    /// Detailed description of the ralley
    /// Should explain what to expect, skill level, and any other relevant info
    var description: String

    /// Information about the person who created the ralley
    /// Used for displaying organizer info on ralley cards
    var organizer: ClubRalleyOrganizer

    /// When the ralley is scheduled to start
    /// Displayed in relative time format on cards
    var dateTime: Date

    /// Location details for the ralley
    /// Includes venue name, address, and GPS coordinates
    var location: ClubRalleyLocation

    /// Maximum number of participants allowed
    /// Used to determine if ralley is full
    var maxPlayers: Int

    /// Current number of participants
    /// Displayed as "X/Y players" on cards
    var currentPlayers: Int

    /// Cost to join in dollars (0 for free events)
    /// Displayed as "FREE" or "$X" on cards
    var cost: Int

    /// Any special requirements for participants
    /// e.g., "Bring your own ball", "Intermediate skill level"
    var requirements: String

    /// Whether the ralley is visible to everyone
    /// Private ralleys only show to invited users
    var isPublic: Bool

    /// When the ralley was created (optional for new ralleys being created)
    var createdAt: Date?

    /// Whether the ralley is currently active
    /// Inactive ralleys don't appear in search results
    var isActive: Bool?

    // MARK: - Captain & Chat Properties

    /// Visibility setting - who can see/find this ralley
    var visibility: RalleyVisibility

    /// Join type setting - how users can join
    var joinType: RalleyJoinType

    /// Whether current user is the captain (organizer)
    var isCaptain: Bool

    /// ID of the associated group chat (if created)
    var chatId: UUID?

    /// Number of pending join requests (for captain)
    var pendingRequestsCount: Int

    /// Duration of the ralley in minutes (default: 60)
    var durationMinutes: Int

    /// Whether this ralley repeats weekly
    var isRecurring: Bool

    // MARK: - Computed Properties

    /// Calculated end time based on start time and duration
    var endTime: Date {
        dateTime.addingTimeInterval(Double(durationMinutes) * 60)
    }

    /// Formatted string showing time until the ralley starts
    /// Returns values like "in 2h", "in 3d", "yesterday"
    var timeUntilStart: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: dateTime, relativeTo: Date())
    }

    /// Whether the ralley is full
    var isFull: Bool {
        currentPlayers >= maxPlayers
    }

    /// Number of available spots
    var availableSpots: Int {
        max(0, maxPlayers - currentPlayers)
    }

    /// Whether the ralley is in the past
    var isPast: Bool {
        dateTime < Date()
    }

    /// Whether the ralley is happening soon (within 2 hours)
    var isHappeningSoon: Bool {
        let twoHoursFromNow = Date().addingTimeInterval(2 * 60 * 60)
        return dateTime > Date() && dateTime < twoHoursFromNow
    }

    /// Whether this ralley is restricted to former college athletes
    var isCollegeAthletesOnly: Bool {
        visibility == .collegeAthletesOnly
    }

    /// Whether this ralley requires approval to join
    var requiresApproval: Bool {
        joinType == .approvalRequired
    }

    /// Whether current user can directly join (open join type)
    var canJoinDirectly: Bool {
        joinType == .open && !isFull
    }

    // MARK: - Initialization with Defaults

    /// Initialize with all properties including new captain/chat fields
    init(
        id: UUID,
        title: String,
        sport: String,
        description: String,
        organizer: ClubRalleyOrganizer,
        dateTime: Date,
        location: ClubRalleyLocation,
        maxPlayers: Int,
        currentPlayers: Int,
        cost: Int,
        requirements: String,
        isPublic: Bool,
        createdAt: Date? = nil,
        isActive: Bool? = nil,
        visibility: RalleyVisibility = .anyone,
        joinType: RalleyJoinType = .open,
        isCaptain: Bool = false,
        chatId: UUID? = nil,
        pendingRequestsCount: Int = 0,
        durationMinutes: Int = 60,
        isRecurring: Bool = false
    ) {
        self.id = id
        self.title = title
        self.sport = sport
        self.description = description
        self.organizer = organizer
        self.dateTime = dateTime
        self.location = location
        self.maxPlayers = maxPlayers
        self.currentPlayers = currentPlayers
        self.cost = cost
        self.requirements = requirements
        self.isPublic = isPublic
        self.createdAt = createdAt
        self.isActive = isActive
        self.visibility = visibility
        self.joinType = joinType
        self.isCaptain = isCaptain
        self.chatId = chatId
        self.pendingRequestsCount = pendingRequestsCount
        self.durationMinutes = durationMinutes
        self.isRecurring = isRecurring
    }
}

// MARK: - ClubRalleyOrganizer Model

/**
 * ClubRalleyOrganizer: Information about a ralley organizer
 *
 * Purpose: Stores display information for the person who created a ralley.
 * This is a simplified version of User data optimized for display.
 *
 * Usage:
 * - Displayed on ralley cards showing who's hosting
 * - Shown in ralley detail views
 * - Used for linking to organizer profiles
 *
 * Note: The id field links to the User table for full profile access.
 */
struct ClubRalleyOrganizer: Codable {

    /// Unique user ID of the organizer (links to User table)
    let id: UUID

    /// Display name (typically "First Last")
    let name: String

    /// Username with @ prefix (e.g., "@alexj")
    let username: String

    /// URL string for profile photo
    /// Should be a valid URL that can be loaded with AsyncImage
    let photoURL: String
}

// MARK: - ClubRalleyLocation Model

/**
 * ClubRalleyLocation: Location information for a ralley
 *
 * Purpose: Stores venue details for UI display and map integration.
 *
 * Note: This is separate from RalleyLocation (in Models/Ralley/Ralley.swift)
 * to avoid conflicts between the UI model and database model. The database
 * model has optional address while this UI model requires all fields.
 *
 * Usage:
 * - Displayed on ralley cards
 * - Used for map pins in FindRalleysView
 * - Shown in ralley detail views with full address
 */
struct ClubRalleyLocation: Codable {

    /// Venue name (e.g., "Riverside Park Courts")
    /// This is the primary display name for the location
    let name: String

    /// Street address (e.g., "123 Park Ave")
    let address: String

    /// City name (e.g., "Chicago")
    let city: String

    /// State abbreviation (e.g., "IL")
    let state: String

    /// GPS latitude for map display
    let latitude: Double

    /// GPS longitude for map display
    let longitude: Double

    // MARK: - Computed Properties

    /// Full display address combining all components
    var fullAddress: String {
        if address.isEmpty {
            return "\(city), \(state)"
        }
        return "\(address), \(city), \(state)"
    }

    /// Short display address for cards
    var shortAddress: String {
        "\(city), \(state)"
    }
}

// MARK: - ClubRalleyPost Model

/**
 * ClubRalleyPost: Post model for the social feed
 *
 * Purpose: Represents a user post in the home feed and profile views.
 * Optimized for display with engagement metrics.
 *
 * Usage:
 * - HomeFeedView displays posts
 * - PostCardView renders individual posts
 * - UserPostsSection shows user's posts in profile
 *
 * Database: Maps to posts table via PostService
 */
struct ClubRalleyPost: Identifiable, Codable {

    // MARK: - Core Properties

    /// Unique identifier for the post
    let id: UUID

    /// Display name of the post author
    let authorName: String

    /// Username of the author (with @ prefix)
    let authorUsername: String

    /// URL string for author's profile photo
    let authorPhotoURL: String

    /// Author's user ID
    var authorId: UUID?

    /// Author's school/university (e.g., "Texas A&M", "Bucknell University")
    var authorSchool: String?

    /// Author's location (e.g., "Chicago, IL")
    var authorLocation: String?

    /// Author's sport (e.g., "soccer", "tennis")
    var authorSport: String?

    /// Optional title for the post
    let title: String?

    /// Main content/body of the post
    let content: String

    /// Array of image URLs attached to the post
    let images: [String]

    /// When the post was created
    let timestamp: Date

    // MARK: - Post Type & Visibility

    /// Type of post (text, image, link, ralley completion, etc.)
    var postType: PostType

    /// Visibility setting - who can see this post
    var visibility: PostVisibility

    /// Related ralley ID (for ralley completion posts)
    var relatedRalleyId: UUID?

    /// Tagged user IDs (for ralley completion posts with attendees)
    var taggedUserIds: [UUID]

    /// Link URL (for link posts)
    var linkUrl: String?

    // MARK: - Engagement Properties

    /// Number of likes on the post
    var likes: Int

    /// Number of comments on the post
    var comments: Int

    /// Number of shares/reposts of the post
    var shares: Int

    /// Whether the current user has liked this post
    var isLiked: Bool

    /// Whether the current user has reposted this post
    var isReposted: Bool

    // MARK: - Repost Properties

    /// Original post ID if this is a repost
    var originalPostId: UUID?

    /// Original post author name (for repost display)
    var originalAuthorName: String?

    /// Quote comment added when reposting
    var repostComment: String?

    // MARK: - Computed Properties

    /// Formatted relative time string (e.g., "2h ago", "yesterday")
    var timeAgo: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: timestamp, relativeTo: Date())
    }

    /// Whether the post has any images
    var hasImages: Bool {
        !images.isEmpty
    }

    /// Total engagement count for sorting
    var engagementCount: Int {
        likes + comments + shares
    }

    /// Whether this is a repost
    var isRepost: Bool {
        originalPostId != nil
    }

    /// Whether this is a ralley completion post
    var isRalleyCompletion: Bool {
        postType == .ralleyCompletion
    }

    // MARK: - Initialization

    init(
        id: UUID,
        authorName: String,
        authorUsername: String,
        authorPhotoURL: String,
        authorId: UUID? = nil,
        authorSchool: String? = nil,
        authorLocation: String? = nil,
        authorSport: String? = nil,
        title: String? = nil,
        content: String,
        images: [String] = [],
        timestamp: Date,
        postType: PostType = .text,
        visibility: PostVisibility = .everyone,
        relatedRalleyId: UUID? = nil,
        taggedUserIds: [UUID] = [],
        linkUrl: String? = nil,
        likes: Int = 0,
        comments: Int = 0,
        shares: Int = 0,
        isLiked: Bool = false,
        isReposted: Bool = false,
        originalPostId: UUID? = nil,
        originalAuthorName: String? = nil,
        repostComment: String? = nil
    ) {
        self.id = id
        self.authorName = authorName
        self.authorUsername = authorUsername
        self.authorPhotoURL = authorPhotoURL
        self.authorId = authorId
        self.authorSchool = authorSchool
        self.authorLocation = authorLocation
        self.authorSport = authorSport
        self.title = title
        self.content = content
        self.images = images
        self.timestamp = timestamp
        self.postType = postType
        self.visibility = visibility
        self.relatedRalleyId = relatedRalleyId
        self.taggedUserIds = taggedUserIds
        self.linkUrl = linkUrl
        self.likes = likes
        self.comments = comments
        self.shares = shares
        self.isLiked = isLiked
        self.isReposted = isReposted
        self.originalPostId = originalPostId
        self.originalAuthorName = originalAuthorName
        self.repostComment = repostComment
    }
}
