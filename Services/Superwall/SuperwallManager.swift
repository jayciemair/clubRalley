//
//  SuperwallManager.swift
//  Checkpoint
//
//  Manages Superwall integration for paywalls
//  Note: Subscription status is now managed by RevenueCat (via RCPurchaseController)
//

import Foundation
import SuperwallKit
import StoreKit

class SuperwallManager: NSObject, ObservableObject {
    static let shared = SuperwallManager()

    // MARK: - Properties

    /// Subscription status from RevenueCat's cache (avoids actor isolation issues)
    var isSubscribed: Bool {
        UserDefaults.standard.bool(forKey: "rc_lastKnownSubscriptionStatus")
    }

    /// Subscription status from RevenueCat's cache (avoids actor isolation issues)
    var hasActiveEntitlements: Bool {
        UserDefaults.standard.bool(forKey: "rc_lastKnownSubscriptionStatus")
    }

    // Callback for purchase completion (for onboarding flow navigation)
    var onPurchaseComplete: (() -> Void)?

    // Callback for when paywall is dismissed without purchase
    var onPaywallDismissed: (() -> Void)?

    private var isSetupComplete = false

    private override init() {
        super.init()
        // DON'T access Superwall.shared here - it may not be configured yet
        // Note: Subscription status caching is now handled by RevenueCat
    }

    // MARK: - Setup

    /// Call this AFTER Superwall.configure() has been called
    func completeSetup() {
        guard !isSetupComplete else { return }
        isSetupComplete = true

        // Now safe to access Superwall.shared
        Superwall.shared.delegate = self
        setUserAttributes()
        print("[Superwall] ✅ SuperwallManager setup complete")
    }

    private func configureSuperwallOptions() {
        // Note: This documents our preferred settings
        // Actual configuration happens in AppDelegate.configure()
        // To apply these settings, update AppDelegate.swift

        let options = SuperwallOptions()

        // Configure logging based on build configuration
        #if DEBUG
        options.logging.level = .debug
        options.logging.scopes = [.all]
        // print("🔧 Superwall: Debug logging enabled")
        #else
        options.logging.level = .warn
        options.logging.scopes = [.paywallPresentation]
        #endif

        // Configure paywall behavior
        options.paywalls.shouldShowPurchaseFailureAlert = true
        options.paywalls.automaticallyDismiss = true

        // Use StoreKit 2 for better performance on iOS 15+
        options.storeKitVersion = .storeKit2

        // These settings should be applied in AppDelegate
    }

    private func setUserAttributes() {
        // Set custom user properties for paywall targeting
        if let userId = UserDefaults.standard.string(forKey: "userId") {
            Superwall.shared.setUserAttributes(["userId": userId])
        }

        // Add any other relevant user attributes
        let attributes: [String: Any] = [
            "app_install_date": UserDefaults.standard.object(forKey: "app_install_date") ?? Date(),
            "onboarding_completed": UserDefaults.standard.bool(forKey: "onboarding_completed"),
            "platform": "iOS"
        ]

        Superwall.shared.setUserAttributes(attributes)
    }

    // MARK: - Paywall Presentation

    /// Present a paywall for a specific placement
    /// - Parameters:
    ///   - placement: The placement identifier configured in Superwall dashboard
    ///   - params: Optional parameters to pass to the paywall
    ///   - handler: Completion handler called when user either purchases or dismisses
    func presentPaywall(
        placement: String,
        params: [String: Any]? = nil,
        handler: PaywallPresentationHandler? = nil
    ) {
        // print("[Superwall] 📍 presentPaywall() called with placement: \(placement)")
        // print("[Superwall] 📍 params: \(params ?? [:])")
        Superwall.shared.register(
            placement: placement,
            params: params ?? [:],
            handler: handler
        )
        // print("[Superwall] 📍 Superwall.shared.register() completed")
    }

