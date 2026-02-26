//
//  PushNotificationService.swift
//  Club Ralley
//
//  Manages APNs device token registration and push notification permissions
//

import Foundation
import UIKit
import UserNotifications

@MainActor
class PushNotificationService: ObservableObject {

    // MARK: - Singleton

    static let shared = PushNotificationService()

    // MARK: - Published Properties

    @Published var pushAuthorizationStatus: UNAuthorizationStatus = .notDetermined

    // MARK: - Private Properties

    private var currentToken: String?

    // MARK: - Initialization

    private init() {}

    // MARK: - Permission & Registration

    /// Request push notification permission, then register for remote notifications
    func requestPermissionAndRegister() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                print("⚠️ PushNotificationService: Authorization request failed: \(error.localizedDescription)")
                return
            }

            Task { @MainActor in
                self.pushAuthorizationStatus = granted ? .authorized : .denied
            }

            if granted {
                DispatchQueue.main.async {
                    UIApplication.shared.registerForRemoteNotifications()
                }
                print("✅ PushNotificationService: Push authorization granted, registering for remote notifications")
            } else {
                print("⚠️ PushNotificationService: Push authorization denied by user")
            }
        }
    }

    /// Re-check the current authorization status (e.g. when returning from Settings)
    func refreshPermissionStatus() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        pushAuthorizationStatus = settings.authorizationStatus

        // If authorized but no token yet, re-register
        if settings.authorizationStatus == .authorized {
            UIApplication.shared.registerForRemoteNotifications()
        }
    }

    // MARK: - Token Management

    /// Called from AppDelegate when APNs returns a device token
    func handleDeviceToken(_ data: Data) {
        let token = data.map { String(format: "%02.2hhx", $0) }.joined()
        currentToken = token
        print("✅ PushNotificationService: Received device token: \(token.prefix(8))...")

        Task {
            await upsertTokenToServer(token)
        }
    }

    /// Called from AppDelegate when APNs registration fails
    func handleRegistrationFailure(_ error: Error) {
        // Expected to fail on Simulator — not an error in that context
        print("⚠️ PushNotificationService: Remote notification registration failed: \(error.localizedDescription)")
    }

    /// Mark the current device token as inactive (e.g. on logout)
    func deactivateCurrentToken() async {
        guard let token = currentToken else { return }

        do {
            let update = DeviceTokenDeactivate(is_active: false)
            let client = SupabaseClientManager.shared
            try await client.database
                .from("device_tokens")
                .update(update)
                .eq("token", value: token)
                .execute()

            print("✅ PushNotificationService: Deactivated device token")
            currentToken = nil
        } catch {
            print("❌ PushNotificationService: Failed to deactivate token: \(error)")
        }
    }

    // MARK: - Private

    private func upsertTokenToServer(_ token: String) async {
        guard let userId = SupabaseManager.shared.currentUser?.id else {
            print("⚠️ PushNotificationService: No current user, skipping token upsert")
            return
        }

        let record = DeviceTokenRecord(
            user_id: userId,
            token: token,
            platform: "ios",
            is_active: true
        )

        do {
            let client = SupabaseClientManager.shared
            try await client.database
                .from("device_tokens")
                .upsert(record, onConflict: "token")
                .execute()

            print("✅ PushNotificationService: Upserted device token to server")
        } catch {
            print("❌ PushNotificationService: Failed to upsert token: \(error)")
        }
    }
}

// MARK: - Database Models

private struct DeviceTokenRecord: Encodable {
    let user_id: UUID
    let token: String
    let platform: String
    let is_active: Bool
}

private struct DeviceTokenDeactivate: Encodable {
    let is_active: Bool
}
