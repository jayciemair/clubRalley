//
//  Notification.swift
//  Club Ralley
//
//  Model for in-app notifications
//

import Foundation

/// Types of notifications
enum NotificationType: String, Codable, CaseIterable {
    case like = "like"
    case comment = "comment"
    case follow = "follow"
    case ralleyJoin = "ralley_join"
    case ralleyInvite = "ralley_invite"
    case ralleyReminder = "ralley_reminder"
    case mention = "mention"
    case message = "message"
    case system = "system"

    var icon: String {
        switch self {
        case .like: return "heart.fill"
        case .comment: return "bubble.left.fill"
        case .follow: return "person.badge.plus.fill"
        case .ralleyJoin: return "figure.run"
        case .ralleyInvite: return "envelope.fill"
        case .ralleyReminder: return "clock.fill"
        case .mention: return "at"
        case .message: return "message.fill"
        case .system: return "bell.fill"
        }
    }
}

/// App notification model
struct AppNotification: Identifiable, Codable {
    let id: UUID
    let userId: UUID
    let type: NotificationType
    let title: String
    let body: String?
    let isRead: Bool
    let fromUserId: UUID?
    let fromUserName: String?
    let fromUserPhotoURL: String?
    let ralleyId: UUID?
    let postId: UUID?
    let createdAt: Date

    /// Formatted time string for display
    var formattedTime: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: createdAt, relativeTo: Date())
    }
}

/// Database notification model
struct DatabaseNotification: Codable {
    var id: UUID?
    let user_id: UUID
    let type: String
    let title: String
    let body: String?
    let data: NotificationData?
    var is_read: Bool?
    let from_user_id: UUID?
    let ralley_id: UUID?
    let post_id: UUID?
    var created_at: Date?

    init(
        user_id: UUID,
        type: NotificationType,
        title: String,
        body: String? = nil,
        data: NotificationData? = nil,
        from_user_id: UUID? = nil,
        ralley_id: UUID? = nil,
        post_id: UUID? = nil
    ) {
        self.id = nil
        self.user_id = user_id
        self.type = type.rawValue
        self.title = title
        self.body = body
        self.data = data
        self.is_read = nil
        self.from_user_id = from_user_id
        self.ralley_id = ralley_id
        self.post_id = post_id
        self.created_at = nil
    }
}

/// Notification data payload
struct NotificationData: Codable {
    var postId: UUID?
    var ralleyId: UUID?
    var commentId: UUID?
    var actionUrl: String?

    init(postId: UUID? = nil, ralleyId: UUID? = nil, commentId: UUID? = nil, actionUrl: String? = nil) {
        self.postId = postId
        self.ralleyId = ralleyId
        self.commentId = commentId
        self.actionUrl = actionUrl
    }
}

/// Database notification with joined user data
struct DatabaseNotificationWithUser: Codable {
    let id: UUID
    let user_id: UUID
    let type: String
    let title: String
    let body: String?
    let data: NotificationData?
    let is_read: Bool
    let from_user_id: UUID?
    let ralley_id: UUID?
    let post_id: UUID?
    let created_at: Date
    let from_user: DatabaseNotificationUser?

    enum CodingKeys: String, CodingKey {
        case id, user_id, type, title, body, data, is_read, from_user_id, ralley_id, post_id, created_at
        case from_user = "club_users"
    }

    /// Convert to AppNotification
    func toAppNotification() -> AppNotification {
        AppNotification(
            id: id,
            userId: user_id,
            type: NotificationType(rawValue: type) ?? .system,
            title: title,
            body: body,
            isRead: is_read,
            fromUserId: from_user_id,
            fromUserName: from_user.map { "\($0.first_name) \($0.last_name)" },
            fromUserPhotoURL: from_user?.profile_photo_url,
            ralleyId: ralley_id,
            postId: post_id,
            createdAt: created_at
        )
    }
}

/// User data for notification display
struct DatabaseNotificationUser: Codable {
    let id: UUID?
    let first_name: String
    let last_name: String
    let username: String
    let profile_photo_url: String?
}
