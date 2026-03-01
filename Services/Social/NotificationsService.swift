//
//  NotificationsService.swift
//  Club Ralley
//
//  Notification models and types used across the app
//

import Foundation
import SwiftUI

// MARK: - App Notification Model

struct AppNotification: Identifiable {
    let id: UUID
    let type: NotificationType
    let actorId: UUID?
    var actorName: String?
    var actorPhotoURL: String?
    var actorUsername: String?
    let postId: UUID?
    let ralleyId: UUID?
    let message: String
    var isRead: Bool
    let createdAt: Date
}

// MARK: - Notification Type

enum NotificationType: String {
    case newFollower = "new_follower"
    case like = "like"
    case comment = "comment"
    case ralleyJoin = "ralley_join"
    case ralleyInvite = "ralley_invite"
    case ralleyReminder = "ralley_reminder"
    case mention = "mention"
    case message = "message"
    case general = "general"

    var icon: String {
        switch self {
        case .newFollower: return "person.badge.plus"
        case .like: return "heart.fill"
        case .comment: return "message.fill"
        case .ralleyJoin: return "sportscourt.fill"
        case .ralleyInvite: return "envelope.fill"
        case .ralleyReminder: return "clock.fill"
        case .mention: return "at"
        case .message: return "envelope.fill"
        case .general: return "bell.fill"
        }
    }

    var iconColor: Color {
        switch self {
        case .newFollower: return Color(hex: "#2C4F40")
        case .like: return .red
        case .comment: return Color(hex: "#2C4F40")
        case .ralleyJoin: return .orange
        case .ralleyInvite: return Color(hex: "#2C4F40")
        case .ralleyReminder: return .blue
        case .mention: return .purple
        case .message: return Color(hex: "#2C4F40")
        case .general: return .gray
        }
    }
}
