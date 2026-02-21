//
//  SocialProofScreen.swift
//  Club Ralley
//
//  Social proof - women who have healed
//

import SwiftUI

struct SocialProofScreen: View {
    @EnvironmentObject var flowController: OnboardingFlowController

    @State private var showTitle: Bool = false
    @State private var visibleReviews: [Int] = []
    @State private var showButton: Bool = false

    private let reviews = [
        (name: "Eliza, 24", review: "I was checking his Instagram 20 times a day. Now I don't even think about it. This app saved my sanity."),
        (name: "Priya, 18", review: "The text simulation feature stopped me from embarrassing myself so many times. Worth it just for that."),
        (name: "Jordan, 26", review: "I thought I'd never move on. 30 days later, I barely recognize the girl who was crying every night.")
    ]

    var body: some View {
        ZStack {
            OnboardingGradientBackground(style: .mochiWelcome, animated: true)

            OnboardingScrollableLayout(
                showBackButton: true,
                showContinueButton: showButton,
                backgroundColor: .clear
            ) {
                VStack(spacing: 0) {
                    Spacer()
                        .frame(height: 40)

                    // Title
                    VStack(spacing: 8) {
                        Text("Women like you")
                            .font(.custom("Satoshi-Bold", size: 32))
                            .foregroundColor(Color(hex: "#4A2040"))

                        Text("have healed")
                            .font(.custom("Satoshi-Bold", size: 32))
                            .foregroundColor(Color(hex: "#E080C0"))
                    }
                    .opacity(showTitle ? 1 : 0)
                    .padding(.horizontal, 24)

                    Spacer()
                        .frame(height: 32)

                    // Reviews
                    VStack(spacing: 16) {
                        ForEach(Array(reviews.enumerated()), id: \.offset) { index, review in
                            ReviewCard(name: review.name, review: review.review)
                                .opacity(visibleReviews.contains(index) ? 1 : 0)
                                .offset(y: visibleReviews.contains(index) ? 0 : 20)
                        }
                    }
                    .padding(.horizontal, 24)

                    Spacer()
                }
            } continueAction: {
                flowController.saveData(for: "social_proof", data: [
                    "viewed": true,
                    "timestamp": Date().timeIntervalSince1970
                ])
                flowController.navigateNext()
            }
        }
        .onAppear {
            animateSequence()
        }
    }

    private func animateSequence() {
        // Show title
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(.easeOut(duration: 0.4)) {
                showTitle = true
            }
        }

        // Show reviews one by one
        for (index, _) in reviews.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8 + Double(index) * 0.4) {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                withAnimation(.easeOut(duration: 0.4)) {
                    visibleReviews.append(index)
                }
            }
        }

        // Show button
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8 + Double(reviews.count) * 0.4 + 0.5) {
            withAnimation(.easeOut(duration: 0.3)) {
                showButton = true
            }
        }
    }
}

// MARK: - Review Card

private struct ReviewCard: View {
    let name: String
    let review: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Stars
            HStack(spacing: 2) {
                ForEach(0..<5, id: \.self) { _ in
                    Image(systemName: "star.fill")
                        .font(.system(size: 12))
                        .foregroundColor(Color(hex: "#E080C0"))
                }
            }

            Text(review)
                .font(.custom("Satoshi-Regular", size: 16))
                .foregroundColor(Color(hex: "#4A2040"))
                .fixedSize(horizontal: false, vertical: true)

            Text("— \(name)")
                .font(.custom("Satoshi-Medium", size: 14))
                .foregroundColor(Color(hex: "#6A3060").opacity(0.7))
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.7))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color(hex: "#E080C0").opacity(0.3), lineWidth: 1)
        )
    }
}

struct SocialProofScreen_Previews: PreviewProvider {
    static var previews: some View {
        SocialProofScreen()
            .environmentObject(OnboardingFlowController())
    }
}
