//
//  NoContactTimerView.swift
//  Checkpoint
//
//  Real-time display showing days since last contact
//  With reset functionality for when they actually texted
//

import SwiftUI

struct NoContactTimerView: View {
    let startDate: Date
    var onReset: (() -> Void)?

    @State private var now = Date()
    @State private var showResetConfirmation = false

    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    // Calculate time components since start date
    private var timeComponents: (days: Int, hours: Int, minutes: Int, seconds: Int) {
        let interval = now.timeIntervalSince(startDate)
        guard interval > 0 else { return (0, 0, 0, 0) }

        let totalSeconds = Int(interval)
        let days = totalSeconds / 86400
        let hours = (totalSeconds % 86400) / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60

        return (days, hours, minutes, seconds)
    }

    var body: some View {
        VStack(spacing: 16) {
            // Main days display - big and prominent
            VStack(spacing: 4) {
                Text("\(timeComponents.days)")
                    .font(.custom("Satoshi-Black", size: 72))
                    .foregroundColor(Color(hex: "#4A2040"))
                    .contentTransition(.numericText())

                Text(timeComponents.days == 1 ? "day" : "days")
                    .font(.custom("Satoshi-Medium", size: 18))
                    .foregroundColor(Color(hex: "#6A3060").opacity(0.7))
            }

            // Time breakdown - hours:mins:secs
            HStack(spacing: 8) {
                TimeBlock(value: timeComponents.hours, label: "hrs")
                Text(":")
                    .font(.custom("Satoshi-Bold", size: 20))
                    .foregroundColor(Color(hex: "#6A3060").opacity(0.5))
                TimeBlock(value: timeComponents.minutes, label: "min")
                Text(":")
                    .font(.custom("Satoshi-Bold", size: 20))
                    .foregroundColor(Color(hex: "#6A3060").opacity(0.5))
                TimeBlock(value: timeComponents.seconds, label: "sec")
            }

            // Label
            Text("no contact")
                .font(.custom("Satoshi-Medium", size: 14))
                .foregroundColor(Color(hex: "#6A3060").opacity(0.6))

            // Reset button
            if onReset != nil {
                Button(action: {
                    let generator = UIImpactFeedbackGenerator(style: .medium)
                    generator.impactOccurred()
                    showResetConfirmation = true
                }) {
                    Text("i texted him")
                        .font(.custom("Satoshi-Medium", size: 14))
                        .foregroundColor(Color(hex: "#E080C0"))
                }
                .padding(.top, 4)
            }
        }
        .padding(.vertical, 24)
        .padding(.horizontal, 24)
        .frame(maxWidth: .infinity)
        .background(Color.white.opacity(0.6))
        .cornerRadius(24)
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(Color.white.opacity(0.3), lineWidth: 1)
        )
        .onReceive(timer) { _ in
            now = Date()
        }
        .alert("reset your streak?", isPresented: $showResetConfirmation) {
            Button("cancel", role: .cancel) {}
            Button("yes, i texted him", role: .destructive) {
                onReset?()
            }
        } message: {
            Text("this will reset your no contact counter. you can do this!")
        }
    }
}

// MARK: - Time Block Component

private struct TimeBlock: View {
    let value: Int
    let label: String

    var body: some View {
        VStack(spacing: 2) {
            Text(String(format: "%02d", value))
                .font(.custom("Satoshi-Bold", size: 24))
                .foregroundColor(Color(hex: "#4A2040"))
                .monospacedDigit()

            Text(label)
                .font(.custom("Satoshi-Regular", size: 10))
                .foregroundColor(Color(hex: "#6A3060").opacity(0.6))
        }
        .frame(width: 50)
    }
}

// MARK: - Preview

struct NoContactTimerView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
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

            VStack(spacing: 20) {
                NoContactTimerView(
                    startDate: Date().addingTimeInterval(-3 * 24 * 60 * 60),
                    onReset: { print("Reset!") }
                )
                .padding(.horizontal, 24)
            }
        }
    }
}
