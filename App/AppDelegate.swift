//
//  AppDelegate.swift
//  Checkpoint
//
//  Handles background notification delivery, shield clearing, and quick actions
//

import UIKit
import UserNotifications
import AppTrackingTransparency

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

    // MARK: - UNUserNotificationCenterDelegate

    /// Called when notification is delivered (even in background!)
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Handle notification while app is in foreground
        handleSessionEndNotification(notification)

        // Show notification banner/sound
        completionHandler([.banner, .sound])
    }

    /// Called when notification is delivered in background (THIS IS KEY!)
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        // Handle notification tap
        handleSessionEndNotification(response.notification)
        completionHandler()
    }

    // MARK: - Background Shield Clearing

    private func handleSessionEndNotification(_ notification: UNNotification) {
        // Session end notification handling - protection service removed
        // Can be extended for other notification types in the future
    }
}
