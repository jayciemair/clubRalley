//
//  NotificationSettingsService.swift
//  Club Ralley
//
//  Syncs notification preferences between the app and the server
//

import Foundation

@MainActor
class NotificationSettingsService: ObservableObject {

    // MARK: - Singleton

    static let shared = NotificationSettingsService()

    // MARK: - Published Properties

    @Published var isLoading = false

    // MARK: - Initialization

    private init() {}

    // MARK: - Server Sync

    /// Load notification settings from the server
    func loadSettings() async -> NotificationSettingsRecord? {
        guard let userId = SupabaseManager.shared.currentUser?.id else { return nil }

        do {
            let client = SupabaseClientManager.shared
            let records: [NotificationSettingsRecord] = try await client.database
                .from("notification_settings")
                .select()
                .eq("user_id", value: userId)
                .execute()
                .value

            return records.first
        } catch {
            print("⚠️ NotificationSettingsService: Failed to load settings: \(error)")
            return nil
        }
    }

    /// Upsert notification settings to the server
    func syncSettings(
        pushEnabled: Bool,
        ralleyInvites: Bool,
        ralleyUpdates: Bool,
        newFollowers: Bool,
        commentsLikes: Bool
    ) async {
        guard let userId = SupabaseManager.shared.currentUser?.id else { return }

        let record = NotificationSettingsRecord(
            user_id: userId,
            push_enabled: pushEnabled,
            ralley_invites: ralleyInvites,
            ralley_updates: ralleyUpdates,
            new_followers: newFollowers,
            comments_likes: commentsLikes
        )

        do {
            let client = SupabaseClientManager.shared
            try await client.database
                .from("notification_settings")
                .upsert(record, onConflict: "user_id")
                .execute()

            print("✅ NotificationSettingsService: Synced settings to server")
        } catch {
            print("❌ NotificationSettingsService: Failed to sync settings: \(error)")
        }
    }
}

// MARK: - Database Model

struct NotificationSettingsRecord: Codable {
    let user_id: UUID
    let push_enabled: Bool
    let ralley_invites: Bool
    let ralley_updates: Bool
    let new_followers: Bool
    let comments_likes: Bool
}
