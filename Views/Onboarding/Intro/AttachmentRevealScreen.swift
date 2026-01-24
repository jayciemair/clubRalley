//
//  AttachmentRevealScreen.swift
//  Get Over Him
//
//  Shows user's emotional attachment level - compassionate framing
//

import SwiftUI

struct AttachmentRevealScreen: View {
    @EnvironmentObject var flowController: OnboardingFlowController

    @State private var userBarHeight: CGFloat = 0
    @State private var averageBarHeight: CGFloat = 0
    @State private var showPercentages: Bool = false
    @State private var showMessage: Bool = false
    @State private var showContinueButton: Bool = false

    // Calculate attachment score based on their answers
    // Range: 65 (minimum) to 96 (maximum)
    private var attachmentScore: Int {
        // Base score - calculated so minimum selections = 65
        var score = 61

        // From whats_hurting - each selection adds 2 points (max +12)
        if let data = flowController.getData(for: "whats_hurting"),
           let selected = data["selected"] as? [String] {
            score += min(selected.count * 2, 12)
        }

        // From how_coping - each selection adds 2 points (max +12)
        if let data = flowController.getData(for: "how_coping"),
           let selected = data["selected"] as? [String] {
            score += min(selected.count * 2, 12)
        }

        // From breakup_timing - more recent = higher score (max +11)
        if let data = flowController.getData(for: "breakup_timing"),
           let timing = data["selected"] as? String {
            switch timing {
            case "just_happened": score += 11
            case "still_fresh": score += 7
            case "little_while": score += 3
            case "longer": score += 0
            default: break
            }
        }

        // Ensure score is between 65-96
        return min(96, max(65, score))
    }

    private let averageScore: Int = 35

    private var targetUserBarHeight: CGFloat {
        CGFloat(attachmentScore) * 2.8
    }

    private var targetAverageBarHeight: CGFloat {
        CGFloat(averageScore) * 2.8
    }

    var body: some View {
        ZStack {
            // Soft pink gradient instead of dark red
            OnboardingGradientBackground(style: .mochiWelcome, animated: true)

            OnboardingScrollableLayout(
                showBackButton: true,
                showContinueButton: showContinueButton,
                backgroundColor: .clear
            ) {
                VStack(spacing: 24) {
                    // Main message
                    VStack(spacing: 8) {
                        Text("your emotional attachment")
                            .font(.custom("Satoshi-Medium", size: 22))
                            .foregroundColor(Color(hex: "#4A2040"))
                            .multilineTextAlignment(.center)

                        Text("is higher than average")
                            .font(.custom("Satoshi-Bold", size: 28))
                            .foregroundColor(Color(hex: "#E080C0"))
                            .multilineTextAlignment(.center)
                    }
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 24)
                    .padding(.top, 20)

                    // Bar Chart
                    HStack(alignment: .bottom, spacing: 50) {
                        // User's bar
                        VStack(spacing: 8) {
                            ZStack(alignment: .bottom) {
                                Color.clear
                                    .frame(width: 70, height: 280)

                                VStack(spacing: 4) {
                                    if showPercentages {
                                        Text("\(attachmentScore)%")
                                            .font(.custom("Satoshi-Bold", size: 28))
                                            .foregroundColor(Color(hex: "#E080C0"))
                                            .fixedSize()
                                    }

                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(
                                            LinearGradient(
                                                colors: [Color(hex: "#FE9CDD"), Color(hex: "#E080C0")],
                                                startPoint: .top,
                                                endPoint: .bottom
                                            )
                                        )
                                        .frame(width: 70, height: userBarHeight)
                                }
                                .frame(height: userBarHeight + 44, alignment: .bottom)
                            }

                            Text("you")
                                .font(.custom("Satoshi-Bold", size: 16))
                                .foregroundColor(Color(hex: "#4A2040"))
                        }

                        // Average bar
                        VStack(spacing: 8) {
                            ZStack(alignment: .bottom) {
                                Color.clear
                                    .frame(width: 70, height: 280)

                                VStack(spacing: 4) {
                                    if showPercentages {
                                        Text("\(averageScore)%")
                                            .font(.custom("Satoshi-Bold", size: 22))
                                            .foregroundColor(Color(hex: "#6A3060").opacity(0.6))
                                            .fixedSize()
                                    }

                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color(hex: "#6A3060").opacity(0.3))
                                        .frame(width: 70, height: averageBarHeight)
                                }
                                .frame(height: averageBarHeight + 40, alignment: .bottom)
                            }

                            Text("average")
                                .font(.custom("Satoshi-Bold", size: 16))
                                .foregroundColor(Color(hex: "#6A3060").opacity(0.7))
                        }
                    }
                    .padding(.vertical, 16)

                    // Message
                    Text("your results show a strong emotional attachment to your ex")
                        .font(.custom("Satoshi-Medium", size: 18))
                        .foregroundColor(Color(hex: "#4A2040"))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                        .opacity(showMessage ? 1.0 : 0.0)

                    Spacer()
                }
            } continueAction: {
                flowController.saveData(for: "attachment_reveal", data: [
                    "attachment_score": attachmentScore,
                    "timestamp": Date().timeIntervalSince1970
                ])
                flowController.navigateNext()
            }
        }
        .onAppear {
            animateBars()
        }
    }

    private func animateBars() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.prepare()

        // Animate user bar first
        withAnimation(.easeOut(duration: 1.2)) {
            userBarHeight = targetUserBarHeight
        }

        // Then average bar
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(.easeOut(duration: 0.8)) {
                averageBarHeight = targetAverageBarHeight
            }
        }

        // Show percentages
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            generator.impactOccurred()
            withAnimation(.easeOut(duration: 0.3)) {
                showPercentages = true
            }
        }

        // Show message
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation(.easeOut(duration: 0.4)) {
                showMessage = true
            }
        }

        // Show continue button
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            withAnimation(.easeOut(duration: 0.3)) {
                showContinueButton = true
            }
        }
    }
}

struct AttachmentRevealScreen_Previews: PreviewProvider {
    static var previews: some View {
        AttachmentRevealScreen()
            .environmentObject(OnboardingFlowController())
    }
}
