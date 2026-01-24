//
//  SavingsExplanationView.swift
//  Checkpoint
//
//  Explanation popup showing how savings are calculated
//

import SwiftUI

struct SavingsExplanationView: View {
    @Binding var isShowing: Bool

    var body: some View {
        ZStack {
            // Dimmed background
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture {
                    isShowing = false
                }

            // Popup card (now scrollable)
            ScrollView {
                VStack(spacing: 20) {
                    // Header with X button
                    HStack {
                        Text("How we calculate your savings")
                            .font(.custom("Satoshi-Bold", size: 20))
                            .foregroundColor(AppTheme.Colors.textPrimary)

                        Spacer()

                        Button(action: {
                            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                            impactFeedback.impactOccurred()
                            isShowing = false
                        }) {
                            Image(systemName: "xmark")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(AppTheme.Colors.textSecondary)
                                .padding(8)
                                .background(Circle().fill(Color.gray.opacity(0.1)))
                        }
                    }

                    // Content sections
                    VStack(spacing: 16) {
                        VStack(spacing: 12) {
                            Text("Your healing progress:")
                                .font(.custom("Satoshi-Medium", size: 14))
                                .foregroundColor(AppTheme.Colors.textSecondary)

                            VStack(spacing: 4) {
                                Text("Days of no contact × Healing multiplier")
                                    .font(.custom("Satoshi-Bold", size: 15))
                                    .foregroundColor(Color.green)
                            }
                            .multilineTextAlignment(.center)
                            .padding(.vertical, 12)
                            .padding(.horizontal, 16)
                            .frame(maxWidth: .infinity)
                            .background(Color.green.opacity(0.1))
                            .cornerRadius(12)

                            Text("Your emotional recovery score")
                                .font(.custom("Satoshi-Regular", size: 13))
                                .foregroundColor(AppTheme.Colors.textSecondary)
                        }

                        Divider()

                        VStack(spacing: 8) {
                            Text("Based on:")
                                .font(.custom("Satoshi-Medium", size: 14))
                                .foregroundColor(AppTheme.Colors.textSecondary)

                            Text("Time Since Last Contact")
                                .font(.custom("Satoshi-Bold", size: 15))
                                .foregroundColor(Color.green)

                            Text("Time since you started your healing journey")
                                .font(.custom("Satoshi-Regular", size: 12))
                                .foregroundColor(AppTheme.Colors.textSecondary)
                        }

                        Divider()
                            .padding(.vertical, 8)

                        // Contact section
                        Text("What if I contact him?")
                            .font(.custom("Satoshi-Bold", size: 20))
                            .foregroundColor(AppTheme.Colors.textPrimary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.top, 8)

                        VStack(spacing: 12) {
                            HStack(alignment: .top, spacing: 12) {
                                Image(systemName: "1.circle.fill")
                                    .foregroundColor(AppTheme.Colors.primary)
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Be honest with yourself")
                                        .font(.custom("Satoshi-Medium", size: 14))
                                        .foregroundColor(AppTheme.Colors.textPrimary)
                                    Text("This is for your own healing")
                                        .font(.custom("Satoshi-Regular", size: 12))
                                        .foregroundColor(AppTheme.Colors.textSecondary)
                                }
                                Spacer()
                            }

                            HStack(alignment: .top, spacing: 12) {
                                Image(systemName: "2.circle.fill")
                                    .foregroundColor(AppTheme.Colors.primary)
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Your no-contact streak resets")
                                        .font(.custom("Satoshi-Medium", size: 14))
                                        .foregroundColor(AppTheme.Colors.textPrimary)
                                    Text("But your overall progress continues")
                                        .font(.custom("Satoshi-Regular", size: 12))
                                        .foregroundColor(AppTheme.Colors.textSecondary)
                                }
                                Spacer()
                            }

                            HStack(alignment: .top, spacing: 12) {
                                Image(systemName: "3.circle.fill")
                                    .foregroundColor(AppTheme.Colors.primary)
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Every day still counts")
                                        .font(.custom("Satoshi-Medium", size: 14))
                                        .foregroundColor(AppTheme.Colors.textPrimary)
                                    Text("Progress isn't lost - just start fresh")
                                        .font(.custom("Satoshi-Regular", size: 12))
                                        .foregroundColor(AppTheme.Colors.textSecondary)
                                }
                                Spacer()
                            }

                            HStack(alignment: .top, spacing: 12) {
                                Image(systemName: "4.circle.fill")
                                    .foregroundColor(AppTheme.Colors.primary)
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Texts avoided & contact-free days stay intact")
                                        .font(.custom("Satoshi-Medium", size: 14))
                                        .foregroundColor(AppTheme.Colors.textPrimary)
                                    Text("These track your lifetime progress")
                                        .font(.custom("Satoshi-Regular", size: 12))
                                        .foregroundColor(AppTheme.Colors.textSecondary)
                                }
                                Spacer()
                            }
                        }
                        .padding(.top, 8)

                    }
                }
                .padding(24)
            }
            .scrollIndicators(.hidden)
            .background(AppTheme.Colors.darkSurface)
            .cornerRadius(20)
            .frame(maxWidth: 340, maxHeight: 600)
            .shadow(radius: 20)
        }
    }
}

// MARK: - Preview

struct SavingsExplanationView_Previews: PreviewProvider {
    @State static var isShowing = true

    static var previews: some View {
        SavingsExplanationView(isShowing: $isShowing)
    }
}