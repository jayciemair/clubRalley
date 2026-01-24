//
//  BreakupTimingScreen.swift
//  Get Over Him
//
//  Asks how long since the breakup
//

import SwiftUI

struct BreakupTimingScreen: View {
    @EnvironmentObject var flowController: OnboardingFlowController
    @State private var selectedOption: String? = nil
    @State private var hasInteracted: Bool = false

    private let options = [
        ("just_happened", "just happened", "0-2 weeks"),
        ("still_fresh", "still fresh", "2-4 weeks"),
        ("a_little_while", "a little while", "1-3 months"),
        ("longer", "longer than i'd like to admit", "3+ months")
    ]

    var body: some View {
        ZStack {
            OnboardingGradientBackground(style: .mochiWelcome, animated: true)

            OnboardingScrollableLayout(
                showBackButton: true,
                showContinueButton: hasInteracted,
                backgroundColor: .clear
            ) {
                VStack(alignment: .leading, spacing: 0) {
                    // Question
                    VStack(alignment: .center, spacing: AppTheme.Spacing.md) {
                        Text("how long has it been since you last talked?")
                            .font(.custom("Satoshi-Bold", size: 32))
                            .foregroundColor(Color(hex: "#4A2040"))
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
                            .frame(maxWidth: .infinity)
                    }
                    .padding(.top, 20)
                    .padding(.horizontal, AppTheme.Spacing.lg)
                    .padding(.bottom, AppTheme.Spacing.lg)

                    // Options
                    VStack(spacing: AppTheme.Spacing.md) {
                        ForEach(options, id: \.0) { option in
                            BreakupTimingOption(
                                id: option.0,
                                title: option.1,
                                subtitle: option.2,
                                isSelected: selectedOption == option.0
                            ) {
                                let generator = UIImpactFeedbackGenerator(style: .medium)
                                generator.impactOccurred()
                                selectedOption = option.0
                                hasInteracted = true
                            }
                        }
                    }
                    .padding(.horizontal, AppTheme.Spacing.lg)

                    Spacer()
                }
            } continueAction: {
                guard let option = selectedOption else { return }

                flowController.saveData(for: "breakup_timing", data: [
                    "timing": option,
                    "timestamp": Date().timeIntervalSince1970
                ])

                flowController.navigateNext()
            }
        }
        .onAppear {
            // Restore saved data if exists
            if let data = flowController.getData(for: "breakup_timing"),
               let timing = data["timing"] as? String {
                selectedOption = timing
                hasInteracted = true
            }
        }
    }
}

// MARK: - Breakup Timing Option Component

private struct BreakupTimingOption: View {
    let id: String
    let title: String
    let subtitle: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.custom("Satoshi-Bold", size: 20))
                    .foregroundColor(Color(hex: "#4A2040"))

                Text(subtitle)
                    .font(.custom("Satoshi-Regular", size: 15))
                    .foregroundColor(Color(hex: "#6A3060").opacity(0.7))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 20)
            .padding(.vertical, 18)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(isSelected ? Color(hex: "#E080C0").opacity(0.15) : Color.white.opacity(0.5))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(isSelected ? Color(hex: "#E080C0").opacity(0.5) : Color.white.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct BreakupTimingScreen_Previews: PreviewProvider {
    static var previews: some View {
        BreakupTimingScreen()
            .environmentObject(OnboardingFlowController())
    }
}
