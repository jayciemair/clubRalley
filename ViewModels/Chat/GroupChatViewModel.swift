//
//  GroupChatViewModel.swift
//  Club Ralley
//
//  ViewModel for managing a single group chat's state and operations.
//

import Foundation
import SwiftUI

/**
 * GroupChatViewModel: ViewModel for group chat messaging
 *
 * Purpose: Manages messages, sending, and member info for a single chat
 * Strategy: Uses ChatService for backend operations, maintains local cache
 */
@MainActor
class GroupChatViewModel: ObservableObject {

    // MARK: - Published Properties

    /// Messages in the chat (chronological order)
    @Published var messages: [GroupChatMessage] = []

    /// Members of the chat
    @Published var members: [GroupChatMember] = []

    /// Loading state for UI
    @Published var isLoading = false

    /// Sending state for message input
    @Published var isSending = false

    /// Error state
    @Published var error: Error?

    /// Message input text
    @Published var messageText = ""

    /// Realtime connection status
    @Published var isRealtimeConnected = false

    // MARK: - Chat Info

    /// The chat being displayed
    let chat: GroupChat

    // MARK: - Dependencies

    private let chatService = ChatService()
    private let realtimeManager = RealtimeManager.shared
    private let supabaseManager = SupabaseManager.shared

    // MARK: - Initialization

    init(chat: GroupChat) {
        self.chat = chat
        Task {
            await loadMessages()
            await loadMembers()
            subscribeToRealtime()
        }
    }

    deinit {
        // Unsubscribe when view model is deallocated
        Task { @MainActor in
            await realtimeManager.unsubscribeFromChatMessages()
        }
    }

    // MARK: - Message Loading

    /// Load messages for this chat
    func loadMessages() async {
        isLoading = true
        error = nil

        do {
            let loadedMessages = try await chatService.loadMessages(chatId: chat.id)
            messages = loadedMessages
            // Mark as read when loading
            try? await chatService.markAsRead(chatId: chat.id)
        } catch {
            self.error = error
            print("GroupChatViewModel: Failed to load messages: \(error)")
        }

        isLoading = false
    }

    /// Load more messages (pagination)
    func loadMoreMessages() async {
        guard let oldestMessage = messages.first else { return }

        do {
            let olderMessages = try await chatService.loadMessages(
                chatId: chat.id,
                limit: 50,
                before: oldestMessage.createdAt
            )
            messages.insert(contentsOf: olderMessages, at: 0)
        } catch {
            print("GroupChatViewModel: Failed to load more messages: \(error)")
        }
    }

    // MARK: - Sending Messages

    /// Send a message
    func sendMessage() async {
        let content = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !content.isEmpty else { return }

        isSending = true
        messageText = "" // Clear immediately for UX

        do {
            let sentMessage = try await chatService.sendMessage(chatId: chat.id, content: content)
            messages.append(sentMessage)
        } catch {
            self.error = error
            messageText = content // Restore on failure
            print("GroupChatViewModel: Failed to send message: \(error)")
        }

        isSending = false
    }

    // MARK: - Member Management

    /// Load chat members
    func loadMembers() async {
        do {
            members = try await chatService.loadMembers(chatId: chat.id)
        } catch {
            print("GroupChatViewModel: Failed to load members: \(error)")
        }
    }

    /// Remove a member (admin only)
    func removeMember(_ userId: UUID) async {
        guard chat.isAdmin else { return }

        do {
            try await chatService.removeMember(chatId: chat.id, userId: userId)
            members.removeAll { $0.id == userId }
        } catch {
            print("GroupChatViewModel: Failed to remove member: \(error)")
        }
    }

    // MARK: - Realtime Subscription

    /// Subscribe to realtime chat messages
    private func subscribeToRealtime() {
        guard let ralleyId = chat.ralleyId else { return }

        realtimeManager.subscribeToChatMessages(ralleyId: ralleyId) { [weak self] payload in
            Task { @MainActor in
                self?.handleNewMessage(payload)
            }
        }

        isRealtimeConnected = true
        print("✅ GroupChatViewModel: Subscribed to realtime for chat \(chat.id)")
    }

    /// Handle incoming realtime message
    private func handleNewMessage(_ payload: ChatMessagePayload) {
        // Don't add if it's our own message (already added when sent)
        guard payload.senderId != supabaseManager.currentUser?.id else { return }

        // Check if message already exists
        guard !messages.contains(where: { $0.id == payload.id }) else { return }

        // Find sender info from members
        let member = members.first(where: { $0.id == payload.senderId })
        let messageType = ChatMessageType(rawValue: payload.messageType) ?? .text

        // Create GroupChatMessage from payload
        let newMessage = GroupChatMessage(
            id: payload.id,
            chatId: chat.id,
            senderId: payload.senderId,
            senderName: member?.name ?? "Unknown",
            senderUsername: member?.username ?? "unknown",
            senderPhotoURL: member?.photoURL,
            content: payload.content,
            messageType: messageType,
            createdAt: payload.createdAt,
            isFromCurrentUser: false
        )

        messages.append(newMessage)
        print("✅ GroupChatViewModel: Received realtime message from \(payload.senderId)")
    }

    /// Unsubscribe from realtime
    func unsubscribeFromRealtime() async {
        await realtimeManager.unsubscribeFromChatMessages()
        isRealtimeConnected = false
    }

    // MARK: - Helpers

    /// Check if can send (not empty and not sending)
    var canSend: Bool {
        !messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isSending
    }

    /// Clear error
    func clearError() {
        error = nil
    }
}
