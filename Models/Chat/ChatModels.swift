//
//  ChatModels.swift
//  Club Ralley
//
//  Models for ralley visibility, join types, and group chat functionality.
//

import Foundation

// MARK: - Ralley Visibility

/**
 * Defines who can see/find a ralley
 */
enum RalleyVisibility: String, Codable, CaseIterable {
    /// Anyone can see the ralley
    case anyone = "anyone"

    /// Only mutual friends can see the ralley
    case mutualFriends = "mutual_friends"

    /// Only friends (people you follow who follow you back) can see
    case friends = "friends"

    var displayName: String {
        switch self {
        case .anyone: return "Anyone"
        case .mutualFriends: return "Mutual Friends"
        case .friends: return "Friends Only"
        }
    }

    var description: String {
        switch self {
        case .anyone: return "Visible to everyone on Club Ralley"
        case .mutualFriends: return "Only people you both follow can see"
        case .friends: return "Only your friends can see this ralley"
        }
    }

    var iconName: String {
        switch self {
        case .anyone: return "globe"
        case .mutualFriends: return "person.2"
        case .friends: return "lock"
        }
    }
}

// MARK: - Ralley Join Type

/**
 * Defines how users can join a ralley
 */
enum RalleyJoinType: String, Codable, CaseIterable {
    /// Open - anyone who can see it can join immediately
    case open = "open"

    /// Approval required - captain must approve join requests
    case approvalRequired = "approval_required"

    var displayName: String {
        switch self {
        case .open: return "Open"
        case .approvalRequired: return "Approval Required"
        }
    }

    var description: String {
        switch self {
        case .open: return "Anyone can join instantly"
        case .approvalRequired: return "You approve who joins"
        }
    }

    var iconName: String {
        switch self {
        case .open: return "door.left.hand.open"
        case .approvalRequired: return "checkmark.shield"
        }
    }
}

// MARK: - Chat Member Role

/**
 * Role of a member in a group chat
 */
enum ChatMemberRole: String, Codable {
    /// Admin can manage members and chat settings
    case admin = "admin"

    /// Regular member can send/receive messages
    case member = "member"
}

// MARK: - Chat Message Type

/**
 * Type of message in a chat
 */
enum ChatMessageType: String, Codable {
    /// Regular text message from a user
    case text = "text"

    /// System message (e.g., "John joined the chat")
    case system = "system"
}

// MARK: - Group Chat Model

/**
 * UI model for a group chat associated with a ralley
 */
struct GroupChat: Identifiable, Codable {
    /// Unique identifier for the chat
    let id: UUID

    /// ID of the associated ralley
    let ralleyId: UUID

    /// Title of the ralley (for display)
    let ralleyTitle: String

    /// Sport type of the ralley
    let ralleySport: String

    /// Date/time of the ralley
    let ralleyDateTime: Date

    /// When the chat was created
    let createdAt: Date

    /// Number of members in the chat
    var memberCount: Int

    /// Most recent message preview (if any)
    var lastMessage: String?

    /// When the last message was sent
    var lastMessageAt: Date?

    /// Whether there are unread messages
    var hasUnread: Bool

    /// Current user's role in this chat
    var currentUserRole: ChatMemberRole

    // MARK: - Computed Properties

    /// Formatted time for last message
    var lastMessageTimeAgo: String? {
        guard let lastMessageAt = lastMessageAt else { return nil }
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: lastMessageAt, relativeTo: Date())
    }

    /// Whether current user is admin
    var isAdmin: Bool {
        currentUserRole == .admin
    }
}

// MARK: - Group Chat Message Model

/**
 * UI model for a message in a group chat
 */
struct GroupChatMessage: Identifiable, Codable, Equatable {
    /// Unique identifier for the message
    let id: UUID

    /// ID of the chat this message belongs to
    let chatId: UUID

    /// ID of the sender (nil for system messages)
    let senderId: UUID?

    /// Sender's display name
    let senderName: String

    /// Sender's username
    let senderUsername: String

    /// Sender's profile photo URL
    let senderPhotoURL: String?

    /// Message content
    let content: String

    /// Type of message
    let messageType: ChatMessageType

    /// When the message was sent
    let createdAt: Date

    /// Whether this message is from the current user
    var isFromCurrentUser: Bool

    // MARK: - Computed Properties

    /// Formatted timestamp for display
    var formattedTime: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: createdAt)
    }

    /// Whether this is a system message
    var isSystemMessage: Bool {
        messageType == .system
    }

    static func == (lhs: GroupChatMessage, rhs: GroupChatMessage) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Chat Member Model

/**
 * UI model for a member of a group chat
 */
struct GroupChatMember: Identifiable, Codable {
    /// Unique identifier (same as user ID)
    let id: UUID

    /// Member's display name
    let name: String

    /// Member's username
    let username: String

    /// Member's profile photo URL
    let photoURL: String?

    /// Member's role in the chat
    let role: ChatMemberRole

    /// When they joined the chat
    let joinedAt: Date

    /// Whether this is the current user
    var isCurrentUser: Bool

    // MARK: - Computed Properties

    /// Whether member is admin
    var isAdmin: Bool {
        role == .admin
    }
}

// MARK: - Pending Join Request Model

/**
 * Model for a pending join request to a private ralley
 */
struct PendingJoinRequest: Identifiable, Codable {
    /// Request ID (using participant record ID)
    let id: UUID

    /// ID of the ralley
    let ralleyId: UUID

    /// ID of the requesting user
    let userId: UUID

    /// Requester's display name
    let userName: String

    /// Requester's username
    let userUsername: String

    /// Requester's profile photo URL
    let userPhotoURL: String?

    /// Number of mutual friends with captain
    let mutualCount: Int

    /// When the request was made
    let requestedAt: Date

    // MARK: - Computed Properties

    /// Formatted time since request
    var timeAgo: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: requestedAt, relativeTo: Date())
    }
}
