//
//  InAppNotificationService.swift
//  Club Ralley
//
//  Service for managing in-app notifications
//

import Foundation
import SwiftUI

/// Service for in-app notifications
@MainActor
class InAppNotificationService: ObservableObject {

    // MARK: - Singleton

    static let shared = InAppNotificationService()

    // MARK: - Dependencies

    private let supabase = SupabaseManager.shared
    private let realtimeManager = RealtimeManager.shared

    // MARK: - Published Properties

    @Published var notifications: [AppNotification] = []
    @Published var unreadCount: Int = 0
    @Published var isLoading = false
    @Published var error: Error?

    // MARK: - Private Properties

    private var isSubscribed = false

    // MARK: - Initialization

    private init() {}

    // MARK: - Setup

    /// Start listening for notifications for the current user
    func startListening() async {
        guard let currentUser = supabase.currentUser else { return }
        guard !isSubscribed else { return }

        // Subscribe to realtime notifications
        realtimeManager.subscribeToNotifications(userId: currentUser.id) { [weak self] payload in
            Task { @MainActor in
                self?.handleNewNotification(payload)
            }
        }

        isSubscribed = true

        // Load existing notifications
        await loadNotifications()
    }

    /// Stop listening for notifications
    func stopListening() async {
        await realtimeManager.unsubscribeFromNotifications()
        isSubscribed = false
    }

    // MARK: - Load Notifications

    /// Load notifications for the current user
    func loadNotifications(limit: Int = 50) async {
        guard supabase.isAuthenticated else { return }
        guard let currentUser = supabase.currentUser else { return }

        isLoading = true
        error = nil

        do {
            let dbNotifications: [DatabaseNotificationWithUser] = try await supabase.query("notifications")
                .select("*, club_users(id, first_name, last_name, username, profile_photo_url)")
                .eq("user_id", value: currentUser.id)
                .order("created_at", ascending: false)
                .execute()

            notifications = dbNotifications.map { $0.toAppNotification() }
            unreadCount = notifications.filter { !$0.isRead }.count

            print("✅ InAppNotificationService: Loaded \(notifications.count) notifications (\(unreadCount) unread)")
            isLoading = false
        } catch {
            self.error = error
            isLoading = false
            print("❌ InAppNotificationService: Failed to load notifications: \(error)")
        }
    }

    // MARK: - Mark as Read

    /// Mark a notification as read
    func markAsRead(_ notificationId: UUID) async {
        guard supabase.isAuthenticated else { return }

        do {
            let update = NotificationReadUpdate(is_read: true)
            try await supabase.update(update, in: "notifications", where: "id = '\(notificationId)'")

            // Update local state
            if let index = notifications.firstIndex(where: { $0.id == notificationId }) {
                var updated = notifications[index]
                updated = AppNotification(
                    id: updated.id,
                    userId: updated.userId,
                    type: updated.type,
                    title: updated.title,
                    body: updated.body,
                    isRead: true,
                    fromUserId: updated.fromUserId,
                    fromUserName: updated.fromUserName,
                    fromUserPhotoURL: updated.fromUserPhotoURL,
                    ralleyId: updated.ralleyId,
                    postId: updated.postId,
                    createdAt: updated.createdAt
                )
                notifications[index] = updated
                unreadCount = notifications.filter { !$0.isRead }.count
            }

            print("✅ InAppNotificationService: Marked notification \(notificationId) as read")
        } catch {
            print("❌ InAppNotificationService: Failed to mark as read: \(error)")
        }
    }

    /// Mark all notifications as read
    func markAllAsRead() async {
        guard supabase.isAuthenticated else { return }
        guard let currentUser = supabase.currentUser else { return }

        do {
            let update = NotificationReadUpdate(is_read: true)
            try await supabase.update(update, in: "notifications", where: "user_id = '\(currentUser.id)' AND is_read = 'false'")

            // Update local state
            notifications = notifications.map { notification in
                AppNotification(
                    id: notification.id,
                    userId: notification.userId,
                    type: notification.type,
                    title: notification.title,
                    body: notification.body,
                    isRead: true,
                    fromUserId: notification.fromUserId,
                    fromUserName: notification.fromUserName,
                    fromUserPhotoURL: notification.fromUserPhotoURL,
                    ralleyId: notification.ralleyId,
                    postId: notification.postId,
                    createdAt: notification.createdAt
                )
            }
            unreadCount = 0

            print("✅ InAppNotificationService: Marked all notifications as read")
        } catch {
            print("❌ InAppNotificationService: Failed to mark all as read: \(error)")
        }
    }

