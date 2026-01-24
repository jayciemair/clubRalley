//
//  FrozenAnalyticsBannerViewModel.swift
//  Checkpoint
//
//  ViewModel for FrozenAnalyticsBanner
//

import SwiftUI
import Combine
import SuperwallKit

@MainActor
class FrozenAnalyticsBannerViewModel: ObservableObject {

    // MARK: - Published Properties

    @Published var isLoadingPaywallData = false
    @Published var projectedLifetimeLoss: Int?
    @Published var projectedAnnualLoss: Int?

    // MARK: - Private Properties

    private let authService = AuthenticationService.shared
    private let supabase = SupabaseClientManager.shared

    // MARK: - Public Methods

    /// Fetch projected lifetime loss and trigger paywall
    func showPaywall() async {
        isLoadingPaywallData = true
        await fetchProjectedLifetimeLoss()
        isLoadingPaywallData = false

        // Update Superwall with projected loss
        if let projectedLoss = projectedLifetimeLoss {
            SuperwallManager.shared.updateProjectedLoss(
                projectedLoss,
                projectedAnnualLoss: projectedAnnualLoss ?? 10000
            )
        }

        // Use win-back placement for lapsed subscribers (no trial offered)
        Superwall.shared.register(
            placement: SuperwallPlacements.winBack,
            params: [
                SuperwallPlacementParams.source: "analytics_frozen_banner",
                SuperwallPlacementParams.projectedLoss: projectedLifetimeLoss ?? 500000
            ]
        )
    }

    // MARK: - Private Methods

    private func fetchProjectedLifetimeLoss() async {
        guard let session = authService.currentSession,
              let userId = UUID(uuidString: session.userId) else {
            projectedLifetimeLoss = 500000
            return
        }

        do {
            // Query the gambling_profiles table
            struct GamblingProfileQuery: Decodable {
                let projected_lifetime_loss: Decimal?
                let projected_annual_loss: Decimal?
            }

            let response: GamblingProfileQuery = try await supabase.database
                .from("gambling_profiles")
                .select("projected_lifetime_loss, projected_annual_loss")
                .eq("user_id", value: userId.uuidString)
                .single()
                .execute()
                .value

            if let lifetimeLoss = response.projected_lifetime_loss {
                let lossInt = Int(truncating: lifetimeLoss as NSDecimalNumber)
                projectedLifetimeLoss = lossInt
            } else {
                projectedLifetimeLoss = 500000
            }

            if let annualLoss = response.projected_annual_loss {
                let lossInt = Int(truncating: annualLoss as NSDecimalNumber)
                projectedAnnualLoss = lossInt
            } else {
                projectedAnnualLoss = 10000
            }
        } catch {
            projectedLifetimeLoss = 500000
            projectedAnnualLoss = 10000
        }
    }
}