    /// Common paywall placements - Deprecated in favor of SuperwallPlacements
    @available(*, deprecated, message: "Use SuperwallPlacements enum instead")
    enum Placement {
        static let onboarding = "onboarding"
        static let featureLimit = "feature_limit"
        static let settings = "settings"
        static let sessionEnd = "session_end"
        static let strictMode = "strict_mode"
        static let weeklyPrompt = "weekly_prompt"
    }

    // MARK: - Helper Methods

    /// Restore purchases
    func restorePurchases() async {
        // Superwall handles restore internally
        // You can trigger a restore through a paywall or programmatically
    }

    /// Identify user for analytics and targeting
    func identify(userId: String) {
        Superwall.shared.identify(userId: userId)
        UserDefaults.standard.set(userId, forKey: "userId")
    }

    /// Reset user on logout
    func reset() {
        Superwall.shared.reset()
        UserDefaults.standard.removeObject(forKey: "userId")
    }

    /// Update projected loss for paywall personalization
    /// - Parameter projectedLoss: The calculated projected lifetime loss
    /// - Parameter projectedAnnualLoss: The calculated projected annual loss
    /// - Parameter weeklySavings: The calculated weekly savings (optional)
    /// - Parameter dailyBetAmount: The raw daily bet amount as integer (optional)
    func updateProjectedLoss(
        _ projectedLoss: Int,
        projectedAnnualLoss: Int,
        weeklySavings: Int? = nil,
        dailyBetAmount: Int? = nil
    ) {
        // Format number with commas for display
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = ","
        let formattedLifetimeLoss = formatter.string(from: NSNumber(value: projectedLoss)) ?? "\(projectedLoss)"
        let formattedAnnualLoss = formatter.string(from: NSNumber(value: projectedAnnualLoss)) ?? "\(projectedAnnualLoss)"

        var attributes: [String: Any] = [
            "ProjectedLoss2": formattedLifetimeLoss,  // Send formatted string (e.g., "5,005,000")
            "ProjectedAnnualLoss": formattedAnnualLoss  // Send formatted string (e.g., "52,000")
        ]

        // Add weekly savings if provided (formatted string with $ sign)
        if let weeklySavings = weeklySavings {
            let formattedWeeklySavings = formatter.string(from: NSNumber(value: weeklySavings)) ?? "\(weeklySavings)"
            attributes["WeeklySavings"] = "$\(formattedWeeklySavings)"  // e.g., "$1,250"
        }

        // Add daily bet amount if provided (raw integer for ratio calculations)
        if let dailyBetAmount = dailyBetAmount {
            attributes["DailyBetAmount"] = dailyBetAmount  // e.g., 250
        }

        Superwall.shared.setUserAttributes(attributes)
    }

    /// Debug: Print current Superwall subscription status
    func debugPrintSubscriptionStatus() {
        // let status = Superwall.shared.subscriptionStatus
        // print("[Superwall] 🔍 Subscription Status Check:")
        // switch status {
        // case .active(let entitlements):
        //     print("[Superwall]    Status: ACTIVE ✅")
        //     print("[Superwall]    Entitlements: \(entitlements.map { $0.id })")
        //     print("[Superwall]    ⚠️ Paywalls will NOT show unless audience filter allows subscribed users")
        // case .inactive:
        //     print("[Superwall]    Status: INACTIVE ❌")
        //     print("[Superwall]    ✅ Paywalls WILL show")
        // case .unknown:
        //     print("[Superwall]    Status: UNKNOWN ⏳")
        //     print("[Superwall]    ⚠️ Paywalls will NOT show until status is set")
        // }
    }

    // MARK: - Subscription Status

    /// Get current subscription status from RevenueCat's cache
    func getCurrentSubscriptionStatus() -> Bool {
        return UserDefaults.standard.bool(forKey: "rc_lastKnownSubscriptionStatus")
    }
}

// MARK: - SuperwallDelegate

extension SuperwallManager: SuperwallDelegate {

