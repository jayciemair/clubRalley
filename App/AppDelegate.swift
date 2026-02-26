//
//  AppDelegate.swift
//  Checkpoint
//
//  Handles background notification delivery, shield clearing, and quick actions
//

import UIKit
import UserNotifications
import AppTrackingTransparency
import GoogleSignIn

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        // CRITICAL PATH ONLY - Keep this minimal for fast launch
        // All SDK initialization is deferred to AppInitializer (called from CheckpointApp.task)

        // Set notification delegate to receive notifications in background
        UNUserNotificationCenter.current().delegate = self

        // Request App Tracking Transparency permission (for better attribution)
        // Delay to avoid showing popup immediately on first launch
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.requestTrackingPermission()
        }

        return true
    }

    // MARK: - Google Sign-In URL Handling

    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        // Handle Google Sign-In callback
        if GIDSignIn.sharedInstance.handle(url) {
            return true
        }
        return false
    }

    // MARK: - Scene Configuration

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        let config = UISceneConfiguration(name: nil, sessionRole: connectingSceneSession.role)
        config.delegateClass = SceneDelegate.self
        return config
    }

    private func requestTrackingPermission() {
        // Only request on iOS 14+
        if #available(iOS 14, *) {
            ATTrackingManager.requestTrackingAuthorization { status in
                #if DEBUG
                switch status {
                case .authorized:
                    print("🎯 ATT: User authorized tracking")
                case .denied:
                    print("🎯 ATT: User denied tracking")
                case .restricted:
                    print("🎯 ATT: Tracking restricted")
                case .notDetermined:
                    print("🎯 ATT: Tracking not determined")
                @unknown default:
                    break
                }
                #endif
            }
        }
    }

    // MARK: - APNs Registration

    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        Task { @MainActor in
            PushNotificationService.shared.handleDeviceToken(deviceToken)
        }
    }

    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        Task { @MainActor in
            PushNotificationService.shared.handleRegistrationFailure(error)
        }
    }

    // MARK: - UNUserNotificationCenterDelegate

    /// Called when notification arrives while app is in foreground
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // If this is a remote push, suppress the banner — in-app Realtime already handles it
        if notification.request.trigger is UNPushNotificationTrigger {
            completionHandler([])
            return
        }

        // Local notifications: show banner/sound as before
        handleSessionEndNotification(notification)
        completionHandler([.banner, .sound])
    }

    /// Called when user taps a notification (local or remote)
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo

        // Handle remote push tap — deep link to the right screen
        if response.notification.request.trigger is UNPushNotificationTrigger {
            handlePushNotificationTap(userInfo: userInfo)
            completionHandler()
            return
        }

        // Local notification tap
        handleSessionEndNotification(response.notification)
        completionHandler()
    }

    // MARK: - Push Deep Linking

    private func handlePushNotificationTap(userInfo: [AnyHashable: Any]) {
        var info: [String: Any] = [:]

        if let type = userInfo["type"] as? String {
            info["type"] = type
        }
        if let notificationId = userInfo["notification_id"] as? String {
            info["notification_id"] = notificationId
        }
        if let ralleyId = userInfo["ralley_id"] as? String {
            info["ralley_id"] = ralleyId
        }
        if let postId = userInfo["post_id"] as? String {
            info["post_id"] = postId
        }
        if let actorId = userInfo["actor_id"] as? String {
            info["actor_id"] = actorId
        }

        NotificationCenter.default.post(
            name: NSNotification.Name("ClubRalleyPushTap"),
            object: nil,
            userInfo: info
        )
    }

    // MARK: - Background Shield Clearing

    private func handleSessionEndNotification(_ notification: UNNotification) {
        // Session end notification handling - protection service removed
        // Can be extended for other notification types in the future
    }
}
