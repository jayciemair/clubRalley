//
//  TierUnlockedHUD.swift
//  Checkpoint
//
//  Full-screen celebration HUD when user unlocks a new tier card
//

import SwiftUI

struct TierUnlockedHUD: View {
    let tierName: String
    let daysNoContact: Int
    let quitDate: Date
    @Binding var isShowing: Bool

    @State private var scale: CGFloat = 0.5
    @State private var opacity: Double = 0.0

    var body: some View {
        ZStack {
            // Dark background overlay (covers entire screen including tab bar)
            Color.black.opacity(0.92)
                .ignoresSafeArea(.all, edges: .all)
                .opacity(opacity)

            // Content container with additional dark background
            VStack(spacing: AppTheme.Spacing.xl) {
                // Celebration text
                VStack(spacing: AppTheme.Spacing.sm) {
                    Text("New Card Unlocked!")
                        .font(.custom("Satoshi-Bold", size: 32))
                        .foregroundColor(.white)

                    Text(daysNoContact == 0 ? "Your Healing Begins!" : "\(daysNoContact) Days No Contact")
                        .font(.custom("Satoshi-Medium", size: 18))
                        .foregroundColor(.white.opacity(0.9))
                }

                // The tier card
                QuitDateCard(quitDate: quitDate, currentStreak: daysNoContact)
                    .frame(width: 300)
                    .scaleEffect(scale)
                    .shadow(color: .black.opacity(0.5), radius: 30, x: 0, y: 15)

                // Tap to continue
                Text("Tap to continue")
                    .font(.custom("Satoshi-Regular", size: 16))
                    .foregroundColor(.white.opacity(0.7))
            }
            .padding(.horizontal, AppTheme.Spacing.xl)
            .padding(.vertical, 60)
            .opacity(opacity)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            // Trigger haptic feedback
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)

            // Animate in
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                scale = 1.0
            }

            withAnimation(.easeOut(duration: 0.4)) {
                opacity = 1.0
            }
        }
        .onTapGesture {
            dismiss()
        }
    }

    private func dismiss() {
        // Animate out
        withAnimation(.easeIn(duration: 0.2)) {
            opacity = 0.0
            scale = 0.9
        }

        // Dismiss after animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            isShowing = false
        }
    }
}

// MARK: - View Modifier

struct TierUnlockedHUDModifier: ViewModifier {
    @Binding var isShowing: Bool
    let tierName: String
    let daysNoContact: Int
    let quitDate: Date

    func body(content: Content) -> some View {
        content
            .overlay(
                Group {
                    if isShowing {
                        TierUnlockedHUD(
                            tierName: tierName,
                            daysNoContact: daysNoContact,
                            quitDate: quitDate,
                            isShowing: $isShowing
                        )
                        .transition(.opacity)
                    }
                }
                .ignoresSafeArea(.all)
            )
    }
}

extension View {
    func tierUnlockedHUD(
        isShowing: Binding<Bool>,
        tierName: String,
        daysNoContact: Int,
        quitDate: Date
    ) -> some View {
        modifier(TierUnlockedHUDModifier(
            isShowing: isShowing,
            tierName: tierName,
            daysNoContact: daysNoContact,
            quitDate: quitDate
        ))
    }
}

// MARK: - Preview

struct TierUnlockedHUD_Previews: PreviewProvider {
    static var previews: some View {
        TierUnlockedHUD(
            tierName: "Peace",
            daysNoContact: 68,
            quitDate: Date().addingTimeInterval(10 * 24 * 60 * 60),
            isShowing: .constant(true)
        )
    }
}
