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
 * Strategy: Uses ChatService for backend operations
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

    // MARK: - Initialization

    init(chatService: ChatService? = nil) {
        self.chatService = chatService ?? ServiceContainer.shared.chatService
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
