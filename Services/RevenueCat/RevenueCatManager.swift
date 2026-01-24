//
//  RevenueCatManager.swift
//  Checkpoint
//
//  Manages RevenueCat SDK integration for subscription management
//  Acts as the authoritative source of subscription truth
//

import Foundation
import RevenueCat
import Combine
import StoreKit

@MainActor
final class RevenueCatManager: NSObject, ObservableObject {

    // MARK: - Singleton

    static let shared = RevenueCatManager()

    // MARK: - Published Properties

    /// Current customer info from RevenueCat
    @Published private(set) var customerInfo: RevenueCat.CustomerInfo?

    /// Whether user has an active subscription
    @Published private(set) var hasActiveSubscription = false

    /// Whether user is currently in a trial period
    @Published private(set) var isInTrial = false

    /// Current subscription product ID (if any)
    @Published private(set) var activeProductId: String?

    /// Subscription expiration date (if any)
    @Published private(set) var expirationDate: Date?

    /// Whether the SDK has been initialized
    @Published private(set) var isInitialized = false

    // MARK: - PurchaseController for Superwall

    /// PurchaseController that routes Superwall purchases through RevenueCat
    let purchaseController = RCPurchaseController()

    // MARK: - Private Properties

    private var cancellables = Set<AnyCancellable>()
    private let lastKnownSubscriptionKey = "rc_lastKnownSubscriptionStatus"
    private let hasMigratedKey = "rc_hasMigratedExistingPurchases"

    // MARK: - Initialization

    private override init() {
        super.init()
        // Load cached status for offline support
        hasActiveSubscription = UserDefaults.standard.bool(forKey: lastKnownSubscriptionKey)
        print("[RevenueCat] 📦 Loaded cached subscription status: \(hasActiveSubscription)")
    }

    // MARK: - Configuration

    /// Configure RevenueCat SDK. Call this from AppInitializer BEFORE Superwall.
    func configure() {
        guard !isInitialized else {
            print("[RevenueCat] ⚠️ Already configured, skipping")
            return
        }

        // Set log level based on build configuration
        #if DEBUG
        Purchases.logLevel = .debug
        #else
        Purchases.logLevel = .warn
        #endif

        // Configure RevenueCat with API key
        let apiKey = AppConfig.RevenueCat.apiKey
        print("[RevenueCat] 🔵 Configuring with API key: \(apiKey.prefix(10))...")
        Purchases.configure(withAPIKey: apiKey)

        // Set up delegate for customer info updates
        Purchases.shared.delegate = self

        // Start listening for customer info stream
        setupCustomerInfoListener()

        // NOTE: syncSubscriptionStatus() is called from AppInitializer
        // AFTER Superwall is configured to avoid accessing Superwall.shared too early

        isInitialized = true
        print("[RevenueCat] ✅ Configured successfully with API key: \(apiKey.prefix(10))...")
        print("[RevenueCat] 🔵 App User ID: \(Purchases.shared.appUserID)")

        // Fetch initial customer info and migrate existing subscribers
        Task {
            await refreshCustomerInfo()
            await migrateExistingSubscribersIfNeeded()
        }
    }

    // MARK: - Migration for Existing Subscribers

    /// One-time migration: sync existing StoreKit purchases to RevenueCat
    /// This ensures users who subscribed before RevenueCat don't lose access
    private func migrateExistingSubscribersIfNeeded() async {
        print("[RevenueCat] 🔄 Checking for existing StoreKit subscriptions to migrate...")

        // Check if RevenueCat already knows about a subscription
        if hasActiveSubscription {
            print("[RevenueCat] ✅ RevenueCat already has active subscription")
            UserDefaults.standard.set(true, forKey: hasMigratedKey)
            return
        }

        // Check StoreKit directly for existing entitlements
        let hasStoreKitSubscription = await checkStoreKitEntitlements()

        if hasStoreKitSubscription {
            print("[RevenueCat] 🔄 Found StoreKit subscription - syncing to RevenueCat...")
            do {
                let customerInfo = try await Purchases.shared.syncPurchases()
                updateCustomerInfo(customerInfo)

                // Only mark as migrated if RevenueCat now recognizes the subscription
                if hasActiveSubscription {
                    print("[RevenueCat] ✅ Successfully migrated existing subscription!")
                    UserDefaults.standard.set(true, forKey: hasMigratedKey)
                } else {
                    print("[RevenueCat] ⚠️ Sync completed but subscription not recognized - will retry next launch")
                    // Don't mark as migrated - products may not be configured in dashboard yet
                }
            } catch {
                print("[RevenueCat] ❌ Migration sync failed: \(error)")
            }
        } else {
            print("[RevenueCat] ℹ️ No existing StoreKit subscription found")
            // No StoreKit subscription, so nothing to migrate
            UserDefaults.standard.set(true, forKey: hasMigratedKey)
        }
    }

