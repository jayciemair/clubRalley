//
//  RalleyManager.swift
//  Club Ralley
//
//  ViewModel for managing ralley data and operations.
//  Handles loading, creating, and participating in ralleys.
//

import Foundation
import SwiftUI

/**
 * RalleyManager: ViewModel for ralley operations
 *
 * Purpose: Manages ralley data for UI consumption and user actions
 * Strategy: Uses RalleyService for database operations, maintains local cache
 * Usage: Injected as @EnvironmentObject into FindRalleysView and related views
 */
@MainActor
class RalleyManager: ObservableObject {

    // MARK: - Published Properties

    /// All ralleys for discovery feed and user profiles
    @Published var ralleys: [ClubRalley] = []

    /// Controls ralley creation sheet presentation
    @Published var showingCreateRalley = false

    /// Loading state for UI feedback
    @Published var isLoading = false

    /// Error state for user notifications
    @Published var error: Error?

    // MARK: - Dependencies

    /// Service layer for ralley database operations
    private let ralleyService = RalleyService()

    /// Service layer for chat operations
    private let chatService = ChatService()

    /// Supabase authentication state
    private let supabase = SupabaseManager.shared

    // MARK: - Initialization

    init() {
        // Load ralleys from backend on startup
        Task {
            await loadRalleys()
        }
    }

    // MARK: - Ralley Loading

    /**
     * Load ralleys from Supabase database for discovery feed
     * Handles both real data and fallback to mock data for development
     */
    func loadRalleys() async {
        isLoading = true
        error = nil

        do {
            let loadedRalleys = try await ralleyService.loadNearbyRalleys()
            ralleys = loadedRalleys
            print("✅ RalleyManager: Loaded \(loadedRalleys.count) ralleys from backend")
        } catch {
            print("❌ RalleyManager: Failed to load ralleys: \(error)")
            self.error = error

            // Fallback to sample ralleys for development
            await loadSampleRalleys()
        }

        isLoading = false
    }

    /**
     * Load sample ralleys for development and offline scenarios
     * Ensures app remains functional even without backend connectivity
     */
    private func loadSampleRalleys() async {
        let sampleRalleys = [
            ClubRalley(
                id: UUID(),
                title: "Basketball Pickup",
                sport: "Basketball",
                description: "Friendly pickup basketball game. All skill levels welcome!",
                organizer: ClubRalleyOrganizer(
                    id: UUID(),
                    name: "Alex Johnson",
                    username: "@alexj",
                    photoURL: "https://picsum.photos/50/50?random=401"
                ),
                dateTime: Date().addingTimeInterval(3600 * 2), // 2 hours from now
                location: ClubRalleyLocation(
                    name: "Riverside Park Courts",
                    address: "123 Park Ave",
                    city: "Chicago",
                    state: "IL",
                    latitude: 41.8781,
                    longitude: -87.6298
                ),
                maxPlayers: 8,
                currentPlayers: 5,
                cost: 0,
                requirements: "Bring your own water and sneakers",
                isPublic: true
            ),
            ClubRalley(
                id: UUID(),
                title: "Tennis Doubles",
                sport: "Tennis",
                description: "Looking for tennis doubles partners. Intermediate level preferred.",
                organizer: ClubRalleyOrganizer(
                    id: UUID(),
                    name: "Sarah Wilson",
                    username: "@sarahw",
                    photoURL: "https://picsum.photos/50/50?random=402"
                ),
                dateTime: Date().addingTimeInterval(3600 * 18), // Tomorrow morning
                location: ClubRalleyLocation(
                    name: "University Tennis Center",
                    address: "456 College Blvd",
                    city: "Chicago",
                    state: "IL",
                    latitude: 41.8958,
                    longitude: -87.6388
                ),
                maxPlayers: 4,
                currentPlayers: 2,
                cost: 15,
                requirements: "Bring racket and tennis balls",
                isPublic: true
            ),
            ClubRalley(
                id: UUID(),
                title: "My Test Ralley", // User's own ralley for testing
                sport: "Soccer",
                description: "Just created my first ralley! Looking forward to a fun pickup game.",
                organizer: ClubRalleyOrganizer(
                    id: UUID(),
                    name: "Your Name",
                    username: "@you",
                    photoURL: "https://picsum.photos/50/50?random=50"
                ),
                dateTime: Date().addingTimeInterval(3600 * 6), // 6 hours from now
                location: ClubRalleyLocation(
                    name: "Local Soccer Field",
                    address: "789 Sports Ave",
                    city: "Chicago",
                    state: "IL",
                    latitude: 41.8500,
                    longitude: -87.6500
                ),
                maxPlayers: 12,
                currentPlayers: 1,
                cost: 5,
                requirements: "Bring cleats",
                isPublic: true
            )
        ]

        ralleys = sampleRalleys
        print("📱 RalleyManager: Using sample ralleys (fallback mode)")
    }