    func handleSuperwallEvent(withInfo eventInfo: SuperwallEventInfo) {
        // print("[Superwall] ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        // print("[Superwall] 🎯 DELEGATE EVENT RECEIVED: \(eventInfo.event)")
        // print("[Superwall] 🎯 Event Type: \(type(of: eventInfo.event))")
        // print("[Superwall] 🎯 onPurchaseComplete is: \(self.onPurchaseComplete == nil ? "NIL" : "SET")")
        // print("[Superwall] 🎯 onPaywallDismissed is: \(self.onPaywallDismissed == nil ? "NIL" : "SET")")
        // print("[Superwall] ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")

        switch eventInfo.event {
        case .paywallOpen:
            // print("[Superwall] ✅ Paywall Opened: \(info.name)")
            break

        case .paywallClose:
            // print("[Superwall] ❌❌❌ PAYWALL CLOSE EVENT RECEIVED ❌❌❌")
            // print("[Superwall] ❌ Paywall Name: \(info.name)")
            // print("[Superwall] ❌ onPaywallDismissed callback is: \(self.onPaywallDismissed == nil ? "NIL" : "SET")")
            // Trigger dismissed callback on main thread
            DispatchQueue.main.async {
                // print("[Superwall] 🔔 On main thread, calling onPaywallDismissed callback...")
                self.onPaywallDismissed?()
                // print("[Superwall] 🔔 onPaywallDismissed call completed")
            }

        case .paywallDecline:
            // print("[Superwall] 👎 Paywall Declined: \(info.name)")
            // Also trigger dismissed callback on decline on main thread
            DispatchQueue.main.async {
                // print("[Superwall] 🔔 Calling onPaywallDismissed callback (from decline)")
                self.onPaywallDismissed?()
            }

        case .transactionStart:
            // print("[Superwall] 🛒 Transaction Started: \(product.productIdentifier)")
            break

        case .transactionComplete:
            // print("[Superwall] ✅ Transaction Complete: \(product.productIdentifier), Type: \(type)")
            // Don't trigger callback here - wait for subscriptionStart or nonRecurringProductPurchase
            break

        case .transactionFail:
            // print("[Superwall] 💥 Transaction Failed: \(error)")
            break

        case .transactionAbandon(let product, let paywallInfo):
            // print("[Superwall] 🏃 Transaction Abandoned: \(product.productIdentifier)")
            // Implement sophisticated transaction recovery with delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                Superwall.shared.register(
                    placement: SuperwallPlacements.transactionAbandonDiscount,
                    params: [
                        "product_id": product.productIdentifier,
                        "paywall_id": paywallInfo.identifier
                    ]
                )
            }

        case .subscriptionStart(let product, let paywallInfo):
            // print("[Superwall] 🎉 SUBSCRIPTION START: \(product.productIdentifier)")
            // print("[Superwall] 🔔 Calling onPurchaseComplete callback")

            // Track subscription start with Adjust (with revenue)
            let revenue = product.sk2Product.map { NSDecimalNumber(decimal: $0.price).doubleValue }
            let currency = product.sk2Product?.priceFormatStyle.currencyCode ?? "USD"

            AdjustService.shared.trackSubscriptionStarted(
                productId: product.productIdentifier,
                isFreeTrial: false,  // Regular subscription (not a trial)
                revenue: revenue,  // Pass actual product price from StoreKit 2
                currency: currency
            )

            // Trigger purchase complete callback on main thread
            DispatchQueue.main.async {
                self.onPurchaseComplete?()
            }

        case .freeTrialStart(let product, let paywallInfo):
            // print("[Superwall] 🎉🎉🎉 FREE TRIAL START EVENT RECEIVED! 🎉🎉🎉")
            // print("[Superwall] 🎉 Product: \(product.productIdentifier)")
            // print("[Superwall] 🎉 Paywall Info: \(paywallInfo.name)")
            // #if DEBUG
            // print("[Superwall] 🔔 NOTIFICATION REMINDER: In sandbox mode, trial reminder notifications fire in MINUTES, not DAYS")
            // print("[Superwall] 🔔 If you configured a 2-day reminder in the paywall editor, it will fire in 2 MINUTES")
            // print("[Superwall] 🔔 In production, it will fire in 2 DAYS (normal timing)")
            // #else
            // print("[Superwall] 🔔 Trial reminder notifications will fire based on configured delay in DAYS")
            // #endif
            // print("[Superwall] 🎉 onPurchaseComplete callback is: \(self.onPurchaseComplete == nil ? "NIL (THIS IS THE BUG!)" : "SET (good)")")
            // print("[Superwall] 🔔 About to call onPurchaseComplete callback on main thread...")

