//
//  ProjectedYearlyLossViewModel.swift
//  Checkpoint
//
//  ViewModel for ProjectedYearlyLossScreen - handles yearly loss calculation
//

import SwiftUI

@MainActor
class ProjectedYearlyLossViewModel: ObservableObject {

    // MARK: - Published Properties

    @Published var displayedAmount: Int = 0
    @Published var showComparisons = false
    @Published var fontSize: CGFloat = 64

    // MARK: - Private Properties

    var flowController: OnboardingFlowController?

    // MARK: - Computed Properties

    var projectedAnnualLoss: Int {
        guard let flowController = flowController else { return 0 }
        // Get previously collected data
        let dailyBetCount = (flowController.getData(for: "daily_bet_count")?["daily_bet_count"] as? Int) ?? 5
        let averageBetAmount = (flowController.getData(for: "average_bet_amount")?["average_bet_amount"] as? Double) ?? 25.0
        let gamblingDays = (flowController.getData(for: "gambling_days")?["day_count"] as? Int) ?? 2

        // Calculate: daily_bet_count × average_bet_amount × days_per_week × 52 weeks
        let weeklyLoss = Double(dailyBetCount) * averageBetAmount * Double(gamblingDays)
        let annualLoss = weeklyLoss * 52.0

        return Int(annualLoss)
    }

    var monthsOfRent: Int {
        projectedAnnualLoss / 1500 // Average monthly rent
    }

    var sportsTickets: Int {
        projectedAnnualLoss / 150 // Average sports game ticket
    }

    var gymMemberships: Int {
        projectedAnnualLoss / 600 // Annual gym membership
    }

    // MARK: - Public Methods

    func animateCounter() {
        let targetValue = projectedAnnualLoss
        let animationDuration = 2.0

        // Set font size based on target value
        fontSize = targetValue >= 1_000_000 ? 56 : 64

        HapticUtility.playContinuousHaptic(duration: animationDuration)

        let startTime = Date()
        Timer.scheduledTimer(withTimeInterval: 1.0/60.0, repeats: true) { timer in
            let elapsed = Date().timeIntervalSince(startTime)
            let progress = min(elapsed / animationDuration, 1.0)

            self.displayedAmount = Int(Double(targetValue) * progress)

            if progress >= 1.0 {
                timer.invalidate()
                self.displayedAmount = targetValue

                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    withAnimation {
                        self.showComparisons = true
                    }
                }
            }
        }
    }

    func saveAndContinue() {
        guard let flowController = flowController else { return }
        flowController.saveData(for: "projected_annual_loss", data: ["projected_annual_loss": projectedAnnualLoss])
        flowController.navigateNext()
    }
}
