//
//  SceneDelegate.swift
//  Checkpoint
//
//  Handles quick actions (home screen shortcuts) for SwiftUI lifecycle
//

import UIKit

class SceneDelegate: NSObject, UIWindowSceneDelegate {

    /// Called when app is launched from a quick action (cold start)
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        if let shortcutItem = connectionOptions.shortcutItem {
            print("📧 Scene willConnectTo with shortcut: \(shortcutItem.type)")
            handleShortcutItem(shortcutItem)
        }
    }

    /// Called when app is in background and quick action is tapped
    func windowScene(_ windowScene: UIWindowScene, performActionFor shortcutItem: UIApplicationShortcutItem, completionHandler: @escaping (Bool) -> Void) {
        print("📧 windowScene performActionFor: \(shortcutItem.type)")
        let handled = handleShortcutItem(shortcutItem)
        completionHandler(handled)
    }

    @discardableResult
    private func handleShortcutItem(_ shortcutItem: UIApplicationShortcutItem) -> Bool {
        switch shortcutItem.type {
        case "com.checkpoint.reminder":
            // Just open the app - no action needed
            return true
        case "com.checkpoint.feedback":
            // Open email to collect feedback
            let emailURL = URL(string: "mailto:hello@checkpoint.so")!
            print("📧 Opening mailto URL")
            UIApplication.shared.open(emailURL, options: [:]) { success in
                print("📧 mailto open result: \(success)")
            }
            return true
        case "com.checkpoint.tryfree":
            // Show Superwall paywall with specific campaign
            print("🎁 Try for free quick action tapped")
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                SuperwallManager.shared.presentPaywall(
                    placement: SuperwallPlacements.quickActionTryFree,
                    params: ["source": "quick_action_delete"]
                )
            }
            return true
        default:
            return false
        }
    }
}
