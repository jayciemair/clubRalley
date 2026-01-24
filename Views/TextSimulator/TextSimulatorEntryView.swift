//
//  TextSimulatorEntryView.swift
//  Get Over Him
//
//  Entry screen before text simulator - reality check before texting
//

import SwiftUI

struct TextSimulatorEntryView: View {
    @State private var showSimulator = false
    @ObservedObject private var statsManager = SimulatorStatsManager.shared

    var body: some View {
        ZStack {
            // Pink gradient background
            LinearGradient(
                colors: [
                    Color(hex: "#F8C8DC"),
                    Color(hex: "#F0A0C0"),
                    Color(hex: "#E890B8")
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 0) {
                    // Header
                    HStack {
                        Text("text him")
                            .font(.custom("Satoshi-Bold", size: 34))
                            .foregroundColor(.white)
                        Spacer()
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 10)

                    Spacer()
                        .frame(height: 40)

                    // Hero card
                    VStack(spacing: 20) {
                        // Trash icon
                        ZStack {
                            Circle()
                                .fill(Color(hex: "#E080C0").opacity(0.2))
                                .frame(width: 100, height: 100)

                            Image(systemName: "trash.fill")
                                .font(.system(size: 40, weight: .medium))
                                .foregroundColor(Color(hex: "#D070B0"))
                        }

                        // Main message
                        VStack(spacing: 8) {
                            Text("want to text him?")
                                .font(.custom("Satoshi-Bold", size: 24))
                                .foregroundColor(Color(hex: "#4A2040"))

                            Text("test it here first")
                                .font(.custom("Satoshi-Medium", size: 16))
                                .foregroundColor(Color(hex: "#6A3060").opacity(0.7))
                        }

                        // CTA Button
                        Button(action: {
                            let generator = UIImpactFeedbackGenerator(style: .medium)
                            generator.impactOccurred()
                            showSimulator = true
                        }) {
                            HStack(spacing: 8) {
                                Text("start")
                                    .font(.custom("Satoshi-Bold", size: 16))
                                Image(systemName: "arrow.right")
                                    .font(.system(size: 14, weight: .bold))
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 28)
                            .padding(.vertical, 14)
                            .background(
                                LinearGradient(
                                    colors: [
                                        Color(hex: "#E080C0"),
                                        Color(hex: "#D070B0")
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(24)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 32)
                    .padding(.horizontal, 24)
                    .background(Color.white.opacity(0.7))
                    .cornerRadius(24)
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .stroke(Color.white.opacity(0.5), lineWidth: 1)
                    )
                    .padding(.horizontal, 24)

                    Spacer()
                        .frame(height: 24)

                    // Stats section
                    VStack(spacing: 12) {
                        Text("after trying this")
                            .font(.custom("Satoshi-Medium", size: 14))
                            .foregroundColor(Color(hex: "#6A3060").opacity(0.8))

                        HStack(spacing: 12) {
                            StatBox(
                                percent: statsManager.noLongerWantToTextPercent,
                                label: "didnt text\nhim after"
                            )
                            StatBox(
                                percent: statsManager.notWorthItPercent,
                                label: "said he wasnt\nworth it"
                            )
                            StatBox(
                                percent: statsManager.predictedRegretPercent,
                                label: "avoided\nregret"
                            )
                        }
                    }
                    .padding(.horizontal, 24)

                    Spacer()
                        .frame(height: 20)

                    // "It helped" callout
                    HStack(spacing: 8) {
                        Text("\(statsManager.helpedPercent)%")
                            .font(.custom("Satoshi-Bold", size: 18))
                            .foregroundColor(Color(hex: "#4A2040"))

                        Text("said it helped")
                            .font(.custom("Satoshi-Medium", size: 16))
                            .foregroundColor(Color(hex: "#6A3060").opacity(0.8))
                    }
                    .padding(.vertical, 14)
                    .padding(.horizontal, 24)
                    .background(Color.white.opacity(0.6))
                    .cornerRadius(20)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.white.opacity(0.3), lineWidth: 1)
                    )
                    .padding(.horizontal, 24)

                    // Bottom padding for tab bar
                    Color.clear
                        .frame(height: 120)
                }
            }
            .scrollIndicators(.hidden)
        }
        .fullScreenCover(isPresented: $showSimulator) {
            TextSimulatorView()
        }
    }
}

// MARK: - Stat Box Component

private struct StatBox: View {
    let percent: Int
    let label: String

    var body: some View {
        VStack(spacing: 6) {
            Text("\(percent)%")
                .font(.custom("Satoshi-Bold", size: 24))
                .foregroundColor(Color(hex: "#4A2040"))

            Text(label)
                .font(.custom("Satoshi-Regular", size: 11))
                .foregroundColor(Color(hex: "#6A3060").opacity(0.7))
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .frame(height: 28) // Fixed height for 2 lines
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .padding(.horizontal, 6)
        .background(Color.white.opacity(0.6))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.3), lineWidth: 1)
        )
    }
}

#Preview {
    TextSimulatorEntryView()
}
