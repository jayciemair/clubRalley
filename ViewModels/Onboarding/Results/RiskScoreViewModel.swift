//
//  RiskScoreViewModel.swift
//  Checkpoint
//
//  ViewModel for RiskScoreRevealScreen - handles risk score calculation
//

import SwiftUI

@MainActor
class RiskScoreViewModel: ObservableObject {

    // MARK: - Published Properties

    @Published var userBarHeight: CGFloat = 0
    @Published var averageBarHeight: CGFloat = 0
    @Published var showPercentages: Bool = false
    @Published var showMessage: Bool = false
    @Published var showContinueButton: Bool = false

    // MARK: - Private Properties

    var flowController: OnboardingFlowController? {
        didSet {
            // Clear cache when flowController changes
            _cachedRiskScore = nil
            _cachedRiskMultiplier = nil
        }
    }
    private let averageScore: Int = 15

    // Cache calculated values to avoid repeated computation
    private var _cachedRiskScore: Int?
    private var _cachedRiskMultiplier: Double?

    // MARK: - Initialization

    init(flowController: OnboardingFlowController? = nil) {
        self.flowController = flowController
    }

    // MARK: - Computed Properties

    var projectedLifetimeLoss: Double {
        guard let flowController = flowController else {
            return 0
        }

        let dailyBetData = flowController.getData(for: "daily_bet_count")
        let avgBetData = flowController.getData(for: "average_bet_amount")
        let gamblingDaysData = flowController.getData(for: "gambling_days")
        let ageData = flowController.getData(for: "age")

        let dailyBetCount = (dailyBetData?["daily_bet_count"] as? Int) ?? 5
        let averageBetAmount = (avgBetData?["average_bet_amount"] as? Double) ?? 25.0
        let gamblingDays = (gamblingDaysData?["day_count"] as? Int) ?? 2
        let age = (ageData?["age"] as? Int) ?? 30

        let weeklyLoss = Double(dailyBetCount) * averageBetAmount * Double(gamblingDays)
        let annualLoss = weeklyLoss * 52.0
        let yearsRemaining = max(0, 80 - age)
        let lifetimeLoss = annualLoss * Double(yearsRemaining)

        return lifetimeLoss
    }

    var riskScore: Int {
        // Return cached value if available
        if let cached = _cachedRiskScore {
            return cached
        }

        let lifetimeLoss = projectedLifetimeLoss

        // Extreme cases - financial projection is catastrophic
        let score: Int
        if lifetimeLoss > 5_000_000 {
            score = 90
        } else if lifetimeLoss > 1_000_000 {
            var tempScore = 75
            tempScore += calculateBehavioralScore()
            score = min(tempScore, 95)
        } else {
            // Normal calculation for non-extreme cases
            var tempScore = 20 // Base score
            tempScore += calculateBehavioralScore()

            // Financial factor - tiered for more reasonable amounts
            if lifetimeLoss > 500_000 {
                tempScore += 40
            } else if lifetimeLoss > 250_000 {
                tempScore += 35
            } else if lifetimeLoss > 100_000 {
                tempScore += 30
            } else if lifetimeLoss > 50_000 {
                tempScore += 20
            } else if lifetimeLoss > 25_000 {
                tempScore += 15
            } else {
                tempScore += 10
            }

            score = min(tempScore, 95)
        }

        _cachedRiskScore = score
        return score
    }

    var riskDifference: Int {
        riskScore - averageScore
    }

    var riskMultiplier: Double {
        // Return cached value if available
        if let cached = _cachedRiskMultiplier {
            return cached
        }

        guard averageScore > 0 else { return 1.0 }
        let multiplier = Double(riskScore) / Double(averageScore)
        _cachedRiskMultiplier = multiplier
        return multiplier
    }

    // MARK: - Public Methods

    func animateBars() {
        // Force cache clear before calculation
        _cachedRiskScore = nil
        _cachedRiskMultiplier = nil

        let calculatedScore = riskScore  // This will trigger the full calculation
        let calculatedMultiplier = riskMultiplier

        // Calculate bar heights (max 300pt)
        let userHeight = (CGFloat(calculatedScore) / 100.0) * 300
        let avgHeight = (CGFloat(averageScore) / 100.0) * 300

        // Animate bars climbing up
        withAnimation(.easeOut(duration: 1.5)) {
            userBarHeight = userHeight
            averageBarHeight = avgHeight
        }

        // Show percentages after bars finish
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            withAnimation(.easeIn(duration: 0.3)) {
                self.showPercentages = true
            }
        }

        // Show message last
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation(.easeIn(duration: 0.3)) {
                self.showMessage = true
            }
        }

        // Show continue button after message finishes appearing
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) {
            self.showContinueButton = true
        }
    }

    func saveAndContinue() {
        guard let flowController = flowController else { return }
        flowController.saveData(for: "risk_score", data: [
            "score": riskScore,
            "average": averageScore,
            "difference": riskDifference,
            "timestamp": Date().timeIntervalSince1970
        ])
        flowController.navigateNext()
    }

    // MARK: - Private Methods

    private func calculateBehavioralScore() -> Int {
        guard let flowController = flowController else {
            return 0
        }
        var behavioralScore = 0

        // Get quiz data
        let firstGambleAge = flowController.getData(for: "first_gamble_age")?["answer"] as? String
        let gender = flowController.getData(for: "gender")?["answer"] as? String
        let chasesLosses = flowController.getData(for: "chases_losses")?["answer"] as? String
        let withWhoGamble = flowController.getData(for: "with_who_gamble")?["answers"] as? [String]
        let hidesGambling = flowController.getData(for: "hides_gambling")?["answer"] as? String

        // Demographic factors
        if gender == "Male" {
            behavioralScore += 10
        }

        if firstGambleAge == "Under 18" {
            behavioralScore += 10
        } else if firstGambleAge == "18-21" {
            behavioralScore += 5
        }

        // Behavioral factors
        if chasesLosses == "Yes" {
            behavioralScore += 10
        }

        if let withWhoGamble = withWhoGamble, withWhoGamble.contains("Alone") {
            behavioralScore += 10
        }

        if hidesGambling == "Yes" {
            behavioralScore += 10
        }

        return behavioralScore
    }
}
