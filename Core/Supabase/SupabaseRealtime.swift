//
//  SupabaseRealtime.swift
//  Club Ralley
//
//  Realtime subscriptions for live updates
//  Handles direct messages, chat messages, and notifications
//

import Foundation
import Supabase

// MARK: - Realtime Subscription Manager

@MainActor
class RealtimeManager: ObservableObject {

    // MARK: - Singleton

    static let shared = RealtimeManager()

    // MARK: - Dependencies

    private var client: SupabaseClient? {
        SupabaseClientManager.shared.client
    }

    // MARK: - Active Channels

    private var directMessageChannel: RealtimeChannelV2?
    private var chatMessageChannel: RealtimeChannelV2?
    private var notificationChannel: RealtimeChannelV2?
    private var participantChannel: RealtimeChannelV2?

    // MARK: - Published State

    @Published var isConnected = false
    @Published var connectionError: String?

    // MARK: - Callbacks

    private var onDirectMessage: ((DirectMessagePayload) -> Void)?
    private var onChatMessage: ((ChatMessagePayload) -> Void)?
    private var onNotification: ((NotificationPayload) -> Void)?
    private var onParticipantChange: ((ParticipantChangePayload) -> Void)?

    // MARK: - Initialization

    private init() {}

    // MARK: - Direct Message Subscriptions

    /// Subscribe to direct messages for the current user
    func subscribeToDirectMessages(
        userId: UUID,
        onMessage: @escaping (DirectMessagePayload) -> Void
    ) {
        guard let client = client else {
            print("RealtimeManager: No Supabase client available")
            return
        }

        // Unsubscribe from existing channel
        Task {
            await unsubscribeFromDirectMessages()
        }

        self.onDirectMessage = onMessage

        // Create channel for direct messages where user is the recipient
        let channel = client.channel("direct_messages:\(userId.uuidString)")

        // Listen for new messages
        let insertions = channel.postgresChange(
            InsertAction.self,
            schema: "public",
            table: "direct_messages",
            filter: "recipient_id=eq.\(userId.uuidString)"
        )

        Task {
            for await insertion in insertions {
                if let record = insertion.record as? [String: Any],
                   let payload = DirectMessagePayload(from: record) {
                    await MainActor.run {
                        self.onDirectMessage?(payload)
                    }
                }
            }
        }

        // Subscribe to the channel
        Task {
            await channel.subscribe()
            await MainActor.run {
                self.directMessageChannel = channel
                self.isConnected = true
                print("RealtimeManager: Subscribed to direct messages for user \(userId)")
            }
        }
    }

    /// Unsubscribe from direct messages
    func unsubscribeFromDirectMessages() async {
        if let channel = directMessageChannel {
            await channel.unsubscribe()
            directMessageChannel = nil
            print("RealtimeManager: Unsubscribed from direct messages")
        }
    }

    // MARK: - Chat Message Subscriptions

    /// Subscribe to chat messages for a specific ralley
    func subscribeToChatMessages(
        ralleyId: UUID,
        onMessage: @escaping (ChatMessagePayload) -> Void
    ) {
        guard let client = client else {
            print("RealtimeManager: No Supabase client available")
            return
        }

        // Unsubscribe from existing channel
        Task {
            await unsubscribeFromChatMessages()
        }

        self.onChatMessage = onMessage

        // Create channel for chat messages
        let channel = client.channel("chat_messages:\(ralleyId.uuidString)")

        // Listen for new messages
        let insertions = channel.postgresChange(
            InsertAction.self,
            schema: "public",
            table: "chat_messages",
            filter: "ralley_id=eq.\(ralleyId.uuidString)"
        )

        Task {
            for await insertion in insertions {
                if let record = insertion.record as? [String: Any],
                   let payload = ChatMessagePayload(from: record) {
                    await MainActor.run {
                        self.onChatMessage?(payload)
                    }
                }
            }
        }

        // Subscribe to the channel
        Task {
            await channel.subscribe()
            await MainActor.run {
                self.chatMessageChannel = channel
                print("RealtimeManager: Subscribed to chat messages for ralley \(ralleyId)")
            }
        }
    }

