//
//  RCPurchaseController.swift
//  Checkpoint
//
//  PurchaseController implementation that routes Superwall purchases through RevenueCat
//

import Foundation
import SuperwallKit
import RevenueCat
import StoreKit

enum PurchasingError: LocalizedError {
    case sk2ProductNotFound
    case purchaseFailed(underlying: Error)

    var errorDescription: String? {
        switch self {
        case .sk2ProductNotFound:
            return "StoreKit 2 product not found"
        case .purchaseFailed(let error):
            return "Purchase failed: \(error.localizedDescription)"
        }
    }
}

final class RCPurchaseController: PurchaseController {

    // MARK: - Subscription Status Sync

    /// Start syncing RevenueCat subscription status to Superwall
    /// Call this AFTER both RevenueCat AND Superwall are configured
    func syncSubscriptionStatus() {
        Task {
            for await customerInfo in Purchases.shared.customerInfoStream {
                await updateSuperwallStatus(from: customerInfo)
            }
        }
    }

    /// Update Superwall's subscription status from RevenueCat customer info
    @MainActor
    private func updateSuperwallStatus(from customerInfo: RevenueCat.CustomerInfo) {
        print("[RevenueCat] 🔵 Customer info received:")
        print("[RevenueCat] 🔵   - App User ID: \(customerInfo.originalAppUserId)")
        print("[RevenueCat] 🔵   - All entitlements: \(customerInfo.entitlements.all.keys.joined(separator: ", "))")
        print("[RevenueCat] 🔵   - Active entitlements: \(customerInfo.entitlements.activeInCurrentEnvironment.keys.joined(separator: ", "))")

        let activeEntitlements = customerInfo.entitlements.activeInCurrentEnvironment

        if activeEntitlements.isEmpty {
            Superwall.shared.subscriptionStatus = .inactive
            print("[RevenueCat] ✅ Synced to Superwall: INACTIVE (no active entitlements)")
        } else {
            let entitlements = Set(activeEntitlements.keys.map { Entitlement(id: $0) })
            Superwall.shared.subscriptionStatus = .active(entitlements)
            print("[RevenueCat] ✅ Synced to Superwall: ACTIVE with \(entitlements.map { $0.id })")
        }
    }

    // MARK: - PurchaseController Protocol

    /// Handle purchases through RevenueCat
    func purchase(product: SuperwallKit.StoreProduct) async -> PurchaseResult {
        do {
            // Get the StoreKit 2 product from Superwall's StoreProduct
            guard let sk2Product = product.sk2Product else {
                print("[RevenueCat] ❌ No SK2 product available")
                throw PurchasingError.sk2ProductNotFound
            }

            // Convert to RevenueCat StoreProduct
            let rcProduct = RevenueCat.StoreProduct(sk2Product: sk2Product)

            print("[RevenueCat] 🛒 Starting purchase for: \(rcProduct.productIdentifier)")

            // Purchase through RevenueCat
            let result = try await Purchases.shared.purchase(product: rcProduct)

            if result.userCancelled {
                print("[RevenueCat] 👤 User cancelled purchase")
                return .cancelled
            }

            print("[RevenueCat] ✅ Purchase successful: \(rcProduct.productIdentifier)")
            return .purchased

        } catch let error as RevenueCat.ErrorCode {
            // Handle specific RevenueCat errors
            if error == .paymentPendingError {
                print("[RevenueCat] ⏳ Payment pending")
                return .pending
            }
            print("[RevenueCat] ❌ Purchase error: \(error)")
            return .failed(error)

        } catch {
            print("[RevenueCat] ❌ Purchase failed: \(error)")
            return .failed(error)
        }
    }

    /// Handle restore through RevenueCat
    func restorePurchases() async -> RestorationResult {
        do {
            print("[RevenueCat] 🔄 Restoring purchases...")
            let customerInfo = try await Purchases.shared.restorePurchases()

            let hasActiveEntitlements = !customerInfo.entitlements.activeInCurrentEnvironment.isEmpty

            if hasActiveEntitlements {
                print("[RevenueCat] ✅ Restore successful - active entitlements found")
                return .restored
            } else {
                print("[RevenueCat] ⚠️ Restore complete - no active entitlements")
                return .restored
            }

        } catch {
            print("[RevenueCat] ❌ Restore failed: \(error)")
            return .failed(error)
        }
    }
}
