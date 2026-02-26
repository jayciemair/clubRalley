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
    private var allChatMessagesChannel: RealtimeChannelV2?
    private var notificationChannel: RealtimeChannelV2?
    private var participantChannel: RealtimeChannelV2?
    private var feedParticipantChannel: RealtimeChannelV2?

    // MARK: - Published State

    @Published var isConnected = false
    @Published var connectionError: String?

    // MARK: - Callbacks

    private var onDirectMessage: ((DirectMessagePayload) -> Void)?
    private var onChatMessage: ((ChatMessagePayload) -> Void)?
    private var onAllChatMessages: ((ChatMessagePayload) -> Void)?
    private var onNotification: ((NotificationPayload) -> Void)?
    private var onParticipantChange: ((ParticipantChangePayload) -> Void)?
    private var onFeedParticipantChange: ((ParticipantChangePayload) -> Void)?

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

    // MARK: - All Chat Messages Subscription (for chat list unread tracking)

    /// Subscribe to all chat_messages inserts (no filter — used by ChatsListViewModel)
    func subscribeToAllChatMessages(
        onMessage: @escaping (ChatMessagePayload) -> Void
    ) {
        guard let client = client else {
            print("RealtimeManager: No Supabase client available")
            return
        }

        Task {
            await unsubscribeFromAllChatMessages()
        }

        self.onAllChatMessages = onMessage

        let channel = client.channel("all_chat_messages")

        let insertions = channel.postgresChange(
            InsertAction.self,
            schema: "public",
            table: "chat_messages"
        )

        Task {
            for await insertion in insertions {
                if let record = insertion.record as? [String: Any],
                   let payload = ChatMessagePayload(from: record) {
                    await MainActor.run {
                        self.onAllChatMessages?(payload)
                    }
                }
            }
        }

        Task {
            await channel.subscribe()
            await MainActor.run {
                self.allChatMessagesChannel = channel
                print("RealtimeManager: Subscribed to all chat messages")
            }
        }
    }

    /// Unsubscribe from all chat messages
    func unsubscribeFromAllChatMessages() async {
        if let channel = allChatMessagesChannel {
            await channel.unsubscribe()
            allChatMessagesChannel = nil
            print("RealtimeManager: Unsubscribed from all chat messages")
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

    // MARK: - Feed Participant Subscriptions (All Ralleys)

    /// Subscribe to participant changes across ALL ralleys (for feed count sync)
    func subscribeToAllParticipantChanges(
        onChange: @escaping (ParticipantChangePayload) -> Void
    ) {
        guard let client = client else {
            print("RealtimeManager: No Supabase client available")
            return
        }

        // Unsubscribe from existing feed channel
        Task {
            await unsubscribeFromAllParticipantChanges()
        }

        self.onFeedParticipantChange = onChange

        // Create channel for all participant changes (no filter)
        let channel = client.channel("feed_participants")

        // Listen for inserts (new participants)
        let insertions = channel.postgresChange(
            InsertAction.self,
            schema: "public",
            table: "ralley_participants"
        )

        // Listen for updates (status changes, e.g. pending → joined)
        let updates = channel.postgresChange(
            UpdateAction.self,
            schema: "public",
            table: "ralley_participants"
        )

        // Listen for deletes (participant left)
        let deletions = channel.postgresChange(
            DeleteAction.self,
            schema: "public",
            table: "ralley_participants"
        )

        Task {
            for await insertion in insertions {
                await MainActor.run {
                    self.onFeedParticipantChange?(ParticipantChangePayload(type: .joined, record: insertion.record as? [String: Any]))
                }
            }
        }

        Task {
            for await update in updates {
                await MainActor.run {
                    self.onFeedParticipantChange?(ParticipantChangePayload(type: .updated, record: update.record as? [String: Any]))
                }
            }
        }

        Task {
            for await deletion in deletions {
                await MainActor.run {
                    self.onFeedParticipantChange?(ParticipantChangePayload(type: .left, record: deletion.oldRecord as? [String: Any]))
                }
            }
        }

        // Subscribe to the channel
        Task {
            await channel.subscribe()
            await MainActor.run {
                self.feedParticipantChannel = channel
                print("RealtimeManager: Subscribed to all participant changes (feed sync)")
            }
        }
    }

    /// Unsubscribe from feed-level participant changes
    func unsubscribeFromAllParticipantChanges() async {
        if let channel = feedParticipantChannel {
            await channel.unsubscribe()
            feedParticipantChannel = nil
            print("RealtimeManager: Unsubscribed from feed participant changes")
        }
    }

    // MARK: - Cleanup

    /// Unsubscribe from all channels and clear callbacks
    func unsubscribeAll() async {
        await unsubscribeFromDirectMessages()
        await unsubscribeFromChatMessages()
        await unsubscribeFromAllChatMessages()
        await unsubscribeFromNotifications()
        await unsubscribeFromParticipants()
        await unsubscribeFromAllParticipantChanges()

        // Clear all callbacks to prevent stale closures firing
        onDirectMessage = nil
        onChatMessage = nil
        onAllChatMessages = nil
        onNotification = nil
        onParticipantChange = nil
        onFeedParticipantChange = nil

        isConnected = false
        print("RealtimeManager: Unsubscribed from all channels and cleared callbacks")
    }
}
