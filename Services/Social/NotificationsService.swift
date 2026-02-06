//
//  NotificationsService.swift
//  Club Ralley
//
//  Service for managing user notifications
//

import Foundation
import SwiftUI

@MainActor
class NotificationsService: ObservableObject {

    // MARK: - Published Properties

    @Published var notifications: [AppNotification] = []
    @Published var unreadCount: Int = 0
    @Published var isLoading = false
    @Published var error: Error?

    // MARK: - Dependencies

    private let supabase = SupabaseManager.shared

    // MARK: - Initialization

    init() {
        Task {
            await loadNotifications()
        }
    }

    // MARK: - Load Notifications

    func loadNotifications() async {
        guard supabase.isAuthenticated else {
            notifications = generateMockNotifications()
            unreadCount = notifications.filter { !$0.isRead }.count
            return
        }

        isLoading = true
        error = nil

        guard let userId = supabase.currentUser?.id else {
            notifications = generateMockNotifications()
            unreadCount = notifications.filter { !$0.isRead }.count
            isLoading = false
            return
        }

        do {
            let dbNotifications: [DatabaseNotificationWithUser] = try await supabase.query("notifications")
                .select("*, club_users(first_name, last_name, username, profile_photo_url)")
                .eq("user_id", value: userId)
                .order("created_at", ascending: false)
                .limit(50)
                .execute()

            notifications = dbNotifications.map { mapDatabaseNotificationToApp($0) }
            unreadCount = notifications.filter { !$0.isRead }.count

            print("NotificationsService: Loaded \(notifications.count) notifications")
        } catch {
            print("Failed to load notifications: \(error)")
            self.error = error

            // Use mock data for development
            notifications = generateMockNotifications()
            unreadCount = notifications.filter { !$0.isRead }.count
        }

        isLoading = false
    }

    // MARK: - Mark as Read

    func markAsRead(_ id: UUID) async {
        // Optimistic update
        if let index = notifications.firstIndex(where: { $0.id == id }) {
            notifications[index].isRead = true
            unreadCount = notifications.filter { !$0.isRead }.count
        }

        guard supabase.isAuthenticated else { return }

        do {
            try await supabase.update(
                ["is_read": true],
                in: "notifications",
                where: "id = '\(id)'"
            )
            print("Marked notification as read: \(id)")
        } catch {
            print("Failed to mark notification as read: \(error)")
        }
    }

    func markAllAsRead() async {
        // Optimistic update
        for index in notifications.indices {
            notifications[index].isRead = true
        }
        unreadCount = 0

        guard supabase.isAuthenticated, let userId = supabase.currentUser?.id else { return }

        do {
            try await supabase.update(
                ["is_read": true],
                in: "notifications",
                where: "user_id = '\(userId)'"
            )
            print("Marked all notifications as read")
        } catch {
            print("Failed to mark all notifications as read: \(error)")
        }
    }

    // MARK: - Helpers

    private func mapDatabaseNotificationToApp(_ dbNotification: DatabaseNotificationWithUser) -> AppNotification {
        return AppNotification(
            id: dbNotification.id,
            type: NotificationType(rawValue: dbNotification.type) ?? .general,
            actorId: dbNotification.actor_id,
            actorName: dbNotification.actor.map { "\($0.first_name) \($0.last_name)" },
            actorPhotoURL: dbNotification.actor?.profile_photo_url,
            actorUsername: dbNotification.actor?.username,
            postId: dbNotification.post_id,
            ralleyId: dbNotification.ralley_id,
            message: dbNotification.message,
            isRead: dbNotification.is_read,
            createdAt: dbNotification.created_at
        )
    }

    private func generateMockNotifications() -> [AppNotification] {
        return [
            AppNotification(
                id: UUID(),
                type: .newFollower,
                actorId: UUID(),
                actorName: "Sarah Wilson",
                actorPhotoURL: "https://picsum.photos/44/44?random=100",
                actorUsername: "sarahw",
                postId: nil,
                ralleyId: nil,
                message: "Sarah Wilson started following you",
                isRead: false,
                createdAt: Date().addingTimeInterval(-1800)
            ),
            AppNotification(
                id: UUID(),
                type: .comment,
                actorId: UUID(),
                actorName: "Mike Johnson",
                actorPhotoURL: "https://picsum.photos/44/44?random=101",
                actorUsername: "mikej",
                postId: UUID(),
                ralleyId: nil,
                message: "Mike Johnson commented on your post",
                isRead: false,
                createdAt: Date().addingTimeInterval(-3600)
            ),
            AppNotification(
                id: UUID(),
                type: .like,
                actorId: UUID(),
                actorName: "Emily Chen",
                actorPhotoURL: "https://picsum.photos/44/44?random=102",
                actorUsername: "emilyc",
                postId: UUID(),
                ralleyId: nil,
                message: "Emily Chen liked your post",
                isRead: true,
                createdAt: Date().addingTimeInterval(-7200)
            ),
            AppNotification(
                id: UUID(),
                type: .ralleyJoin,
                actorId: UUID(),
                actorName: "Alex Thompson",
                actorPhotoURL: "https://picsum.photos/44/44?random=103",
                actorUsername: "alext",
                postId: nil,
                ralleyId: UUID(),
                message: "Alex Thompson joined your ralley",
                isRead: true,
                createdAt: Date().addingTimeInterval(-86400)
            ),
            AppNotification(
                id: UUID(),
                type: .ralleyReminder,
                actorId: nil,
                actorName: nil,
                actorPhotoURL: nil,
                actorUsername: nil,
                postId: nil,
                ralleyId: UUID(),
                message: "Your basketball ralley starts in 1 hour",
                isRead: true,
                createdAt: Date().addingTimeInterval(-172800)
            )
        ]
    }
}

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
        case .ralleyReminder: return .blue
        case .mention: return .purple
        case .message: return Color(hex: "#2C4F40")
        case .general: return .gray
        }
    }
}

// MARK: - Database Models

struct DatabaseNotificationWithUser: Codable {
    let id: UUID
    let user_id: UUID
    let type: String
    let message: String
    let actor_id: UUID?
    let post_id: UUID?
    let ralley_id: UUID?
    let is_read: Bool
    let created_at: Date
    let actor: DatabaseNotificationActor?

    enum CodingKeys: String, CodingKey {
        case id, user_id, type, message, actor_id, post_id, ralley_id, is_read, created_at
        case actor = "club_users"
    }
}

struct DatabaseNotificationActor: Codable {
    let first_name: String
    let last_name: String
    let username: String
    let profile_photo_url: String?
}
