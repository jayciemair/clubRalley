//
//  QuitDateRevealViewModel.swift
//  Checkpoint
//
//  ViewModel for QuitDateRevealScreen - handles Superwall campaign setup
//

import SwiftUI
import SuperwallKit

@MainActor
class QuitDateRevealViewModel: ObservableObject {

    // MARK: - Published Properties

    @Published var showHeader: Bool = false
    @Published var showContent: Bool = false
    @Published var showContinue: Bool = false
    @Published var hasTriggeredPaywall: Bool = false

    // MARK: - Private Properties

    var flowController: OnboardingFlowController?

    // MARK: - Computed Properties

    var quitDate: Date {
        guard let lastContactDate = getLastGambleDate() else {
            // Fallback to today + 78 if no start date found
            return Calendar.current.date(byAdding: .day, value: 78, to: Date()) ?? Date()
        }
        return Calendar.current.date(byAdding: .day, value: 78, to: lastContactDate) ?? Date()
    }

    var streakStartedAt: Date? {
        return getLastGambleDate()
    }

    // MARK: - Public Methods

    func animateEntrance() {
        let generator = UIImpactFeedbackGenerator(style: .heavy)

        // Show header first ("We built you a custom plan")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.showHeader = true
            generator.impactOccurred()
        }

        // Show carousel content + subtitle after longer pause
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.3) {
            self.showContent = true
            generator.impactOccurred()
        }

        // Show continue button
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.showContinue = true
            generator.impactOccurred()
        }
    }

    func handleContinue() {
        guard let flowController = flowController else { return }

        // Save that they viewed this screen
        flowController.saveData(for: "quit_date_reveal", data: [
            "viewed": true,
            "quit_date": quitDate.timeIntervalSince1970,
            "timestamp": Date().timeIntervalSince1970
        ])

        hasTriggeredPaywall = true

        // Get user data for campaign targeting
        let projectedLoss = getProjectedLoss()
        let projectedAnnualLoss = getProjectedAnnualLoss()
        let userAge = getUserAge()
        let riskScore = getRiskScore()
        let userGoal = getUserGoal()
        let gender = getGender()
        let weeklySavings = getWeeklySavings()
        let dailyBetAmount = getDailyBetAmount()

        // Configure Superwall attributes first
        configureSuperwallForPaywall(
            projectedLoss: projectedLoss,
            projectedAnnualLoss: projectedAnnualLoss,
            userAge: userAge,
            riskScore: riskScore,
            userGoal: userGoal,
            gender: gender,
            weeklySavings: weeklySavings,
            dailyBetAmount: dailyBetAmount
        )

        // Use specific placement for age-based targeting
        let placement = SuperwallPlacements.onboardingAge(for: userAge)
        let params: [String: Any] = [
            SuperwallPlacementParams.source: "quit_date_reveal",
            SuperwallPlacementParams.tier: "tier_78_days",
            SuperwallPlacementParams.daysToQuit: 78,
            SuperwallPlacementParams.projectedLoss: projectedLoss
        ]

        // DEBUG: Print subscription status before showing paywall
        print("[Superwall] 🎯 Attempting to show paywall: \(placement)")
        SuperwallManager.shared.debugPrintSubscriptionStatus()

        // Set callbacks for purchase/dismiss
        print("[Superwall] 📝 BEFORE setting onPurchaseComplete callback")
        print("[Superwall] 📝 Current onPurchaseComplete is: \(SuperwallManager.shared.onPurchaseComplete == nil ? "nil" : "set")")
        SuperwallManager.shared.onPurchaseComplete = { [weak self] in
            print("[Superwall] 🎉🎉🎉 onPurchaseComplete callback TRIGGERED! 🎉🎉🎉")
            print("[Superwall] 🎉 self is: \(self == nil ? "nil (WEAK REFERENCE LOST)" : "valid")")
            print("[Superwall] 🎉 flowController is: \(self?.flowController == nil ? "nil" : "valid")")
            print("[Superwall] 🎉 About to call navigateNext()...")
            self?.flowController?.navigateNext()
            print("[Superwall] 🎉 navigateNext() called!")
        }
        print("[Superwall] 📝 AFTER setting onPurchaseComplete callback")
        print("[Superwall] 📝 New onPurchaseComplete is: \(SuperwallManager.shared.onPurchaseComplete == nil ? "nil" : "set")")

        print("[Superwall] 📝 BEFORE setting onPaywallDismissed callback")
        SuperwallManager.shared.onPaywallDismissed = { [weak self] in
            print("[Superwall] 👋👋👋 onPaywallDismissed callback TRIGGERED 👋👋👋")
            self?.hasTriggeredPaywall = false
            // Trigger abandon recovery after dismiss
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                print("[Superwall] 🔄 Attempting to register transaction_abandon placement")
                Superwall.shared.register(
                    placement: SuperwallPlacements.transactionAbandonDiscount,
                    params: [
                        SuperwallPlacementParams.originalPlacement: placement,
                        SuperwallPlacementParams.attemptCount: 1
                    ]
                )
            }
        }
        print("[Superwall] 📝 AFTER setting onPaywallDismissed callback")

        // Simple register call - no complex handlers
        print("[Superwall] 🚀 Registering placement: \(placement)")
        Superwall.shared.register(placement: placement, params: params)
        print("[Superwall] ✓ Placement registered, waiting for events...")
    }

    // MARK: - Private Methods

    private func getProjectedLoss() -> Int {
        guard let flowController = flowController else { return 500000 }
        if let flowData = flowController.getData(for: "projected_lifetime_loss")?["projected_lifetime_loss"] as? Int {
            return flowData
        }
        return 500000 // Fallback
    }

    private func getProjectedAnnualLoss() -> Int {
        guard let flowController = flowController else { return 10000 }
        if let flowData = flowController.getData(for: "projected_annual_loss")?["projected_annual_loss"] as? Int {
            return flowData
        }
        return 10000 // Fallback
    }

    private func getUserAge() -> Int {
        guard let flowController = flowController else { return 25 }
        return flowController.getData(for: "age")?["age"] as? Int ?? 25
    }

    private func getRiskScore() -> Int {
        guard let flowController = flowController else { return 0 }
        return flowController.getData(for: "risk_score")?["score"] as? Int ?? 0
    }

    private func getUserGoal() -> String {
        guard let flowController = flowController else { return "unknown" }
        return flowController.getData(for: "user_goal")?["user_goal"] as? String ?? "unknown"
    }

    private func getGender() -> String {
        guard let flowController = flowController else { return "unknown" }
        return flowController.getData(for: "gender")?["answer"] as? String ?? "unknown"
    }

    private func getWeeklySavings() -> Int {
        guard let flowController = flowController else { return 0 }
        let dailyBetCount = (flowController.getData(for: "daily_bet_count")?["daily_bet_count"] as? Int) ?? 5
        let averageBetAmount = (flowController.getData(for: "average_bet_amount")?["average_bet_amount"] as? Double) ?? 25.0
        let gamblingDays = (flowController.getData(for: "gambling_days")?["day_count"] as? Int) ?? 2

        // Weekly savings = daily bets × average bet × days per week
        return Int(Double(dailyBetCount) * averageBetAmount * Double(gamblingDays))
    }

    private func getDailyBetAmount() -> Int {
        guard let flowController = flowController else { return 0 }
        let dailyBetCount = (flowController.getData(for: "daily_bet_count")?["daily_bet_count"] as? Int) ?? 5
        let averageBetAmount = (flowController.getData(for: "average_bet_amount")?["average_bet_amount"] as? Double) ?? 25.0

        // Daily bet amount = daily bets × average bet
        return Int(Double(dailyBetCount) * averageBetAmount)
    }

    private func getLastGambleDate() -> Date? {
        guard let flowController = flowController else { return nil }
        guard let timestamp = flowController.getData(for: "last_gamble_date")?["last_gamble_date"] as? TimeInterval else {
            return nil
        }
        return Date(timeIntervalSince1970: timestamp)
    }

    private func configureSuperwallForPaywall(
        projectedLoss: Int,
        projectedAnnualLoss: Int,
        userAge: Int,
        riskScore: Int,
        userGoal: String,
        gender: String,
        weeklySavings: Int,
        dailyBetAmount: Int
    ) {
        // Set all user attributes for campaign targeting
        let userAttributes: [String: Any] = [
            SuperwallPlacementParams.userAge: userAge,
            SuperwallPlacementParams.projectedLoss: projectedLoss,
            SuperwallPlacementParams.riskScore: riskScore,
            SuperwallPlacementParams.gender: gender,
            SuperwallPlacementParams.userGoal: userGoal
        ]

        // Update Superwall with user attributes for campaign rules
        Superwall.shared.setUserAttributes(userAttributes)

        // Update projected loss formatting for paywall display (includes weekly savings and daily bet amount)
        SuperwallManager.shared.updateProjectedLoss(
            projectedLoss,
            projectedAnnualLoss: projectedAnnualLoss,
            weeklySavings: weeklySavings,
            dailyBetAmount: dailyBetAmount
        )
    }
}
