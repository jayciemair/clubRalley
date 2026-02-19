//
//  SharedUserState.swift
//  Club Ralley
//
//  Single source of truth for blocked user IDs.
//  Replaces the separate caches in RalleyService, PostService, and FriendshipService.
//

import Foundation
import SwiftUI

@MainActor
class SharedUserState: ObservableObject {

    // MARK: - Published Properties

    @Published private(set) var blockedUserIds: Set<UUID> = []

    // MARK: - Dependencies

    private let friendshipService: FriendshipService

    // MARK: - Cache State

    private var lastRefresh: Date?
    private let refreshInterval: TimeInterval = 300 // 5 minutes

    // MARK: - Initialization

    init(friendshipService: FriendshipService) {
        self.friendshipService = friendshipService
    }

    // MARK: - Public API

    /// Check if a user ID is blocked
    func isBlocked(_ userId: UUID) -> Bool {
        blockedUserIds.contains(userId)
    }

    /// Refresh blocked users if cache is stale (older than 5 minutes)
    func refreshBlockedUsersIfNeeded() async {
        if let lastRefresh = lastRefresh,
           Date().timeIntervalSince(lastRefresh) < refreshInterval {
            return
        }

        do {
            blockedUserIds = try await friendshipService.getBlockedUserIds()
            lastRefresh = Date()
        } catch {
            print("SharedUserState: Failed to refresh blocked users: \(error)")
        }
    }

    /// Force refresh blocked users cache
    func forceRefresh() async {
        lastRefresh = nil
        await refreshBlockedUsersIfNeeded()
    }
}
