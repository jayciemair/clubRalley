//
//  MainGoalsScreen.swift
//  Club Ralley
//
//  Multi-select: What are your main goals?
//

import SwiftUI

struct MainGoalsScreen: View {
    @EnvironmentObject var flowController: OnboardingFlowController
    @State private var selectedOptions: Set<String> = []

    private let options = [
        ("heal_move_on", "heal & move on"),
        ("protect_peace", "protect my peace"),
        ("stop_stalking", "stop checking his socials"),
        ("break_attachment", "break the attachment"),
        ("focus_myself", "focus on myself"),
        ("feel_better", "just feel better")
    ]

    var body: some View {
        ZStack {
            OnboardingGradientBackground(style: .mochiWelcome, animated: true)

            OnboardingScrollableLayout(
                showBackButton: true,
                showContinueButton: !selectedOptions.isEmpty,
                backgroundColor: .clear
            ) {
                VStack(alignment: .leading, spacing: 0) {
                    // Question
                    Text("what are your main goals?")
                        .font(.custom("Satoshi-Bold", size: 32))
                        .foregroundColor(Color(hex: "#4A2040"))
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.top, 20)
                        .padding(.horizontal, AppTheme.Spacing.lg)

                    Text("select all that apply")
                        .font(.custom("Satoshi-Regular", size: 16))
                        .foregroundColor(Color(hex: "#6A3060").opacity(0.7))
                        .padding(.top, 8)
                        .padding(.horizontal, AppTheme.Spacing.lg)
                        .padding(.bottom, AppTheme.Spacing.lg)

                    // Options
                    VStack(spacing: 12) {
                        ForEach(options, id: \.0) { option in
                            MultiSelectOption(
                                id: option.0,
                                title: option.1,
                                isSelected: selectedOptions.contains(option.0)
                            ) {
                                let generator = UIImpactFeedbackGenerator(style: .light)
                                generator.impactOccurred()

                                if selectedOptions.contains(option.0) {
                                    selectedOptions.remove(option.0)
                                } else {
                                    selectedOptions.insert(option.0)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, AppTheme.Spacing.lg)

                    Spacer()
                }
            } continueAction: {
                flowController.saveData(for: "main_goals", data: [
                    "selected": Array(selectedOptions),
                    "timestamp": Date().timeIntervalSince1970
                ])
                flowController.navigateNext()
            }
        }
        .onAppear {
            if let data = flowController.getData(for: "main_goals"),
               let saved = data["selected"] as? [String] {
                selectedOptions = Set(saved)
            }
        }
    }
}

// MARK: - Multi Select Option

private struct MultiSelectOption: View {
    let id: String
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                // Checkbox
                ZStack {
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(isSelected ? Color(hex: "#E080C0") : Color(hex: "#6A3060").opacity(0.3), lineWidth: 2)
                        .frame(width: 24, height: 24)

                    if isSelected {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color(hex: "#E080C0"))
                            .frame(width: 24, height: 24)

                        Image(systemName: "checkmark")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                    }
                }

                Text(title)
                    .font(.custom("Satoshi-Medium", size: 18))
                    .foregroundColor(Color(hex: "#4A2040"))
                    .multilineTextAlignment(.leading)

                Spacer()
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? Color(hex: "#E080C0").opacity(0.15) : Color.white.opacity(0.5))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? Color(hex: "#E080C0").opacity(0.5) : Color.white.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct MainGoalsScreen_Previews: PreviewProvider {
    static var previews: some View {
        MainGoalsScreen()
            .environmentObject(OnboardingFlowController())
    }
}
