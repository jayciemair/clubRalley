//
//  DailyCheckInView.swift
//  Checkpoint
//
//  Full-screen daily check-in prompt shown on app launch
//

import SwiftUI

struct DailyCheckInView: View {

    // MARK: - Properties

    @Binding var isPresented: Bool
    @Binding var showSuccessConfetti: Bool
    let currentStreak: Int
    let onRelapse: () -> Void

    @State private var opacity: Double = 0
    @State private var contentScale: CGFloat = 0.9

    // MARK: - Body

    var body: some View {
        ZStack {
            // Background
            AppTheme.Colors.background
                .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                // Main content
                VStack(spacing: AppTheme.Spacing.lg) {
                    // Mochi image
                    Image("Mochi")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 100, height: 100)
                        .clipShape(Circle())

                    // Day counter
                    VStack(spacing: AppTheme.Spacing.xs) {
                        Text("Day \(currentStreak + 1)")
                            .font(.custom("Satoshi-Black", size: 44))
                            .foregroundColor(AppTheme.Colors.textPrimary)

                        Text("Daily Check-In\nWith Mochi")
                            .font(.custom("Satoshi-Medium", size: 16))
                            .foregroundColor(AppTheme.Colors.textSecondary)
                            .multilineTextAlignment(.center)
                    }

                    // Question text
                    Text("did you contact him today?")
                        .font(.custom("Satoshi-Bold", size: 22))
                        .foregroundColor(AppTheme.Colors.textPrimary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, AppTheme.Spacing.xl)
                        .padding(.top, AppTheme.Spacing.md)

                    // Buttons - No keeps streak (good), Yes resets (relapse)
                    VStack(spacing: AppTheme.Spacing.md) {
                        // No button - Primary action (kept streak!)
                        Button(action: handleNo) {
                            HStack(spacing: 12) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 24, weight: .semibold))

                                Text("No")
                                    .font(.custom("Satoshi-Bold", size: 20))
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 64)
                            .background(AppTheme.Colors.success)
                            .cornerRadius(AppTheme.Radius.medium)
                        }

                        // Yes button - Secondary action (contacted him = relapse)
                        Button(action: handleYes) {
                            HStack(spacing: 12) {
                                Image(systemName: "xmark.circle")
                                    .font(.system(size: 24, weight: .semibold))

                                Text("Yes")
                                    .font(.custom("Satoshi-Bold", size: 20))
                            }
                            .foregroundColor(AppTheme.Colors.textSecondary)
                            .frame(maxWidth: .infinity)
                            .frame(height: 64)
                            .background(AppTheme.Colors.darkSurface)
                            .cornerRadius(AppTheme.Radius.medium)
                            .overlay(
                                RoundedRectangle(cornerRadius: AppTheme.Radius.medium)
                                    .stroke(AppTheme.Colors.border, lineWidth: 1)
                            )
                        }
                    }
                    .padding(.horizontal, AppTheme.Spacing.xl)
                    .padding(.top, AppTheme.Spacing.lg)
                }
                .scaleEffect(contentScale)

                Spacer()
                Spacer()
            }
            .opacity(opacity)
        }
        .onAppear {
            animateIn()
        }
    }

    // MARK: - Actions

    // No = didn't contact him = good (keeps streak)
    private func handleNo() {
        // Haptic feedback
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)

        // Record the check-in (stayed clean = didn't contact him)
        DailyCheckInManager.shared.recordCheckIn(stayedClean: true)

        // Animate out and show confetti
        animateOut {
            showSuccessConfetti = true
            isPresented = false
        }
    }

    // Yes = contacted him = relapse (resets streak)
    private func handleYes() {
        // Haptic feedback - softer for negative action
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()

        // Record the check-in (so it doesn't appear again today)
        DailyCheckInManager.shared.recordCheckIn(stayedClean: false)

        // Animate out and trigger relapse flow
        animateOut {
            isPresented = false
            onRelapse()
        }
    }

    // MARK: - Animations

    private func animateIn() {
        withAnimation(.easeOut(duration: 0.3)) {
            opacity = 1
        }
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
            contentScale = 1.0
        }
    }

    private func animateOut(completion: @escaping () -> Void) {
        withAnimation(.easeIn(duration: 0.2)) {
            opacity = 0
            contentScale = 0.95
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            completion()
        }
    }
}

// MARK: - Preview

struct DailyCheckInView_Previews: PreviewProvider {
    static var previews: some View {
        DailyCheckInView(
            isPresented: .constant(true),
            showSuccessConfetti: .constant(false),
            currentStreak: 247,
            onRelapse: {}
        )
    }
}
