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
                .select("*, club_users(first_name, last_name, username, profile_photo_url)")
                .eq("user_id", value: currentUser.id)
                .order("created_at", ascending: false)
                .execute()

            notifications = dbNotifications.map { $0.toAppNotification() }
            unreadCount = notifications.filter { !$0.isRead }.count

            print("InAppNotificationService: Loaded \(notifications.count) notifications (\(unreadCount) unread)")
            isLoading = false
        } catch {
            self.error = error
            isLoading = false
            print("InAppNotificationService: Failed to load notifications: \(error)")
        }
    }

    // MARK: - Mark as Read

    /// Mark a notification as read
    func markAsRead(_ notificationId: UUID) async {
        // Optimistic update
        if let index = notifications.firstIndex(where: { $0.id == notificationId }) {
            notifications[index].isRead = true
            unreadCount = notifications.filter { !$0.isRead }.count
        }

        guard supabase.isAuthenticated else { return }

        do {
            let update = NotificationReadUpdate(is_read: true)
            try await supabase.update(update, in: "notifications", where: "id = '\(notificationId)'")
        } catch {
            print("InAppNotificationService: Failed to mark as read: \(error)")
        }
    }

    /// Mark all notifications as read
    func markAllAsRead() async {
        // Optimistic update
        for index in notifications.indices {
            notifications[index].isRead = true
        }
        unreadCount = 0

        guard supabase.isAuthenticated else { return }
        guard let currentUser = supabase.currentUser else { return }

        do {
            let update = NotificationReadUpdate(is_read: true)
            try await supabase.update(update, in: "notifications", where: "user_id = '\(currentUser.id)' AND is_read = 'false'")
        } catch {
            print("InAppNotificationService: Failed to mark all as read: \(error)")
        }
    }

    // MARK: - Create Notifications

    /// Create a notification for a like
    func createLikeNotification(postId: UUID, postOwnerId: UUID) async {
        guard let currentUser = supabase.currentUser else { return }
        guard postOwnerId != currentUser.id else { return }

        await createNotification(
            userId: postOwnerId,
            type: .like,
            message: "\(currentUser.displayName) liked your post",
            actorId: currentUser.id,
            postId: postId
        )
    }

    /// Create a notification for a comment
    func createCommentNotification(postId: UUID, postOwnerId: UUID, commentPreview: String) async {
        guard let currentUser = supabase.currentUser else { return }
        guard postOwnerId != currentUser.id else { return }

        await createNotification(
            userId: postOwnerId,
            type: .comment,
            message: "\(currentUser.displayName) commented: \(String(commentPreview.prefix(50)))",
            actorId: currentUser.id,
            postId: postId
        )
    }

    /// Create a notification for a new follower
    func createFollowNotification(followedUserId: UUID) async {
        guard let currentUser = supabase.currentUser else { return }
        guard followedUserId != currentUser.id else { return }

        await createNotification(
            userId: followedUserId,
            type: .newFollower,
            message: "\(currentUser.displayName) started following you",
            actorId: currentUser.id
        )
    }

    /// Create a notification for a ralley join
    func createRalleyJoinNotification(ralleyId: UUID, hostId: UUID, ralleyTitle: String) async {
        guard let currentUser = supabase.currentUser else { return }
        guard hostId != currentUser.id else { return }

        await createNotification(
            userId: hostId,
            type: .ralleyJoin,
            message: "\(currentUser.displayName) joined your ralley",
            actorId: currentUser.id,
            ralleyId: ralleyId
        )
    }

    /// Create a notification for a ralley invitation
    func createRalleyInviteNotification(userId: UUID, ralleyId: UUID, ralleyTitle: String) async {
        guard let currentUser = supabase.currentUser else { return }

        await createNotification(
            userId: userId,
            type: .ralleyInvite,
            message: "\(currentUser.displayName) invited you to a ralley",
            actorId: currentUser.id,
            ralleyId: ralleyId
        )
    }

    // MARK: - Private Methods

    private func createNotification(
        userId: UUID,
        type: NotificationType,
        message: String,
        actorId: UUID? = nil,
        postId: UUID? = nil,
        ralleyId: UUID? = nil
    ) async {
        let insert = NotificationInsert(
            user_id: userId,
            type: type.rawValue,
            actor_id: actorId,
            message: message,
            post_id: postId,
            ralley_id: ralleyId
        )

        do {
            try await supabase.insert(insert, into: "notifications")
            print("InAppNotificationService: Created \(type.rawValue) notification for user \(userId)")
        } catch {
            print("InAppNotificationService: Failed to create notification: \(error)")
        }
    }

    private func handleNewNotification(_ payload: NotificationPayload) {
        let notification = AppNotification(
            id: payload.id,
            type: NotificationType(rawValue: payload.type) ?? .general,
            actorId: payload.actorId,
            actorName: nil,
            actorPhotoURL: nil,
            actorUsername: nil,
            postId: payload.postId,
            ralleyId: payload.ralleyId,
            message: payload.message,
            isRead: payload.isRead,
            createdAt: payload.createdAt
        )

        // Insert at beginning (newest first)
        notifications.insert(notification, at: 0)
        if !notification.isRead {
            unreadCount += 1
        }

        print("InAppNotificationService: Received new notification: \(notification.message)")
    }
}

// MARK: - Helper Structs

struct NotificationReadUpdate: Encodable {
    let is_read: Bool
}

struct NotificationInsert: Codable {
    let user_id: UUID
    let type: String
    let actor_id: UUID?
    let message: String
    let post_id: UUID?
    let ralley_id: UUID?
}
