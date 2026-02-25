//
//  ChatsListViewModel.swift
//  Club Ralley
//
//  ViewModel for managing the list of user's group chats.
//

import Foundation
import SwiftUI

/**
 * ChatsListViewModel: ViewModel for chats list display
 *
 * Purpose: Manages loading and display of user's group chats
 * Strategy: Uses ChatService for backend operations, realtime for live unread updates
 */
@MainActor
class ChatsListViewModel: ObservableObject {

    // MARK: - Published Properties

    /// All chats for current user
    @Published var chats: [GroupChat] = []

    /// Loading state for UI
    @Published var isLoading = false

    /// Error state
    @Published var error: Error?

    /// Whether more chats are available for pagination
    @Published var hasMoreChats = true

    /// Whether currently loading more chats
    @Published var isLoadingMore = false

    /// Page size for pagination
    private let pageSize = 50

    // MARK: - Dependencies

    private let chatService: ChatService
    private let realtimeManager = RealtimeManager.shared

    /// Track which chat is currently open so we don't mark it unread
    var currentlyOpenChatId: UUID?

    // MARK: - Initialization

    init(chatService: ChatService? = nil) {
        self.chatService = chatService ?? ServiceContainer.shared.chatService
        Task {
            await loadChats()
        }
        subscribeToRealtime()
    }

    deinit {
        Task { [realtimeManager] in
            await realtimeManager.unsubscribeFromAllChatMessages()
        }
    }

    // MARK: - Realtime

    /// Subscribe to all chat_messages inserts for live unread updates
    private func subscribeToRealtime() {
        let currentUserId = SupabaseManager.shared.currentUser?.id

        realtimeManager.subscribeToAllChatMessages { [weak self] payload in
            guard let self = self else { return }

            // Ignore messages sent by the current user
            if let currentUserId, payload.senderId == currentUserId {
                return
            }

            // Find matching chat in the list
            if let index = self.chats.firstIndex(where: { $0.ralleyId == payload.ralleyId }) {
                // Update last message preview
                self.chats[index].lastMessage = payload.content
                self.chats[index].lastMessageAt = payload.createdAt

                // Mark as unread unless this chat is currently open
                if self.currentlyOpenChatId != payload.ralleyId {
                    self.chats[index].hasUnread = true
                }

                // Re-sort so most recent is on top
                self.chats.sort { ($0.lastMessageAt ?? $0.createdAt) > ($1.lastMessageAt ?? $1.createdAt) }
            }
        }
    }

    // MARK: - Reset (for user switch / sign out)

    /// Clear all cached data and tear down subscriptions
    func reset() {
        chats = []
        isLoading = false
        isLoadingMore = false
        hasMoreChats = true
        error = nil
        currentlyOpenChatId = nil
        Task {
            await realtimeManager.unsubscribeFromAllChatMessages()
        }
    }

    /// Re-subscribe to realtime and reload for the new user
    func reinitialize() {
        subscribeToRealtime()
        Task {
            await loadChats()
        }
    }

    // MARK: - Loading

    /// Load all chats for current user
    func loadChats() async {
        isLoading = true
        error = nil

        do {
            chats = try await chatService.loadUserChats()
        } catch {
            self.error = error
            print("ChatsListViewModel: Failed to load chats: \(error)")
        }

        isLoading = false
    }

    /// Refresh chats
    func refresh() async {
        hasMoreChats = true
        await loadChats()
    }

    /// Load more chats for infinite scroll
    func loadMoreChats() async {
        guard !isLoadingMore && hasMoreChats else { return }

        isLoadingMore = true

        do {
            let moreChats = try await chatService.loadUserChats(limit: pageSize, offset: chats.count)

            if moreChats.isEmpty {
                hasMoreChats = false
            } else {
                chats.append(contentsOf: moreChats)
                if moreChats.count < pageSize {
                    hasMoreChats = false
                }
            }
        } catch {
            print("ChatsListViewModel: Failed to load more chats: \(error)")
        }

        isLoadingMore = false
    }

    // MARK: - Unread Management

    /// Mark a specific chat as read (updates both local state and service)
    func markChatAsRead(chatId: UUID) {
        if let index = chats.firstIndex(where: { $0.id == chatId }) {
            chats[index].hasUnread = false
        }
        chatService.markChatAsRead(chatId: chatId)
    }

    // MARK: - Computed Properties

    /// Chats with unread messages
    var unreadChats: [GroupChat] {
        chats.filter { $0.hasUnread }
    }

    /// Count of unread chats
    var unreadCount: Int {
        unreadChats.count
    }

    /// Whether there are any chats
    var hasChats: Bool {
        !chats.isEmpty
    }
}
