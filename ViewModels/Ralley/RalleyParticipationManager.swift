//
//  RalleyParticipationManager.swift
//  Club Ralley
//
//  ViewModel for managing ralley participation: joining, leaving, and requests.
//  Handles auto-creation of group chat when max players is reached.
//

import Foundation
import SwiftUI

/**
 * RalleyParticipationManager: ViewModel for participation operations
 *
 * Purpose: Manages join/leave operations and join request management
 * Strategy: Uses RalleyParticipationService for database operations
 * Features:
 *   - Join (instant) for open ralleys
 *   - Request to join for approval-required ralleys
 *   - Auto-create group chat when max players reached
 *   - Captain approval workflow
 */
@MainActor
class RalleyParticipationManager: ObservableObject {

    // MARK: - Published Properties

    /// Error state
    @Published var error: Error?

    /// Loading state
    @Published var isLoading = false

    /// Success message for user feedback
    @Published var successMessage: String?

    // MARK: - Dependencies

    /// Service layer for participation operations
    private let participationService: RalleyParticipationService

    /// Chat service for creating and managing group chats
    private let chatService: ChatService

    /// Reference to parent RalleyManager
    private weak var ralleyManager: RalleyManager?

    /// Supabase manager for user info
    private let supabase = SupabaseManager.shared

    // MARK: - Initialization

    init(ralleyManager: RalleyManager, participationService: RalleyParticipationService? = nil, chatService: ChatService? = nil) {
        let container = ServiceContainer.shared
        self.ralleyManager = ralleyManager
        self.participationService = participationService ?? container.ralleyParticipationService
        self.chatService = chatService ?? container.chatService
    }

    // MARK: - Join/Leave Operations

    /**
     * Join a ralley (add current user as participant)
     * If this causes the ralley to reach max players, auto-creates the group chat
     */
    func joinRalley(_ ralleyId: UUID) async {
        guard let ralleyManager = ralleyManager,
              let index = ralleyManager.indexOfRalley(ralleyId) else { return }

        let ralley = ralleyManager.ralleys[index]

        // Check college athletes only restriction
        if ralley.isCollegeAthletesOnly {
            let isFormerAthlete = SavedUserProfile.loadFromStorage()?.playedCollegeSport == true
            guard isFormerAthlete else {
                self.error = NSError(domain: "RalleyParticipation", code: 3, userInfo: [NSLocalizedDescriptionKey: "This ralley is for former college athletes only"])
                return
            }
        }

        // Check if ralley is full
        guard ralley.currentPlayers < ralley.maxPlayers else {
            print("RalleyParticipationManager: Ralley is already full")
            self.error = NSError(domain: "RalleyParticipation", code: 1, userInfo: [NSLocalizedDescriptionKey: "This Ralley is full"])
            return
        }

        // Check if approval is required
        guard ralley.joinType == .open else {
            print("RalleyParticipationManager: Ralley requires approval, use requestToJoin instead")
            await requestToJoin(ralleyId)
            return
        }

        isLoading = true

        // Optimistic UI update
        let originalPlayers = ralleyManager.ralleys[index].currentPlayers
        ralleyManager.ralleys[index].currentPlayers += 1

        print("RalleyParticipationManager: Optimistic join update for ralley")

        // Attempt to sync with database
        do {
            let success = try await participationService.joinRalley(ralleyId: ralleyId)

            if success {
                print("RalleyParticipationManager: Join synced with database")

                // Track joined ralley locally
                ralleyManager.markRalleyAsJoined(ralleyId)

                // Always add joiner to the ralley chat (ralleyId is the chatId)
                if let currentUser = supabase.currentUser {
                    try? await chatService.addMember(chatId: ralleyId, userId: currentUser.id)
                }

                // Auto-post to feed
                if let postManager = ralleyManager.postManager {
                    let postContent = "Just joined a \(ralley.sport) ralley — \(ralley.title)! \u{1F64C}"
                    await postManager.createPost(
                        content: postContent,
                        postType: .ralleyUpdate,
                        authorSport: ralley.sport,
                        relatedRalleyId: ralleyId
                    )
                }

                successMessage = "You've joined the Ralley!"
            } else {
                // Revert optimistic update on failure
                ralleyManager.ralleys[index].currentPlayers = originalPlayers
            }

        } catch {
            print("RalleyParticipationManager: Failed to sync join with database: \(error)")

            // Revert optimistic update on failure
            ralleyManager.ralleys[index].currentPlayers = originalPlayers
            self.error = error
        }

        isLoading = false
    }

