//
//  BreathingIntroScreen.swift
//  Checkpoint
//
//  Intro screen before breathing exercise
//

import SwiftUI

struct BreathingIntroScreen: View {
    var onComplete: (() -> Void)? = nil
    @State private var showContinueButton = false

    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [
                    Color(red: 0.15, green: 0.20, blue: 0.35),
                    Color(red: 0.08, green: 0.10, blue: 0.18)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                VStack(alignment: .center, spacing: AppTheme.Spacing.xl) {
                    Text("Take a moment")
                        .font(.custom("Satoshi-Bold", size: 36))
                        .foregroundColor(AppTheme.Colors.textPrimary)
                        .multilineTextAlignment(.center)

                    VStack(alignment: .center, spacing: AppTheme.Spacing.lg) {
                        Image(systemName: "wind")
                            .font(.system(size: 64))
                            .foregroundColor(AppTheme.Colors.primary)

                        VStack(alignment: .center, spacing: AppTheme.Spacing.md) {
                            Text("Let's do 4 breathing cycles")
                                .font(.system(size: 18))
                                .foregroundColor(AppTheme.Colors.textSecondary)
                                .multilineTextAlignment(.center)

                            Text("Follow the expanding and shrinking circle as you breathe")
                                .font(.system(size: 16))
                                .foregroundColor(AppTheme.Colors.textSecondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.horizontal, AppTheme.Spacing.lg)
                    }
                }

                Spacer()

                // Continue button at bottom (always rendered to prevent layout shift)
                Button(action: {
                    onComplete?()
                }) {
                    Text("Continue")
                        .font(.custom("Satoshi-Bold", size: 17))
                        .foregroundColor(AppTheme.Colors.darkSurface)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(AppTheme.Colors.primary)
                        .cornerRadius(12)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
                .opacity(showContinueButton ? 1 : 0)
                .disabled(!showContinueButton)
            }
        }
        .onAppear {
            // Delay showing continue button by 1.5 seconds
            Task {
                try? await Task.sleep(nanoseconds: 1_500_000_000) // 1.5 seconds
                withAnimation {
                    showContinueButton = true
                }
            }
        }
    }
}

struct BreathingIntroScreen_Previews: PreviewProvider {
    static var previews: some View {
        BreathingIntroScreen()
    }
}
