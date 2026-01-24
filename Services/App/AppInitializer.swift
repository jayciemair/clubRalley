//
//  AppInitializer.swift
//  Checkpoint
//
//  Handles phased app initialization to optimize launch time.
//  SDKs are initialized AFTER the first frame renders, on background threads where possible.
//

import Foundation
import SuperwallKit
// import AdjustSdk  // Temporarily disabled

final class AppInitializer: ObservableObject {

    static let shared = AppInitializer()

    // MARK: - State

    @Published private(set) var isInitialized = false
    private var isInitializing = false

    private init() {}

    // MARK: - Public API

    /// Initialize all services. Call this from .task { } in your root view.
    /// This is NON-BLOCKING - fires off initialization and returns immediately.
    @MainActor
    func initialize() {
        guard !isInitialized && !isInitializing else { return }
        isInitializing = true

        print("[AppInit] 🚀 Starting non-blocking initialization...")

        // Fire off SDK initialization on background thread - DON'T WAIT
        Task.detached(priority: .userInitiated) {
            await self.initializeSDKs()
        }
    }

    // MARK: - Private Methods

    private func initializeSDKs() async {
        let startTime = CFAbsoluteTimeGetCurrent()
        print("[AppInit] 📦 Initializing SDKs on background thread...")

        // CRITICAL: Initialize RevenueCat FIRST (must be before Superwall)
        // RevenueCat will handle subscription management and sync to Superwall
        await MainActor.run {
            RevenueCatManager.shared.configure()
        }

        // Small yield to let UI breathe
        try? await Task.sleep(nanoseconds: 10_000_000) // 10ms

        // Initialize Superwall WITH RevenueCat's PurchaseController
        await MainActor.run {
            self.initializeSuperwall()
        }

        // Small yield to let UI breathe
        try? await Task.sleep(nanoseconds: 10_000_000) // 10ms

        // Adjust temporarily disabled
        // await MainActor.run {
        //     self.initializeAdjust()
        // }

        let sdkElapsed = (CFAbsoluteTimeGetCurrent() - startTime) * 1000
        print("[AppInit] 📦 SDKs initialized in \(String(format: "%.0f", sdkElapsed))ms")

        // Mark as initialized
        await MainActor.run {
            self.isInitialized = true
            self.isInitializing = false
        }

        let totalElapsed = (CFAbsoluteTimeGetCurrent() - startTime) * 1000
        print("[AppInit] ✅ Total initialization complete in \(String(format: "%.0f", totalElapsed))ms")
    }

    @MainActor
    private func initializeSuperwall() {
        let options = SuperwallOptions()

        // Configure logging - use .warn to reduce console noise
        options.logging.level = .warn
        options.logging.scopes = [.paywallPresentation]

        // Configure paywall behavior
        options.paywalls.shouldShowPurchaseFailureAlert = true
        options.paywalls.automaticallyDismiss = true

        // CRITICAL: Disable paywall preloading to prevent WebView spawning at launch
        // This was causing 5+ second delays with multiple WebContent processes
        // Paywalls will load on-demand when needed (slight delay but much faster launch)
        options.paywalls.shouldPreload = false

        // Use StoreKit 2 for better performance on iOS 15+
        options.storeKitVersion = .storeKit2

        // Configure Superwall with RevenueCat's PurchaseController
        // This routes all purchases through RevenueCat for subscription management
        Superwall.configure(
            apiKey: "pk_4zV7qoSvKMLgKN1Ou-bSX",
            purchaseController: RevenueCatManager.shared.purchaseController,
            options: options
        )

        // Complete SuperwallManager setup (sets delegate, user attributes)
        SuperwallManager.shared.completeSetup()

        // NOW start syncing RevenueCat status to Superwall (after both are configured)
        RevenueCatManager.shared.purchaseController.syncSubscriptionStatus()

        print("[AppInit] ✅ Superwall configured with RevenueCat PurchaseController")
    }

    // TODO: Enable Adjust later
    // Adjust temporarily disabled
    /*
    @MainActor
    private func initializeAdjust() {
        let appToken = "PLACEHOLDER_ADJUST_TOKEN"

        #if DEBUG
        let environment = ADJEnvironmentSandbox
        #else
        let environment = ADJEnvironmentProduction
        #endif

        let adjustConfig = ADJConfig(
            appToken: appToken,
            environment: environment
        )

        #if DEBUG
        adjustConfig?.logLevel = ADJLogLevel.verbose
        #else
        adjustConfig?.logLevel = ADJLogLevel.warn
        #endif

        Adjust.initSdk(adjustConfig)

        print("[AppInit] ✅ Adjust configured")
    }
    */
}