    /**
     * Leave a ralley
     */
    func leaveRalley(_ ralleyId: UUID) async {
        guard let ralleyManager = ralleyManager,
              let index = ralleyManager.indexOfRalley(ralleyId) else { return }

        isLoading = true

        // Optimistic UI update
        let originalPlayers = ralleyManager.ralleys[index].currentPlayers
        ralleyManager.ralleys[index].currentPlayers = max(0, ralleyManager.ralleys[index].currentPlayers - 1)

        do {
            let success = try await participationService.leaveRalley(ralleyId: ralleyId)

            if success {
                // Track left ralley locally
                ralleyManager.markRalleyAsLeft(ralleyId)

                // Remove from chat if exists
                if let chatId = ralleyManager.ralleys[index].chatId,
                   let currentUser = supabase.currentUser {
                    try? await chatService.removeMember(chatId: chatId, userId: currentUser.id)
                }
                successMessage = "You've left the Ralley"
            } else {
                ralleyManager.ralleys[index].currentPlayers = originalPlayers
            }

        } catch {
            print("RalleyParticipationManager: Failed to leave ralley: \(error)")
            ralleyManager.ralleys[index].currentPlayers = originalPlayers
            self.error = error
        }

        isLoading = false
    }

    // MARK: - Auto Group Chat Creation

    /**
     * Create group chat when ralley reaches max players
     * Adds all current attendees + captain to the chat
     */
    private func createGroupChatWhenFull(for ralleyId: UUID, at index: Int) async {
        guard let ralleyManager = ralleyManager else { return }

        let ralley = ralleyManager.ralleys[index]

        // Don't create if chat already exists
        guard ralley.chatId == nil else {
            print("RalleyParticipationManager: Chat already exists for ralley")
            return
        }

        print("RalleyParticipationManager: Ralley is full! Creating group chat...")

        do {
            // Get captain ID (organizer)
            let captainId = ralley.organizer.id

            // Create the group chat
            let chatId = try await chatService.createRalleyChat(ralleyId: ralleyId, captainId: captainId)

            // Update local state with chat ID
            ralleyManager.ralleys[index].chatId = chatId

            // Get all attendees
            let attendees = try await participationService.getAttendees(ralleyId: ralleyId)

            // Add all attendees to the chat (captain already added by createRalleyChat)
            for attendee in attendees where attendee.id != captainId {
                try? await chatService.addMember(chatId: chatId, userId: attendee.id)
            }

            // Send system message
            if let currentUser = supabase.currentUser {
                let _ = GroupChatMessage(
                    id: UUID(),
                    chatId: chatId,
                    senderId: currentUser.id,
                    senderName: "System",
                    senderUsername: "system",
                    senderPhotoURL: nil,
                    content: "The Ralley is full! Let's coordinate logistics here.",
                    messageType: .system,
                    createdAt: Date(),
                    isFromCurrentUser: false
                )
                // Note: In a real implementation, this would be sent through ChatService
            }

            print("RalleyParticipationManager: Group chat created with \(attendees.count) members")

        } catch {
            print("RalleyParticipationManager: Failed to create group chat: \(error)")
        }
    }

    // MARK: - Join Request Operations

    /**
     * Request to join a private ralley (requires captain approval)
     */
    func requestToJoin(_ ralleyId: UUID) async {
        isLoading = true

        do {
            let success = try await participationService.requestToJoin(ralleyId: ralleyId)
            if success {
                successMessage = "Request sent! Waiting for captain approval."
                print("RalleyParticipationManager: Join request submitted")
            }
        } catch {
            print("RalleyParticipationManager: Failed to submit join request: \(error)")
            self.error = error
        }

        isLoading = false
    }

