//
//  WelcomeScreen.swift
//  Club Ralley
//
//  Welcome screen for Club Ralley onboarding
//

import SwiftUI

struct WelcomeScreen: View {
    @EnvironmentObject var controller: ClubRalleyOnboardingController
    @State private var showingAnimation = false
    @State private var featuresVisible = [false, false, false]

    var body: some View {
        ZStack {
            // Background
            Color(hex: "#F5F5F5")
                .ignoresSafeArea()

            GeometryReader { geometry in
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 32) {
                        Spacer(minLength: 40)

                        // App logo/icon
                        VStack(spacing: 20) {
                            ZStack {
                                // Outer ring animation
                                Circle()
                                    .stroke(Color(hex: "#2C4F40").opacity(0.2), lineWidth: 3)
                                    .frame(width: 140, height: 140)
                                    .scaleEffect(showingAnimation ? 1.1 : 1.0)
                                    .opacity(showingAnimation ? 0.5 : 1.0)
                                    .animation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true), value: showingAnimation)

                                Circle()
                                    .fill(Color(hex: "#2C4F40"))
                                    .frame(width: 120, height: 120)

                                Image(systemName: "figure.run")
                                    .font(.system(size: 50, weight: .bold))
                                    .foregroundColor(.white)
                            }

                            Text("Club Ralley")
                                .font(.system(size: 36, weight: .bold))
                                .foregroundColor(ClubRalleyTheme.Colors.darkGreen)
                        }

                        // Tagline
                        VStack(spacing: 8) {
                            Text("GFTO")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(Color(hex: "#2C4F40"))

                            Text("Get the F*** Outside")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(.gray)
                        }

                        // Value propositions
                        VStack(spacing: 16) {
                            ForEach(Array(features.enumerated()), id: \.offset) { index, feature in
                                WelcomeFeatureRow(
                                    icon: feature.icon,
                                    title: feature.title,
                                    description: feature.description
                                )
                                .opacity(featuresVisible[index] ? 1 : 0)
                                .offset(x: featuresVisible[index] ? 0 : -30)
                            }
                        }
                        .padding(.horizontal, 24)

                        Spacer(minLength: 40)

                        // Continue button
                        Button(action: {
                            controller.goToNextStep()
                        }) {
                            HStack(spacing: 8) {
                                Text("Get Started")
                                    .font(.system(size: 18, weight: .semibold))

                                Image(systemName: "arrow.right")
                                    .font(.system(size: 16, weight: .semibold))
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color(hex: "#2C4F40"))
                            .cornerRadius(12)
                        }
                        .padding(.horizontal, 24)

                        // Terms text
                        Text("By continuing, you agree to our Terms of Service and Privacy Policy")
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                            .padding(.bottom, 32)
                    }
                    .frame(minHeight: geometry.size.height)
                }
            }
        }
        .onAppear {
            showingAnimation = true
            animateFeatures()
        }
    }

    private var features: [(icon: String, title: String, description: String)] {
        [
            ("person.2.fill", "Rally Together", "Find athletes and active people to play with"),
            ("sportscourt.fill", "Discover Games", "Join pickup games and events near you"),
            ("trophy.fill", "Build Your Crew", "Create your own ralleys and grow your community")
        ]
    }

    private func animateFeatures() {
        for index in 0..<features.count {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 0.2 + 0.3) {
                withAnimation(.easeOut(duration: 0.4)) {
                    featuresVisible[index] = true
                }
            }
        }
    }
}

// MARK: - Welcome Feature Row

private struct WelcomeFeatureRow: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(alignment: .center, spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color(hex: "#2C4F40").opacity(0.1))
                    .frame(width: 52, height: 52)

                Image(systemName: icon)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(Color(hex: "#2C4F40"))
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(ClubRalleyTheme.Colors.darkGreen)

                Text(description)
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
}

// MARK: - Preview

struct WelcomeScreen_Previews: PreviewProvider {
    static var previews: some View {
        WelcomeScreen()
            .environmentObject(ClubRalleyOnboardingController())
    }
}