            // Track trial start with Adjust
            AdjustService.shared.trackTrialStarted(productId: product.productIdentifier)

            // Also track as subscription started with trial flag
            AdjustService.shared.trackSubscriptionStarted(
                productId: product.productIdentifier,
                isFreeTrial: true
            )

            // Trigger purchase complete callback on main thread
            DispatchQueue.main.async {
                // print("[Superwall] 🔔 Now on main thread, calling onPurchaseComplete...")
                self.onPurchaseComplete?()
                // print("[Superwall] 🔔 onPurchaseComplete call completed")
            }

        case .nonRecurringProductPurchase(let product, let paywallInfo):
            // print("[Superwall] 🎉 NON-RECURRING PURCHASE: \(product.id)")
            // print("[Superwall] 🔔 Calling onPurchaseComplete callback")

            // Track one-time purchase as subscription started (no trial)
            AdjustService.shared.trackSubscriptionStarted(
                productId: product.id,
                isFreeTrial: false
            )

            // Trigger purchase complete callback on main thread
            DispatchQueue.main.async {
                self.onPurchaseComplete?()
            }

        case .transactionRestore:
            // print("[Superwall] 🔄 Transaction Restored")
            break

        case .userAttributes:
            // print("[Superwall] 👤 User Attributes Updated: \(attributes)")
            break

        default:
            // print("[Superwall] ℹ️ Other Event: \(eventInfo.event)")
            break
        }
    }

    /// Called when subscription status changes
    /// Note: Subscription syncing is now handled by RevenueCat's PurchaseController
    func subscriptionStatusDidChange(from oldValue: SuperwallKit.SubscriptionStatus, to newValue: SuperwallKit.SubscriptionStatus) {
        // Subscription status changes are now synced by RCPurchaseController
        // This delegate is kept for logging purposes only
        print("[Superwall] 🔄 Subscription status changed: \(oldValue) -> \(newValue)")
    }
}

// MARK: - SwiftUI View Extensions

import SwiftUI

extension View {
    /// Present a Superwall paywall when this view appears
    func superwallPaywall(
        placement: String,
        params: [String: Any]? = nil
    ) -> some View {
        self.onAppear {
            SuperwallManager.shared.presentPaywall(
                placement: placement,
                params: params
            )
        }
    }

    /// Present paywall based on a condition
    func superwallPaywallIfNeeded(
        placement: String,
        condition: Bool,
        params: [String: Any]? = nil
    ) -> some View {
        self.onAppear {
            if condition {
                SuperwallManager.shared.presentPaywall(
                    placement: placement,
                    params: params
                )
            }
        }
    }
}

// MARK: - Example Usage

/*

 // In your view:

 struct ContentView: View {
     @StateObject private var superwallManager = SuperwallManager.shared

     var body: some View {
         VStack {
             Button("Show Paywall") {
                 SuperwallManager.shared.presentPaywall(
                     placement: SuperwallManager.Placement.settings,
                     params: ["source": "settings_button"]
                 ) { result in
                     switch result {
                     case .purchased:
                         print("User purchased!")
                     case .declined:
                         print("User declined")
                     case .restored:
                         print("Purchase restored")
                     @unknown default:
                         break
                     }
                 }
             }
         }
         .superwallPaywall(placement: SuperwallManager.Placement.onboarding)
     }
 }

 // For feature gating:

 func unlockFeature() {
     SuperwallManager.shared.presentPaywall(
         placement: SuperwallManager.Placement.featureLimit,
         params: ["feature": "advanced_blocking"]
     ) { result in
         if case .purchased = result {
             // Feature is now unlocked
             enableAdvancedBlocking()
         }
     }
 }

 */
