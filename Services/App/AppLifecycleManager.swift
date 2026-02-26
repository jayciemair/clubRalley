//
//  AppLifecycleManager.swift
//  Club Ralley
//
//  Coordinates app-level events and data refreshes
//

import Foundation
import SwiftUI
import Combine

/// Manages app lifecycle events and coordinates data updates
@MainActor
final class AppLifecycleManager: ObservableObject {

    // MARK: - Singleton

    static let shared = AppLifecycleManager()

    // MARK: - Dependencies

    private let authService = AuthenticationService.shared

    // MARK: - Properties

    private var cancellables = Set<AnyCancellable>()
    private var hasInitialized = false
    private var lastActiveTime: Date?

    // MARK: - Initialization

    private init() {
        setupNotificationObservers()
    }

    // MARK: - Public Methods

    /// Initialize app data on launch
    func initializeOnLaunch() async {
        guard !hasInitialized else { return }

        await updateLastActiveTimestamp()

        hasInitialized = true
        lastActiveTime = Date()
    }

    /// Handle app becoming active (returning from background)
    func handleAppBecameActive() async {
        await updateLastActiveTimestamp()
        lastActiveTime = Date()
    }

    /// Handle app going to background
    func handleAppWentToBackground() {
        lastActiveTime = Date()
    }

    // MARK: - Private Methods

    /// Update last_active_at timestamp in database
    private func updateLastActiveTimestamp() async {
        guard case .authenticated(let session) = authService.authState,
              let userId = UUID(uuidString: session.userId) else {
            return
        }

        do {
            let supabase = SupabaseClientManager.shared

            struct LastActiveUpdate: Encodable {
                let last_active_at: Date
            }

            let update = LastActiveUpdate(last_active_at: Date())

            try await supabase.database
                .from("users")
                .update(update)
                .eq("id", value: userId.uuidString)
                .execute()
        } catch {
            // Silent failure - this is not critical
        }
    }

    private func setupNotificationObservers() {
        NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)
            .sink { [weak self] _ in
                Task { @MainActor [weak self] in
                    await self?.handleAppBecameActive()
                }
            }
            .store(in: &cancellables)

        NotificationCenter.default.publisher(for: UIApplication.didEnterBackgroundNotification)
            .sink { [weak self] _ in
                Task { @MainActor [weak self] in
                    self?.handleAppWentToBackground()
                }
            }
            .store(in: &cancellables)
    }

    // MARK: - Debug Methods

    #if DEBUG
    func debugTriggerRefresh() async {
        await updateLastActiveTimestamp()
    }
    #endif
}
