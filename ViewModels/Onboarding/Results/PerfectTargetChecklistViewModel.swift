//
//  PerfectTargetChecklistViewModel.swift
//  Checkpoint
//
//  ViewModel for PerfectTargetChecklistScreen - builds trait checklist
//

import SwiftUI

@MainActor
class PerfectTargetChecklistViewModel: ObservableObject {

    // MARK: - Published Properties

    @Published var checkedItems: Set<String> = []
    @Published var showContinueButton: Bool = false
    @Published var targetTraits: [(id: String, text: String, applies: Bool)] = []

    // MARK: - Private Properties

    var flowController: OnboardingFlowController? {
        didSet {
            loadTargetTraits()
        }
    }

    // MARK: - Initialization

    init(flowController: OnboardingFlowController? = nil) {
        self.flowController = flowController
        if flowController != nil {
            loadTargetTraits()
        }
    }

    // MARK: - Private Methods

    private func loadTargetTraits() {
        guard let flowController = flowController else { return }
        var traits: [(id: String, text: String, applies: Bool)] = []

        // Smart/Educated
        traits.append((
            id: "smart",
            text: "Smart & educated",
            applies: true
        ))

        // Started young
        if let firstGambleAge = flowController.getData(for: "first_gamble_age")?["answer"] as? String,
           firstGambleAge == "Under 18" || firstGambleAge == "18-21" {
            traits.append((
                id: "young",
                text: "Started gambling young",
                applies: true
            ))
        }

        // Male demographic
        if let gender = flowController.getData(for: "gender")?["answer"] as? String,
           gender == "Male" {
            traits.append((
                id: "male",
                text: "Male",
                applies: true
            ))
        }

        // Chases losses
        if let chasesLosses = flowController.getData(for: "chases_losses")?["answer"] as? String,
           chasesLosses == "Yes" {
            traits.append((
                id: "chases",
                text: "Chases losses",
                applies: true
            ))
        }

        // Gambles alone
        if let withWho = flowController.getData(for: "with_who_gamble")?["answers"] as? [String],
           withWho.contains("Alone") {
            traits.append((
                id: "alone",
                text: "Gambles alone",
                applies: true
            ))
        }

        // Uses substances while gambling
        if let substances = flowController.getData(for: "uses_substances_while_gambling")?["answer"] as? String,
           substances == "Yes" {
            traits.append((
                id: "substances",
                text: "Has gambled while impaired",
                applies: true
            ))
        }

        // Feels guilty about gambling
        if let guilty = flowController.getData(for: "guilty_about_gambling")?["answer"] as? String,
           guilty == "Yes" {
            traits.append((
                id: "guilty",
                text: "Feels guilty about gambling",
                applies: true
            ))
        }

        // Gambles to escape problems
        if let escape = flowController.getData(for: "escape_gambling")?["answer"] as? String,
           escape == "Yes" {
            traits.append((
                id: "escape",
                text: "Uses gambling to escape",
                applies: true
            ))
        }

        // Uses deposit bonuses
        if let depositBonus = flowController.getData(for: "deposit_bonus")?["answer"] as? String,
           depositBonus == "Yes" {
            traits.append((
                id: "bonuses",
                text: "Tricked into deposit bonuses",
                applies: true
            ))
        }

        // Hides gambling from loved ones
        if let hides = flowController.getData(for: "hides_gambling")?["answer"] as? String,
           hides == "Yes" {
            traits.append((
                id: "hides",
                text: "Hides gambling from loved ones",
                applies: true
            ))
        }

        self.targetTraits = traits
    }

    // MARK: - Public Methods

    func animateCheckmarks() {
        let applicableTraits = targetTraits.filter { $0.applies }

        // Checkmarks start appearing after 0.5 seconds
        let checkmarkDelay = 0.5

        for (index, trait) in applicableTraits.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + checkmarkDelay + Double(index) * 0.3) {
                self.checkedItems.insert(trait.id)
                HapticUtility.impact(style: .light)
            }
        }

        // Show continue button after all checkmarks
        let totalDelay = checkmarkDelay + Double(applicableTraits.count) * 0.3 + 0.5
        DispatchQueue.main.asyncAfter(deadline: .now() + totalDelay) {
            self.showContinueButton = true
        }
    }

    func saveAndContinue() {
        guard let flowController = flowController else { return }
        let applicableTraitTexts = targetTraits.filter { $0.applies }.map { $0.text }
        flowController.saveData(for: "perfect_target_traits", data: [
            "traits": applicableTraitTexts,
            "trait_count": applicableTraitTexts.count
        ])
        flowController.navigateNext()
    }
}
