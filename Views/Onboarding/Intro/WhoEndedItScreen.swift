//
//  WhoEndedItScreen.swift
//  Get Over Him
//
//  Single-select: Who ended the relationship?
//

import SwiftUI

struct WhoEndedItScreen: View {
    @EnvironmentObject var flowController: OnboardingFlowController
    @State private var selectedOption: String? = nil

    private let options = [
        ("him", "him"),
        ("me", "me"),
        ("mutual", "it was mutual"),
        ("complicated", "it's complicated")
    ]

    var body: some View {
        ZStack {
            OnboardingGradientBackground(style: .mochiWelcome, animated: true)

            OnboardingScrollableLayout(
                showBackButton: true,
                showContinueButton: selectedOption != nil,
                backgroundColor: .clear
            ) {
                VStack(alignment: .leading, spacing: 0) {
                    // Question
                    Text("who ended things?")
                        .font(.custom("Satoshi-Bold", size: 32))
                        .foregroundColor(Color(hex: "#4A2040"))
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.top, 20)
                        .padding(.horizontal, AppTheme.Spacing.lg)
                        .padding(.bottom, AppTheme.Spacing.xl)

                    // Options
                    VStack(spacing: 12) {
                        ForEach(options, id: \.0) { option in
                            SingleSelectOption(
                                title: option.1,
                                isSelected: selectedOption == option.0
                            ) {
                                let generator = UIImpactFeedbackGenerator(style: .light)
                                generator.impactOccurred()
                                selectedOption = option.0
                            }
                        }
                    }
                    .padding(.horizontal, AppTheme.Spacing.lg)

                    Spacer()
                }
            } continueAction: {
                flowController.saveData(for: "who_ended_it", data: [
                    "selected": selectedOption ?? "",
                    "timestamp": Date().timeIntervalSince1970
                ])
                flowController.navigateNext()
            }
        }
        .onAppear {
            if let data = flowController.getData(for: "who_ended_it"),
               let saved = data["selected"] as? String {
                selectedOption = saved
            }
        }
    }
}

// MARK: - Single Select Option

private struct SingleSelectOption: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
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

struct WhoEndedItScreen_Previews: PreviewProvider {
    static var previews: some View {
        WhoEndedItScreen()
            .environmentObject(OnboardingFlowController())
    }
}