    // MARK: - Create Notifications

    /// Create a notification for a like
    func createLikeNotification(postId: UUID, postOwnerId: UUID) async {
        guard let currentUser = supabase.currentUser else { return }
        guard postOwnerId != currentUser.id else { return } // Don't notify yourself

        await createNotification(
            userId: postOwnerId,
            type: .like,
            title: "\(currentUser.displayName) liked your post",
            fromUserId: currentUser.id,
            postId: postId
        )
    }

    /// Create a notification for a comment
    func createCommentNotification(postId: UUID, postOwnerId: UUID, commentPreview: String) async {
        guard let currentUser = supabase.currentUser else { return }
        guard postOwnerId != currentUser.id else { return }

        let preview = commentPreview.prefix(50)
        await createNotification(
            userId: postOwnerId,
            type: .comment,
            title: "\(currentUser.displayName) commented on your post",
            body: String(preview),
            fromUserId: currentUser.id,
            postId: postId
        )
    }

    /// Create a notification for a new follower
    func createFollowNotification(followedUserId: UUID) async {
        guard let currentUser = supabase.currentUser else { return }
        guard followedUserId != currentUser.id else { return }

        await createNotification(
            userId: followedUserId,
            type: .follow,
            title: "\(currentUser.displayName) started following you",
            fromUserId: currentUser.id
        )
    }

    /// Create a notification for a ralley join
    func createRalleyJoinNotification(ralleyId: UUID, hostId: UUID, ralleyTitle: String) async {
        guard let currentUser = supabase.currentUser else { return }
        guard hostId != currentUser.id else { return }

        await createNotification(
            userId: hostId,
            type: .ralleyJoin,
            title: "\(currentUser.displayName) joined your ralley",
            body: ralleyTitle,
            fromUserId: currentUser.id,
            ralleyId: ralleyId
        )
    }

    /// Create a notification for a ralley invitation
    func createRalleyInviteNotification(userId: UUID, ralleyId: UUID, ralleyTitle: String) async {
        guard let currentUser = supabase.currentUser else { return }

        await createNotification(
            userId: userId,
            type: .ralleyInvite,
            title: "\(currentUser.displayName) invited you to a ralley",
            body: ralleyTitle,
            fromUserId: currentUser.id,
            ralleyId: ralleyId
        )
    }

    // MARK: - Private Methods

    private func createNotification(
        userId: UUID,
        type: NotificationType,
        title: String,
        body: String? = nil,
        fromUserId: UUID? = nil,
        postId: UUID? = nil,
        ralleyId: UUID? = nil
    ) async {
        let notification = DatabaseNotification(
            user_id: userId,
            type: type,
            title: title,
            body: body,
            from_user_id: fromUserId,
            ralley_id: ralleyId,
            post_id: postId
        )

        do {
            try await supabase.insert(notification, into: "notifications")
            print("✅ InAppNotificationService: Created \(type.rawValue) notification for user \(userId)")
        } catch {
            print("❌ InAppNotificationService: Failed to create notification: \(error)")
        }
    }

    private func handleNewNotification(_ payload: NotificationPayload) {
        // Convert payload to AppNotification and add to list
        let notification = AppNotification(
            id: payload.id,
            userId: payload.userId,
            type: NotificationType(rawValue: payload.type) ?? .system,
            title: payload.message,
            body: nil,
            isRead: payload.isRead,
            fromUserId: payload.actorId,
            fromUserName: nil,
            fromUserPhotoURL: nil,
            ralleyId: payload.ralleyId,
            postId: payload.postId,
            createdAt: payload.createdAt
        )

        // Insert at beginning (newest first)
        notifications.insert(notification, at: 0)
        if !notification.isRead {
            unreadCount += 1
        }

        print("✅ InAppNotificationService: Received new notification: \(notification.title)")
    }
}

// MARK: - Helper Structs

struct NotificationReadUpdate: Encodable {
    let is_read: Bool
}