    /// Unsubscribe from chat messages
    func unsubscribeFromChatMessages() async {
        if let channel = chatMessageChannel {
            await channel.unsubscribe()
            chatMessageChannel = nil
            print("RealtimeManager: Unsubscribed from chat messages")
        }
    }

    // MARK: - Notification Subscriptions

    /// Subscribe to notifications for the current user
    func subscribeToNotifications(
        userId: UUID,
        onNotification: @escaping (NotificationPayload) -> Void
    ) {
        guard let client = client else {
            print("RealtimeManager: No Supabase client available")
            return
        }

        // Unsubscribe from existing channel
        Task {
            await unsubscribeFromNotifications()
        }

        self.onNotification = onNotification

        // Create channel for notifications
        let channel = client.channel("notifications:\(userId.uuidString)")

        // Listen for new notifications
        let insertions = channel.postgresChange(
            InsertAction.self,
            schema: "public",
            table: "notifications",
            filter: "user_id=eq.\(userId.uuidString)"
        )

        Task {
            for await insertion in insertions {
                if let record = insertion.record as? [String: Any],
                   let payload = NotificationPayload(from: record) {
                    await MainActor.run {
                        self.onNotification?(payload)
                    }
                }
            }
        }

        // Subscribe to the channel
        Task {
            await channel.subscribe()
            await MainActor.run {
                self.notificationChannel = channel
                print("RealtimeManager: Subscribed to notifications for user \(userId)")
            }
        }
    }

    /// Unsubscribe from notifications
    func unsubscribeFromNotifications() async {
        if let channel = notificationChannel {
            await channel.unsubscribe()
            notificationChannel = nil
            print("RealtimeManager: Unsubscribed from notifications")
        }
    }

    // MARK: - Participant Subscriptions

    /// Subscribe to participant changes for a specific ralley
    func subscribeToParticipants(
        ralleyId: UUID,
        onChange: @escaping (ParticipantChangePayload) -> Void
    ) {
        guard let client = client else {
            print("RealtimeManager: No Supabase client available")
            return
        }

        // Unsubscribe from existing channel
        Task {
            await unsubscribeFromParticipants()
        }

        self.onParticipantChange = onChange

        // Create channel for participant changes
        let channel = client.channel("participants:\(ralleyId.uuidString)")

        // Listen for inserts (new participants)
        let insertions = channel.postgresChange(
            InsertAction.self,
            schema: "public",
            table: "ralley_participants",
            filter: "ralley_id=eq.\(ralleyId.uuidString)"
        )

        // Listen for updates (status changes)
        let updates = channel.postgresChange(
            UpdateAction.self,
            schema: "public",
            table: "ralley_participants",
            filter: "ralley_id=eq.\(ralleyId.uuidString)"
        )

        // Listen for deletes (participant left)
        let deletions = channel.postgresChange(
            DeleteAction.self,
            schema: "public",
            table: "ralley_participants",
            filter: "ralley_id=eq.\(ralleyId.uuidString)"
        )

        Task {
            for await insertion in insertions {
                await MainActor.run {
                    self.onParticipantChange?(ParticipantChangePayload(type: .joined, record: insertion.record as? [String: Any]))
                }
            }
        }

        Task {
            for await update in updates {
                await MainActor.run {
                    self.onParticipantChange?(ParticipantChangePayload(type: .updated, record: update.record as? [String: Any]))
                }
            }
        }

        Task {
            for await deletion in deletions {
                await MainActor.run {
                    self.onParticipantChange?(ParticipantChangePayload(type: .left, record: deletion.oldRecord as? [String: Any]))
                }
            }
        }

        // Subscribe to the channel
        Task {
            await channel.subscribe()
            await MainActor.run {
                self.participantChannel = channel
                print("RealtimeManager: Subscribed to participant changes for ralley \(ralleyId)")
            }
        }
    }

    /// Unsubscribe from participant changes
    func unsubscribeFromParticipants() async {
        if let channel = participantChannel {
            await channel.unsubscribe()
            participantChannel = nil
            print("RealtimeManager: Unsubscribed from participant changes")
        }
    }

    // MARK: - Cleanup

    /// Unsubscribe from all channels
    func unsubscribeAll() async {
        await unsubscribeFromDirectMessages()
        await unsubscribeFromChatMessages()
        await unsubscribeFromNotifications()
        await unsubscribeFromParticipants()
        isConnected = false
        print("RealtimeManager: Unsubscribed from all channels")
    }
}

