//
//  RalleyManager.swift
//  Club Ralley
//
//  ViewModel for managing ralley data and core operations.
//  Handles loading, creating, and displaying ralleys.
//

import Foundation
import SwiftUI

/**
 * RalleyManager: ViewModel for core ralley operations
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

    // MARK: - Sub-managers

    /// Participation manager for join/leave operations
    @Published var participationManager: RalleyParticipationManager?

    /// Completion manager for ralley completion flow
    @Published var completionManager: RalleyCompletionManager?

    // MARK: - Initialization

    init() {
        self.participationManager = RalleyParticipationManager(ralleyManager: self)
        self.completionManager = RalleyCompletionManager(ralleyManager: self)

        // Load joined ralleys from local storage
        loadJoinedRalleys()

        // Load ralleys from backend on startup
        Task {
            await loadRalleys()
        }
    }

    // MARK: - Ralley Loading

    /**
     * Load ralleys from Supabase database for discovery feed
     */
    func loadRalleys() async {
        isLoading = true
        error = nil

        do {
            let loadedRalleys = try await ralleyService.loadNearbyRalleys()
            ralleys = loadedRalleys
            print("RalleyManager: Loaded \(loadedRalleys.count) ralleys from backend")
        } catch {
            print("RalleyManager: Failed to load ralleys: \(error)")
            self.error = error
            // Let UI show empty state - no mock data fallback
            ralleys = []
        }

        isLoading = false

        // Start monitoring for ended ralleys (for captain completion flow)
        completionManager?.startMonitoring()
    }

    // MARK: - Ralley Creation

    /**
     * Create new ralley and save to database
     */
    func createRalley(
        title: String,
        sport: String,
        dateTime: Date,
        durationMinutes: Int = 60,
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

        // Create local ralley model
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
            pendingRequestsCount: 0,
            durationMinutes: durationMinutes
        )

        do {
            // Save to database
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

            // Add to local cache
            ralleys.insert(newRalley, at: 0)
            print("RalleyManager: Ralley created successfully")

        } catch {
            print("RalleyManager: Failed to create ralley: \(error)")
            self.error = error

            // Add to local cache anyway for immediate UI feedback
            ralleys.insert(newRalley, at: 0)
            print("RalleyManager: Ralley added locally (backend failed)")
        }

        isLoading = false
    }

    // MARK: - Participation (Delegated)

    func joinRalley(_ ralleyId: UUID) async {
        await participationManager?.joinRalley(ralleyId)
    }

    func requestToJoin(_ ralleyId: UUID) async {
        await participationManager?.requestToJoin(ralleyId)
    }

    func loadPendingRequests(for ralleyId: UUID) async -> [PendingJoinRequest] {
        return await participationManager?.loadPendingRequests(for: ralleyId) ?? []
    }

    func approveJoinRequest(_ request: PendingJoinRequest, chatId: UUID?) async {
        await participationManager?.approveJoinRequest(request, chatId: chatId)
    }

    func rejectJoinRequest(_ request: PendingJoinRequest) async {
        await participationManager?.rejectJoinRequest(request)
    }

    func hasPendingRequest(for ralleyId: UUID) async -> Bool {
        return await participationManager?.hasPendingRequest(for: ralleyId) ?? false
    }

    // MARK: - Completion (Delegated)

    /**
     * Start completion flow for a ralley (captain only)
     */
    func startCompletionFlow(for ralley: ClubRalley) async {
        await completionManager?.startCompletion(for: ralley)
    }

    /**
     * Check if there are any pending completion ralleys
     */
    var hasPendingCompletions: Bool {
        !(completionManager?.pendingCompletionRalleys.isEmpty ?? true)
    }

    // MARK: - Legacy Method

    func addRalley(_ ralley: ClubRalley) {
        ralleys.insert(ralley, at: 0)
        print("RalleyManager: Ralley added to local feed")
    }

    // MARK: - User Content Filtering

    /// Ralleys the current user has joined (tracked locally)
    @Published var joinedRalleyIds: Set<UUID> = []

    func getUserRalleys() -> [ClubRalley] {
        let currentUserName = supabase.currentUser?.displayName ?? "Your Name"
        let userRalleys = ralleys.filter { $0.organizer.name == currentUserName }

        print("RalleyManager: Found \(userRalleys.count) ralleys for current user")
        return userRalleys.sorted { $0.dateTime < $1.dateTime }
    }

    /// Get upcoming ralleys the user has joined
    func getJoinedUpcomingRalleys() -> [ClubRalley] {
        let now = Date()
        return ralleys
            .filter { joinedRalleyIds.contains($0.id) && $0.dateTime > now }
            .sorted { $0.dateTime < $1.dateTime }
    }

    /// Mark a ralley as joined (called when user joins)
    func markRalleyAsJoined(_ ralleyId: UUID) {
        joinedRalleyIds.insert(ralleyId)
        saveJoinedRalleys()
    }

    /// Mark a ralley as left (called when user leaves)
    func markRalleyAsLeft(_ ralleyId: UUID) {
        joinedRalleyIds.remove(ralleyId)
        saveJoinedRalleys()
    }

    /// Save joined ralleys to UserDefaults
    private func saveJoinedRalleys() {
        let ids = joinedRalleyIds.map { $0.uuidString }
        UserDefaults.standard.set(ids, forKey: "joinedRalleyIds")
    }

    /// Load joined ralleys from UserDefaults
    func loadJoinedRalleys() {
        if let ids = UserDefaults.standard.stringArray(forKey: "joinedRalleyIds") {
            joinedRalleyIds = Set(ids.compactMap { UUID(uuidString: $0) })
            print("RalleyManager: Loaded \(joinedRalleyIds.count) joined ralleys")
        }
    }

    func getRalleysForUser(username: String) -> [ClubRalley] {
        return ralleys.filter { $0.organizer.username == username }
            .sorted { $0.dateTime < $1.dateTime }
    }

    // MARK: - Feed Management

    func refreshRalleys() async {
        print("RalleyManager: Refreshing ralleys from database")
        await loadRalleys()
    }

    func clearError() {
        error = nil
    }

    func presentCreateRalley() {
        showingCreateRalley = true
    }

    func dismissCreateRalley() {
        showingCreateRalley = false
    }

    // MARK: - Internal Methods

    func updateRalley(at index: Int, with updatedRalley: ClubRalley) {
        guard index >= 0 && index < ralleys.count else { return }
        ralleys[index] = updatedRalley
    }

    func indexOfRalley(_ ralleyId: UUID) -> Int? {
        return ralleys.firstIndex(where: { $0.id == ralleyId })
    }
}
