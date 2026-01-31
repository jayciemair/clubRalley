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

    // MARK: - Chat Info

    /// The chat being displayed
    let chat: GroupChat

    // MARK: - Dependencies

    private let chatService = ChatService()

    // MARK: - Initialization

    init(chat: GroupChat) {
        self.chat = chat
        Task {
            await loadMessages()
            await loadMembers()
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
