//
//  ProjectedLifetimeLossViewModel.swift
//  Checkpoint
//
//  ViewModel for ProjectedLifetimeLossScreen - handles lifetime loss calculation
//

import SwiftUI

@MainActor
class ProjectedLifetimeLossViewModel: ObservableObject {

    // MARK: - Published Properties

    @Published var displayedAmount: Int = 0
    @Published var showComparisons = false

    // MARK: - Private Properties

    var flowController: OnboardingFlowController?

    // MARK: - Computed Properties

    var projectedLifetimeLoss: Int {
        guard let flowController = flowController else { return 0 }
        // Get previously collected data
        let dailyBetCount = (flowController.getData(for: "daily_bet_count")?["daily_bet_count"] as? Int) ?? 5
        let averageBetAmount = (flowController.getData(for: "average_bet_amount")?["average_bet_amount"] as? Double) ?? 25.0
        let gamblingDays = (flowController.getData(for: "gambling_days")?["day_count"] as? Int) ?? 2
        let age = (flowController.getData(for: "age")?["age"] as? Int) ?? 30

        // Calculate yearly loss first
        let weeklyLoss = Double(dailyBetCount) * averageBetAmount * Double(gamblingDays)
        let annualLoss = weeklyLoss * 52.0

        // Calculate years left to live (assuming life expectancy of 80)
        let yearsRemaining = max(0, 80 - age)

        // Calculate lifetime loss
        let lifetimeLoss = annualLoss * Double(yearsRemaining)

        return Int(lifetimeLoss)
    }

    var newCars: Int {
        projectedLifetimeLoss / 35000 // Average new car price
    }

    var yearsOfRent: Int {
        projectedLifetimeLoss / 18000 // Annual rent ($1,500/month × 12)
    }

    var dreamVacations: Int {
        projectedLifetimeLoss / 5000 // Dream vacation to Europe/Asia
    }

    // MARK: - Public Methods

    func animateCounter() {
        let targetValue = projectedLifetimeLoss
        let animationDuration = 2.5

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
        flowController.saveData(for: "projected_lifetime_loss", data: ["projected_lifetime_loss": projectedLifetimeLoss])
        flowController.navigateNext()
    }
}
