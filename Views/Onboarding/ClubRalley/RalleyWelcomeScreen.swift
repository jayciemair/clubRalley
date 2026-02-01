//
//  RalleyWelcomeScreen.swift
//  Club Ralley
//
//  Welcome screen for Ralley Connect onboarding (Figma design)
//

import SwiftUI

struct RalleyWelcomeScreen: View {
    @EnvironmentObject var controller: ClubRalleyOnboardingController
    @State private var animateLogo = false

    var body: some View {
        ZStack {
            // White background
            Color.white
                .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                // Ralley logo
                VStack(spacing: 24) {
                    // Logo icon
                    ZStack {
                        Circle()
                            .fill(Color(hex: "#2C4F40"))
                            .frame(width: 100, height: 100)

                        Image(systemName: "figure.run")
                            .font(.system(size: 44, weight: .semibold))
                            .foregroundColor(.white)
                    }
                    .scaleEffect(animateLogo ? 1 : 0.8)
                    .opacity(animateLogo ? 1 : 0)
                    .animation(.spring(response: 0.6, dampingFraction: 0.7), value: animateLogo)

                    // Title
                    Text("Ralley Connect")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundColor(.black)
                        .opacity(animateLogo ? 1 : 0)
                        .animation(.easeOut(duration: 0.5).delay(0.2), value: animateLogo)
                }

                Spacer()
                    .frame(height: 40)

                // Tagline
                Text("Meet and reconnect with athletes in our digital locker room.")
                    .font(.system(size: 18))
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                    .opacity(animateLogo ? 1 : 0)
                    .animation(.easeOut(duration: 0.5).delay(0.4), value: animateLogo)

                Spacer()

                // Join button
                Button(action: {
                    controller.goToNextStep()
                }) {
                    Text("Join the roster")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color(hex: "#2C4F40"))
                        .cornerRadius(30)
                }
                .padding(.horizontal, 24)
                .opacity(animateLogo ? 1 : 0)
                .animation(.easeOut(duration: 0.5).delay(0.6), value: animateLogo)

                // Terms text
                VStack(spacing: 4) {
                    Text("By continuing, you agree to our")
                        .font(.system(size: 12))
                        .foregroundColor(.gray)

                    HStack(spacing: 4) {
                        Button(action: {}) {
                            Text("Privacy Policy")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(Color(hex: "#2C4F40"))
                                .underline()
                        }
                        Text("and")
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                        Button(action: {}) {
                            Text("Terms of Service")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(Color(hex: "#2C4F40"))
                                .underline()
                        }
                    }
                }
                .padding(.top, 16)
                .padding(.bottom, 40)
                .opacity(animateLogo ? 1 : 0)
                .animation(.easeOut(duration: 0.5).delay(0.8), value: animateLogo)
            }
        }
        .onAppear {
            animateLogo = true
        }
    }
}

struct RalleyWelcomeScreen_Previews: PreviewProvider {
    static var previews: some View {
        RalleyWelcomeScreen()
            .environmentObject(ClubRalleyOnboardingController())
    }
}