    // MARK: - Ralley Creation

    /**
     * Create new ralley and save to database
     * @param title: Ralley title
     * @param sport: Sport type
     * @param dateTime: When the ralley happens
     * @param locationName: Venue name
     * @param address: Venue address
     * @param maxPlayers: Maximum participants
     * @param cost: Cost per person (optional)
     * @param description: Ralley description
     * @param requirements: Special requirements
     * @param visibility: Who can see the ralley
     * @param joinType: How users can join
     *
     * Flow: Create local ralley -> Save to database -> Create group chat -> Update local cache
     */
    func createRalley(
        title: String,
        sport: String,
        dateTime: Date,
        locationName: String,
        address: String = "",
        city: String = "San Francisco",
        state: String = "CA",
        maxPlayers: Int,
        cost: Double = 0.0,
        description: String,
        requirements: String = "",
        visibility: RalleyVisibility = .anyone,
        joinType: RalleyJoinType = .open
    ) async {
        guard !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            print("RalleyManager: Cannot create ralley with empty title")
            return
        }

        isLoading = true
        error = nil

        let currentUserId = supabase.currentUser?.id ?? UUID()

        // Create local ralley model with current user as organizer (captain)
        var newRalley = ClubRalley(
            id: UUID(),
            title: title,
            sport: sport,
            description: description,
            organizer: ClubRalleyOrganizer(
                id: currentUserId,
                name: supabase.currentUser?.displayName ?? "Your Name",
                username: "@\(supabase.currentUser?.email.components(separatedBy: "@").first ?? "you")",
                photoURL: "https://picsum.photos/50/50?random=50"
            ),
            dateTime: dateTime,
            location: ClubRalleyLocation(
                name: locationName,
                address: address,
                city: city,
                state: state,
                latitude: 37.7749,
                longitude: -122.4194
            ),
            maxPlayers: maxPlayers,
            currentPlayers: 1,
            cost: Int(cost),
            requirements: requirements,
            isPublic: visibility == .anyone,
            visibility: visibility,
            joinType: joinType,
            isCaptain: true,
            chatId: nil,
            pendingRequestsCount: 0
        )

        do {
            // Save to database via RalleyService
            let createdRalley = try await ralleyService.createRalley(newRalley)
            newRalley = createdRalley

            // Create group chat for the ralley
            do {
                let chatId = try await chatService.createRalleyChat(
                    ralleyId: createdRalley.id,
                    captainId: currentUserId
                )
                newRalley.chatId = chatId
                print("RalleyManager: Group chat created for ralley")
            } catch {
                print("RalleyManager: Failed to create group chat: \(error)")
            }

            // Add to local cache at the top of feed
            ralleys.insert(newRalley, at: 0)
            print("RalleyManager: Ralley created successfully")

        } catch {
            print("RalleyManager: Failed to create ralley: \(error)")
            self.error = error

            // Even if backend fails, add to local cache for immediate UI feedback
            ralleys.insert(newRalley, at: 0)
            print("RalleyManager: Ralley added locally (backend failed)")
        }

