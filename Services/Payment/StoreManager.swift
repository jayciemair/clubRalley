//
//  StoreManager.swift
//  Checkpoint
//
//  Handles In-App Purchases and subscription management
//  Subscription status is now managed by RevenueCat (authoritative source)
//

import Foundation
import StoreKit
import Combine

@MainActor
final class StoreManager: NSObject, ObservableObject {
    static let shared = StoreManager()

    // MARK: - Product IDs
    // These must match exactly what's configured in App Store Connect
    private let productIDs = [
        "com.checkpointapp.ios.Checkpoint.weekly",        // Weekly subscription
        "com.checkpointapp.ios.Checkpoint.monthly",       // Monthly subscription
        "com.checkpointapp.ios.Checkpoint.annual",        // Annual subscription
        "com.checkpointapp.ios.Checkpoint.annualDiscount" // Discounted annual
    ]

    // MARK: - Published Properties
    @Published var products: [StoreKit.Product] = []
    @Published var purchasedSubscriptions: Set<String> = []
    @Published var isLoading = false
    @Published var purchaseError: String?
    @Published var hasCompletedInitialLoad = false

    /// Subscription status forwarded from RevenueCat (the authoritative source)
    var hasActiveSubscription: Bool {
        RevenueCatManager.shared.hasActiveSubscription
    }

    // MARK: - Transaction Listener
    private var updateListenerTask: Task<Void, Error>?

    private var cancellables = Set<AnyCancellable>()

    private override init() {
        super.init()

        // Start transaction listener for logging/analytics
        updateListenerTask = listenForTransactions()

        // Defer product loading - use Combine to wait for AppInitializer
        setupInitializationObserver()

        // Observe RevenueCat subscription changes
        setupRevenueCatObserver()
    }

    /// Wait for AppInitializer using Combine instead of polling
    private func setupInitializationObserver() {
        AppInitializer.shared.$isInitialized
            .filter { $0 == true }
            .first()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                Task { @MainActor in
                    await self?.completeInitialization()
                }
            }
            .store(in: &cancellables)
    }

    /// Observe RevenueCat subscription status changes
    private func setupRevenueCatObserver() {
        RevenueCatManager.shared.$hasActiveSubscription
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isActive in
                // Notify observers that subscription status changed
                self?.objectWillChange.send()
                print("[StoreManager] 🔄 RevenueCat subscription update: \(isActive)")
            }
            .store(in: &cancellables)
    }

    private func completeInitialization() async {
        print("[StoreManager] 💳 AppInitializer ready, completing setup...")

        // Load products for display purposes
        await loadProducts()

        // Check current entitlements from StoreKit (for logging/analytics)
        await updatePurchasedProducts()

        // Mark initial load complete
        self.hasCompletedInitialLoad = true
        print("[StoreManager] 💳 Initial load COMPLETE - hasActiveSubscription=\(hasActiveSubscription)")
    }

    deinit {
        updateListenerTask?.cancel()
    }

    // MARK: - Load Products

    func loadProducts() async {
        isLoading = true
        defer { isLoading = false }

        do {
            products = try await StoreKit.Product.products(for: productIDs)
        } catch {
            purchaseError = "Failed to load products"

            // Log error to Supabase
            if let session = AuthenticationService.shared.currentSession,
               let userId = UUID(uuidString: session.userId) {
                await ErrorLoggingService.shared.logError(
                    userId: userId,
                    type: .paymentInitializationFailed,
                    error: error,
                    context: ["operation": "load_products"]
                )
            }
        }
    }

    // MARK: - Purchase

    func purchase(_ product: StoreKit.Product) async throws -> Transaction? {
        let result = try await product.purchase()

        switch result {
        case .success(let verification):
            // Check if transaction is verified
            let transaction: Transaction = try checkVerified(verification)

            // Update purchased products
            await updatePurchasedProducts()

            // Always finish transaction
            await transaction.finish()

            return transaction

        case .userCancelled:
            return nil

        case .pending:
            return nil

        @unknown default:
            return nil
        }
    }

    // MARK: - Restore Purchases

    func restorePurchases() async {
        // This will trigger the transaction listener
        try? await AppStore.sync()

        // Update purchased products
        await updatePurchasedProducts()
    }

    // MARK: - Check Subscription Status

    /// Check subscription status using RevenueCat as the authoritative source
    func checkSubscriptionStatus() async -> Bool {
        // RevenueCat is now the authoritative source
        await RevenueCatManager.shared.refreshCustomerInfo()
        return RevenueCatManager.shared.hasActiveSubscription
    }

    // MARK: - Private Methods

    private func listenForTransactions() -> Task<Void, Error> {
        return Task.detached {
            // Listen for transactions
            for await result in Transaction.updates {
                do {
                    let transaction = try await self.checkVerified(result)

                    // Update purchased products on main thread
                    await MainActor.run {
                        Task {
                            await self.updatePurchasedProducts()
                        }
                    }

                    // Always finish transactions
                    await transaction.finish()
                } catch {
                    // Log error to Supabase
                    if let session = await AuthenticationService.shared.currentSession,
                       let userId = UUID(uuidString: session.userId) {
                        await ErrorLoggingService.shared.logError(
                            userId: userId,
                            type: .paymentPurchaseFailed,
                            error: error,
                            context: ["operation": "transaction_listener"]
                        )
                    }
                }
            }
        }
    }

    private func updatePurchasedProducts() async {
        var purchased: Set<String> = []

        // Check all current entitlements from StoreKit (for logging/analytics)
        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result else {
                continue
            }

            // Check if transaction is not revoked
            if transaction.revocationDate == nil {
                purchased.insert(transaction.productID)
            }
        }

        self.purchasedSubscriptions = purchased
        print("[StoreManager] 🔍 StoreKit entitlements: \(purchased)")

        // Note: Subscription status sync to Superwall is now handled by
        // RevenueCat's PurchaseController (RCPurchaseController.syncSubscriptionStatus)
    }

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw StoreError.failedVerification
        case .verified(let safe):
            return safe
        }
    }

}

// MARK: - Store Errors

enum StoreError: Error {
    case failedVerification
    case productNotFound
}

// MARK: - Product Extensions

extension StoreKit.Product {
    var formattedPrice: String {
        // StoreKit 2 already provides a formatted price
        return displayPrice
    }

    var subscriptionPeriodText: String {
        guard let period = subscription?.subscriptionPeriod else { return "" }

        switch period.unit {
        case .day:
            return period.value == 1 ? "daily" : "every \(period.value) days"
        case .week:
            return period.value == 1 ? "weekly" : "every \(period.value) weeks"
        case .month:
            return period.value == 1 ? "monthly" : "every \(period.value) months"
        case .year:
            return period.value == 1 ? "annually" : "every \(period.value) years"
        @unknown default:
            return ""
        }
    }
}