//
//  HealingTimelineScreen.swift
//  Get Over Him
// d
//  Shows the research-backed timeline - clean, research-focused design
//

import SwiftUI

struct HealingTimelineScreen: View {
    @EnvironmentObject var flowController: OnboardingFlowController

    @State private var showContent: Bool = false
    @State private var showNumber: Bool = false
    @State private var showSubtext: Bool = false
    @State private var showSource: Bool = false
    @State private var showButton: Bool = false

    var body: some View {
        ZStack {
            // Pink rose gradient - different from mochiWelcome
            OnboardingGradientBackground(style: .roseGlow, animated: true)

            OnboardingScrollableLayout(
                showBackButton: true,
                showContinueButton: showButton,
                backgroundColor: .clear
            ) {
                VStack(spacing: 0) {
                    Spacer()
                        .frame(height: 80)

                    // Header text
                    if showContent {
                        Text("research shows it takes\nmost people about...")
                            .font(.custom("Satoshi-Medium", size: 22))
                            .foregroundColor(Color(hex: "#4A2040"))
                            .multilineTextAlignment(.center)
                            .transition(.opacity.combined(with: .move(edge: .bottom)))
                    }

                    Spacer()
                        .frame(height: 40)

                    // Big number
                    if showNumber {
                        VStack(spacing: 8) {
                            Text("77.7")
                                .font(.custom("Satoshi-Black", size: 120))
                                .foregroundColor(Color(hex: "#4A2040"))
                                .shadow(color: Color(hex: "#4A2040").opacity(0.2), radius: 10, x: 0, y: 4)

                            Text("days")
                                .font(.custom("Satoshi-Bold", size: 32))
                                .foregroundColor(Color(hex: "#4A2040").opacity(0.85))
                        }
                        .transition(.scale.combined(with: .opacity))
                    }

                    Spacer()
                        .frame(height: 40)

                    // Subtext
                    if showSubtext {
                        Text("to get over a breakup")
                            .font(.custom("Satoshi-Medium", size: 20))
                            .foregroundColor(Color(hex: "#4A2040"))
                            .multilineTextAlignment(.center)
                            .transition(.opacity)
                    }

                    Spacer()
                        .frame(height: 24)

                    // Promise text
                    if showSource {
                        VStack(spacing: 16) {
                            Text("with daily support, we'll\nget you there faster")
                                .font(.custom("Satoshi-Medium", size: 18))
                                .foregroundColor(Color(hex: "#6A3060").opacity(0.85))
                                .multilineTextAlignment(.center)

                            // Source citation - tappable
                            Button(action: {
                                // Link to the actual study
                                if let url = URL(string: "https://www.tandfonline.com/doi/abs/10.1080/87568225.2011.605693?journalCode=wcsp20") {
                                    UIApplication.shared.open(url)
                                }
                            }) {
                                HStack(spacing: 4) {
                                    Image(systemName: "doc.text")
                                        .font(.system(size: 12))
                                    Text("Journal of Positive Psychology")
                                        .font(.custom("Satoshi-Regular", size: 13))
                                        .underline()
                                }
                                .foregroundColor(Color(hex: "#6A3060").opacity(0.7))
                            }
                        }
                        .transition(.opacity)
                    }

                    Spacer()
                }
                .padding(.horizontal, 24)
            } continueAction: {
                flowController.saveData(for: "healing_timeline", data: [
                    "viewed": true,
                    "timestamp": Date().timeIntervalSince1970
                ])
                flowController.navigateNext()
            }
        }
        .onAppear {
            animateIn()
        }
    }

    private func animateIn() {
        // Staggered animations - slower pacing
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation(.easeOut(duration: 0.8)) {
                showContent = true
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
            withAnimation(.spring(response: 0.8, dampingFraction: 0.75)) {
                showNumber = true
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 3.2) {
            withAnimation(.easeOut(duration: 0.6)) {
                showSubtext = true
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 4.2) {
            withAnimation(.easeOut(duration: 0.6)) {
                showSource = true
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 5.2) {
            withAnimation(.easeOut(duration: 0.5)) {
                showButton = true
            }
        }
    }
}

struct HealingTimelineScreen_Previews: PreviewProvider {
    static var previews: some View {
        HealingTimelineScreen()
            .environmentObject(OnboardingFlowController())
    }
}
