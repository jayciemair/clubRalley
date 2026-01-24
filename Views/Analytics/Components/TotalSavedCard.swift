//
//  TotalSavedCard.swift
//  Checkpoint
//
//  Hero card displaying total amount saved with animated ticker
//

import SwiftUI

struct TotalSavedCard: View {

    // MARK: - Properties

    let amount: Double
    @Binding var showingExplanation: Bool

    // Dynamic font size based on amount value
    private var fontSize: CGFloat {
        if amount >= 1000000 {
            return 56  // $1,000,000+
        } else if amount >= 100000 {
            return 64  // $100,000+
        } else if amount >= 10000 {
            return 68  // $10,000+
        } else {
            return 72  // < $10,000
        }
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            // Main card content
            VStack(spacing: 0) {
                Spacer()

                VStack(spacing: 4) {
                    Text("Total Saved")
                        .font(.custom("Satoshi-Medium", size: 16))
                        .foregroundColor(AppTheme.Colors.textSecondary)

                    // Animated counting number display with smooth transitions
                    AnimatedCountingNumberView(
                        targetValue: amount,
                        fontSize: fontSize,
                        fontName: "Satoshi-Bold",
                        color: Color.green
                    )
                    .padding(.vertical, 4)

                    Text("Since joining Checkpoint")
                        .font(.custom("Satoshi-Regular", size: 14))
                        .foregroundColor(AppTheme.Colors.textSecondary)
                }

                Spacer()
            }
            .frame(maxWidth: .infinity)
            .frame(height: 240)
            .background(
                LinearGradient(
                    colors: [
                        AppTheme.Colors.darkSurface.opacity(0.9),
                        AppTheme.Colors.darkSurface
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.medium))
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.Radius.medium)
                    .stroke(Color.white.opacity(0.05), lineWidth: 1)
            )

            // Info button - top right
            VStack {
                HStack {
                    Spacer()

                    Button(action: {
                        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                        impactFeedback.impactOccurred()
                        showingExplanation = true
                    }) {
                        Image(systemName: "info.circle")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(AppTheme.Colors.textSecondary.opacity(0.8))
                            .padding(12)
                    }
                }
                Spacer()
            }

            // Sitting checkpoint guy on top right edge
            // Commented out - no longer needed
            /*
            VStack {
                HStack {
                    Spacer()
                    Image("checkpoint_sitting")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 90, height: 90)
                        .offset(x: -20, y: -62)
                }
                Spacer()
            }
            .allowsHitTesting(false) // So it doesn't block the info button
            */
        }
        .frame(maxWidth: .infinity)
        .frame(height: 240)
    }
}

// MARK: - Preview

struct TotalSavedCard_Previews: PreviewProvider {
    @State static var showingExplanation = false

    static var previews: some View {
        TotalSavedCard(amount: 1234.56, showingExplanation: $showingExplanation)
            .padding()
            .background(AppTheme.Colors.background)
    }
}