    /// Check StoreKit directly for existing entitlements
    private func checkStoreKitEntitlements() async -> Bool {
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result {
                if transaction.revocationDate == nil {
                    print("[RevenueCat] 🔍 Found StoreKit entitlement: \(transaction.productID)")
                    return true
                }
            }
        }
        return false
    }

    // MARK: - User Identity

    /// Log in a user with their ID
    /// - Parameter userId: The user's unique identifier
    func login(userId: String) async throws {
        print("[RevenueCat] 👤 Logging in user: \(userId)")
        let (customerInfo, _) = try await Purchases.shared.logIn(userId)
        updateCustomerInfo(customerInfo)
    }

    /// Log out the current user
    func logout() async throws {
        print("[RevenueCat] 👤 Logging out user")
        let customerInfo = try await Purchases.shared.logOut()
        updateCustomerInfo(customerInfo)
    }

    // MARK: - Subscription Status

    /// Refresh customer info from RevenueCat
    func refreshCustomerInfo() async {
        do {
            let customerInfo = try await Purchases.shared.customerInfo()
            updateCustomerInfo(customerInfo)
        } catch {
            print("[RevenueCat] ❌ Failed to refresh customer info: \(error)")
        }
    }

    /// Check if user has an active subscription (sync method for quick checks)
    func checkSubscriptionStatus() -> Bool {
        return hasActiveSubscription
    }

    /// Get the premium entitlement if active
    var premiumEntitlement: EntitlementInfo? {
        return customerInfo?.entitlements[AppConfig.RevenueCat.premiumEntitlement]
    }

    // MARK: - Offerings

    /// Get current offerings from RevenueCat
    func getOfferings() async throws -> Offerings {
        return try await Purchases.shared.offerings()
    }

    /// Get a specific package from offerings
    func getPackage(identifier: String) async throws -> Package? {
        let offerings = try await getOfferings()
        return offerings.current?.package(identifier: identifier)
    }

    // MARK: - Private Methods

    private func setupCustomerInfoListener() {
        Task {
            for await customerInfo in Purchases.shared.customerInfoStream {
                await MainActor.run {
                    self.updateCustomerInfo(customerInfo)
                }
            }
        }
    }

    private func updateCustomerInfo(_ info: RevenueCat.CustomerInfo) {
        self.customerInfo = info

        // Check premium entitlement
        let entitlement = info.entitlements[AppConfig.RevenueCat.premiumEntitlement]
        let hasActive = entitlement?.isActive ?? false
        let inTrial = entitlement?.periodType == .trial

        // Update published properties
        self.hasActiveSubscription = hasActive
        self.isInTrial = inTrial
        self.activeProductId = entitlement?.productIdentifier
        self.expirationDate = entitlement?.expirationDate

        // Cache for offline support
        UserDefaults.standard.set(hasActive, forKey: lastKnownSubscriptionKey)

        print("[RevenueCat] 🔄 Customer info updated:")
        print("[RevenueCat]    - Active: \(hasActive)")
        print("[RevenueCat]    - Trial: \(inTrial)")
        print("[RevenueCat]    - Product: \(activeProductId ?? "none")")
        print("[RevenueCat]    - Expires: \(expirationDate?.description ?? "none")")
    }
}

// MARK: - PurchasesDelegate

extension RevenueCatManager: PurchasesDelegate {
    nonisolated func purchases(_ purchases: Purchases, receivedUpdated customerInfo: RevenueCat.CustomerInfo) {
        Task { @MainActor in
            self.updateCustomerInfo(customerInfo)
        }
    }
}