// MARK: - Payload Types

/// Payload for direct message events
struct DirectMessagePayload {
    let id: UUID
    let senderId: UUID
    let recipientId: UUID
    let content: String
    let isRead: Bool
    let createdAt: Date

    init?(from record: [String: Any]) {
        guard let idString = record["id"] as? String,
              let id = UUID(uuidString: idString),
              let senderIdString = record["sender_id"] as? String,
              let senderId = UUID(uuidString: senderIdString),
              let recipientIdString = record["recipient_id"] as? String,
              let recipientId = UUID(uuidString: recipientIdString),
              let content = record["content"] as? String else {
            return nil
        }

        self.id = id
        self.senderId = senderId
        self.recipientId = recipientId
        self.content = content
        self.isRead = record["is_read"] as? Bool ?? false

        if let createdAtString = record["created_at"] as? String {
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            self.createdAt = formatter.date(from: createdAtString) ?? Date()
        } else {
            self.createdAt = Date()
        }
    }
}

/// Payload for chat message events
struct ChatMessagePayload {
    let id: UUID
    let ralleyId: UUID
    let senderId: UUID
    let content: String
    let messageType: String
    let createdAt: Date

    init?(from record: [String: Any]) {
        guard let idString = record["id"] as? String,
              let id = UUID(uuidString: idString),
              let ralleyIdString = record["ralley_id"] as? String,
              let ralleyId = UUID(uuidString: ralleyIdString),
              let senderIdString = record["sender_id"] as? String,
              let senderId = UUID(uuidString: senderIdString),
              let content = record["content"] as? String else {
            return nil
        }

        self.id = id
        self.ralleyId = ralleyId
        self.senderId = senderId
        self.content = content
        self.messageType = record["message_type"] as? String ?? "text"

        if let createdAtString = record["created_at"] as? String {
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            self.createdAt = formatter.date(from: createdAtString) ?? Date()
        } else {
            self.createdAt = Date()
        }
    }
}

/// Payload for notification events
struct NotificationPayload {
    let id: UUID
    let userId: UUID
    let type: String
    let message: String
    let actorId: UUID?
    let postId: UUID?
    let ralleyId: UUID?
    let isRead: Bool
    let createdAt: Date

    init?(from record: [String: Any]) {
        guard let idString = record["id"] as? String,
              let id = UUID(uuidString: idString),
              let userIdString = record["user_id"] as? String,
              let userId = UUID(uuidString: userIdString),
              let type = record["type"] as? String,
              let message = record["message"] as? String else {
            return nil
        }

        self.id = id
        self.userId = userId
        self.type = type
        self.message = message
        self.isRead = record["is_read"] as? Bool ?? false

        if let actorIdString = record["actor_id"] as? String {
            self.actorId = UUID(uuidString: actorIdString)
        } else {
            self.actorId = nil
        }

        if let postIdString = record["post_id"] as? String {
            self.postId = UUID(uuidString: postIdString)
        } else {
            self.postId = nil
        }

        if let ralleyIdString = record["ralley_id"] as? String {
            self.ralleyId = UUID(uuidString: ralleyIdString)
        } else {
            self.ralleyId = nil
        }

        if let createdAtString = record["created_at"] as? String {
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            self.createdAt = formatter.date(from: createdAtString) ?? Date()
        } else {
            self.createdAt = Date()
        }
    }
}

/// Payload for participant change events
struct ParticipantChangePayload {
    enum ChangeType {
        case joined
        case updated
        case left
    }

    let type: ChangeType
    let userId: UUID?
    let ralleyId: UUID?
    let status: String?

    init(type: ChangeType, record: [String: Any]?) {
        self.type = type

        if let record = record {
            if let userIdString = record["user_id"] as? String {
                self.userId = UUID(uuidString: userIdString)
            } else {
                self.userId = nil
            }

            if let ralleyIdString = record["ralley_id"] as? String {
                self.ralleyId = UUID(uuidString: ralleyIdString)
            } else {
                self.ralleyId = nil
            }

            self.status = record["status"] as? String
        } else {
            self.userId = nil
            self.ralleyId = nil
            self.status = nil
        }
    }
}