        isLoading = false
    }

    // MARK: - Ralley Participation

    /**
     * Join a ralley (add current user as participant)
     * Updates both database and local cache
     * @param ralleyId: ID of ralley to join
     */
    func joinRalley(_ ralleyId: UUID) async {
        guard supabase.isAuthenticated else {
            print("❌ RalleyManager: Must be authenticated to join ralleys")
            return
        }

        // Optimistic UI update - change local state immediately
        if let index = ralleys.firstIndex(where: { $0.id == ralleyId }) {
            guard ralleys[index].currentPlayers < ralleys[index].maxPlayers else {
                print("❌ RalleyManager: Ralley is already full")
                return
            }

            let originalPlayers = ralleys[index].currentPlayers
            ralleys[index].currentPlayers += 1

            print("⚡ RalleyManager: Optimistic join update for ralley")

            // Attempt to sync with database
            do {
                let success = try await ralleyService.joinRalley(ralleyId: ralleyId)

                if success {
                    print("✅ RalleyManager: Join synced with database")
                } else {
                    // Revert optimistic update on failure
                    ralleys[index].currentPlayers = originalPlayers
                }

            } catch {
                print("❌ RalleyManager: Failed to sync join with database: \(error)")

                // Revert optimistic update on failure
                ralleys[index].currentPlayers = originalPlayers
                self.error = error
            }
        }
    }

    /**
     * Legacy method for immediate UI updates (maintains backward compatibility)
     * @param ralley: Full ralley model to add to feed
     */
    func addRalley(_ ralley: ClubRalley) {
        ralleys.insert(ralley, at: 0) // Add to beginning of feed
        print("📝 RalleyManager: Ralley added to local feed")
    }

    // MARK: - User Content Filtering

    /**
     * Get ralleys created by current user for profile display
     * @returns: Array of user's ralleys sorted by date
     */
    func getUserRalleys() -> [ClubRalley] {
        let currentUserName = supabase.currentUser?.displayName ?? "Your Name"
        let userRalleys = ralleys.filter { $0.organizer.name == currentUserName }

        print("👤 RalleyManager: Found \(userRalleys.count) ralleys for current user")
        return userRalleys.sorted { $0.dateTime < $1.dateTime } // Sort by upcoming first
    }

    /**
     * Get ralleys for specific user (for viewing other profiles)
     * @param username: Username to filter ralleys by
     * @returns: Array of user's ralleys
     */
    func getRalleysForUser(username: String) -> [ClubRalley] {
        return ralleys.filter { $0.organizer.username == username }
            .sorted { $0.dateTime < $1.dateTime }
    }

    // MARK: - Feed Management

    /**
     * Refresh ralleys by reloading from database
     * Used for pull-to-refresh functionality
     */
    func refreshRalleys() async {
        print("🔄 RalleyManager: Refreshing ralleys from database")
        await loadRalleys()
    }

    /**
     * Clear error state (for user notification dismissal)
     */
    func clearError() {
        error = nil
    }

    /**
     * Present ralley creation sheet
     */
    func presentCreateRalley() {
        showingCreateRalley = true
    }

    /**
     * Dismiss ralley creation sheet
     */
    func dismissCreateRalley() {
        showingCreateRalley = false
    }

    // MARK: - Join Request Management (Captain)

    /**
     * Load pending requests for a ralley (captain only)
     * @param ralleyId: Ralley ID
     * @returns: Array of pending join requests
     */
    func loadPendingRequests(for ralleyId: UUID) async -> [PendingJoinRequest] {
        do {
            return try await ralleyService.loadPendingRequests(ralleyId: ralleyId)
        } catch {
            print("RalleyManager: Failed to load pending requests: \(error)")
            return []
        }
    }

    /**
     * Approve a join request and add user to chat
     * @param request: The pending request to approve
     * @param chatId: ID of the ralley's group chat
     */
    func approveJoinRequest(_ request: PendingJoinRequest, chatId: UUID?) async {
        do {
            let success = try await ralleyService.approveJoinRequest(
                ralleyId: request.ralleyId,
                userId: request.userId
            )

            if success {
                // Add user to group chat
                if let chatId = chatId {
                    try? await chatService.addMember(chatId: chatId, userId: request.userId)
                }

                // Update local ralley state
                if let index = ralleys.firstIndex(where: { $0.id == request.ralleyId }) {
                    ralleys[index].currentPlayers += 1
                    ralleys[index].pendingRequestsCount = max(0, ralleys[index].pendingRequestsCount - 1)
                }

                print("RalleyManager: Approved join request for user \(request.userId)")
            }
        } catch {
            print("RalleyManager: Failed to approve join request: \(error)")
        }
    }

    /**
     * Reject a join request
     * @param request: The pending request to reject
     */
    func rejectJoinRequest(_ request: PendingJoinRequest) async {
        do {
            let success = try await ralleyService.rejectJoinRequest(
                ralleyId: request.ralleyId,
                userId: request.userId
            )

            if success {
                // Update local ralley state
                if let index = ralleys.firstIndex(where: { $0.id == request.ralleyId }) {
                    ralleys[index].pendingRequestsCount = max(0, ralleys[index].pendingRequestsCount - 1)
                }

                print("RalleyManager: Rejected join request for user \(request.userId)")
            }
        } catch {
            print("RalleyManager: Failed to reject join request: \(error)")
        }
    }

    // MARK: - Join Request Submission (User)

    /**
     * Request to join a private ralley
     * @param ralleyId: Ralley ID to request to join
     */
    func requestToJoin(_ ralleyId: UUID) async {
        do {
            let success = try await ralleyService.requestToJoin(ralleyId: ralleyId)
            if success {
                print("RalleyManager: Join request submitted")
            }
        } catch {
            print("RalleyManager: Failed to submit join request: \(error)")
            self.error = error
        }
    }

    /**
     * Check if user has a pending request for a ralley
     * @param ralleyId: Ralley ID
     * @returns: True if pending request exists
     */
    func hasPendingRequest(for ralleyId: UUID) async -> Bool {
        do {
            return try await ralleyService.hasPendingRequest(ralleyId: ralleyId)
        } catch {
            return false
        }
    }
}