    /**
     * Load pending requests for a ralley (captain only)
     */
    func loadPendingRequests(for ralleyId: UUID) async -> [PendingJoinRequest] {
        do {
            return try await participationService.loadPendingRequests(ralleyId: ralleyId)
        } catch {
            print("RalleyParticipationManager: Failed to load pending requests: \(error)")
            return []
        }
    }

    /**
     * Approve a join request and add user to chat
     * Also checks if this causes ralley to be full
     */
    func approveJoinRequest(_ request: PendingJoinRequest, chatId: UUID?) async {
        guard let ralleyManager = ralleyManager else { return }

        isLoading = true

        do {
            let success = try await participationService.approveJoinRequest(
                ralleyId: request.ralleyId,
                userId: request.userId
            )

            if success {
                // Update local ralley state
                if let index = ralleyManager.indexOfRalley(request.ralleyId) {
                    ralleyManager.ralleys[index].currentPlayers += 1
                    ralleyManager.ralleys[index].pendingRequestsCount = max(0, ralleyManager.ralleys[index].pendingRequestsCount - 1)

                    // Always add approved user to the ralley chat (ralleyId is the chatId)
                    try? await chatService.addMember(chatId: request.ralleyId, userId: request.userId)
                }

                successMessage = "Request approved!"
                print("RalleyParticipationManager: Approved join request for user \(request.userId)")
            }
        } catch {
            print("RalleyParticipationManager: Failed to approve join request: \(error)")
            self.error = error
        }

        isLoading = false
    }

    /**
     * Reject a join request
     */
    func rejectJoinRequest(_ request: PendingJoinRequest) async {
        guard let ralleyManager = ralleyManager else { return }

        isLoading = true

        do {
            let success = try await participationService.rejectJoinRequest(
                ralleyId: request.ralleyId,
                userId: request.userId
            )

            if success {
                // Update local ralley state
                if let index = ralleyManager.indexOfRalley(request.ralleyId) {
                    ralleyManager.ralleys[index].pendingRequestsCount = max(0, ralleyManager.ralleys[index].pendingRequestsCount - 1)
                }

                successMessage = "Request declined"
                print("RalleyParticipationManager: Rejected join request for user \(request.userId)")
            }
        } catch {
            print("RalleyParticipationManager: Failed to reject join request: \(error)")
            self.error = error
        }

        isLoading = false
    }

    /**
     * Check if user has a pending request for a ralley
     */
    func hasPendingRequest(for ralleyId: UUID) async -> Bool {
        do {
            return try await participationService.hasPendingRequest(ralleyId: ralleyId)
        } catch {
            return false
        }
    }

    /**
     * Get attendees for a ralley
     */
    func getAttendees(for ralleyId: UUID) async -> [RalleyAttendee] {
        do {
            return try await participationService.getAttendees(ralleyId: ralleyId)
        } catch {
            return []
        }
    }

    /**
     * Check current user's participation status in a ralley
     */
    func getParticipationStatus(for ralleyId: UUID) async -> UserParticipationStatus {
        guard let currentUser = supabase.currentUser else { return .notJoined }

        // Check if user has pending request
        if await hasPendingRequest(for: ralleyId) {
            return .pending
        }

        // Check if user is attending
        let attendees = await getAttendees(for: ralleyId)
        if attendees.contains(where: { $0.id == currentUser.id }) {
            return .joined
        }

        return .notJoined
    }

    // MARK: - Clear State

    func clearError() {
        error = nil
    }

    func clearSuccessMessage() {
        successMessage = nil
    }
}

// MARK: - User Participation Status (UI State)

/// Represents the current user's participation state in a ralley (for UI display)
/// Note: This is separate from ParticipationStatus in Ralley.swift which is for database models
enum UserParticipationStatus {
    case notJoined
    case pending
    case joined

    var displayText: String {
        switch self {
        case .notJoined: return "Join"
        case .pending: return "Pending"
        case .joined: return "Joined"
        }
    }

    var buttonColor: Color {
        switch self {
        case .notJoined: return Color(hex: "#2C4F40")
        case .pending: return .orange
        case .joined: return .gray
        }
    }
}
