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
    let id: UUID

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

    // MARK: - Computed Properties

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

    /// Optional title for the post
    let title: String?

    /// Main content/body of the post
    let content: String

    /// Array of image URLs attached to the post
    let images: [String]

    /// When the post was created
    let timestamp: Date

    // MARK: - Engagement Properties

    /// Number of likes on the post
    var likes: Int

    /// Number of comments on the post
    var comments: Int

    /// Number of shares of the post
    var shares: Int

    /// Whether the current user has liked this post
    var isLiked: Bool

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
}
