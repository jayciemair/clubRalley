//
//  CheckInFrequencyScreen.swift
//  Club Ralley
//
//  Asks how often Mochi should check in - triggers notification permission
//

import SwiftUI
import UserNotifications

struct CheckInFrequencyScreen: View {
    @EnvironmentObject var flowController: OnboardingFlowController

    @State private var displayedText: String = ""
    @State private var showSlider: Bool = false
    @State private var showButton: Bool = false
    @State private var frequency: Double = 3
    @State private var currentPhrase: Int = 0

    private let phrases = [
        "how often should i check in with you?"
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
                        .frame(height: 24)

                    // Mochi
                    HStack {
                        Image("Mochi")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 180, height: 180)
                        Spacer()
                    }
                    .padding(.leading, 24)

                    Spacer()
                        .frame(height: 8)

                    // Chat bubble
                    ZStack(alignment: .topLeading) {
                        Text("how often should i check in with you?")
                            .font(.custom("Satoshi-Medium", size: 22))
                            .foregroundColor(.clear)
                            .multilineTextAlignment(.leading)
                            .fixedSize(horizontal: false, vertical: true)

                        Text(displayedText)
                            .font(.custom("Satoshi-Medium", size: 22))
                            .foregroundColor(Color(hex: "#4A2040"))
                            .multilineTextAlignment(.leading)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 20)
                    .background(
                        SpeechBubbleShape(tailOffset: 50)
                            .fill(Color.white.opacity(0.7))
                    )
                    .overlay(
                        SpeechBubbleShape(tailOffset: 50)
                            .stroke(Color(hex: "#E080C0").opacity(0.5), lineWidth: 1.5)
                    )
                    .padding(.horizontal, 24)

                    Spacer()
                        .frame(height: 32)

                    // Frequency selector
                    if showSlider {
                        VStack(spacing: 20) {
                            // Display selected frequency
                            Text("\(Int(frequency))")
                                .font(.custom("Satoshi-Black", size: 64))
                                .foregroundColor(Color(hex: "#4A2040"))

                            Text(frequencyLabel)
                                .font(.custom("Satoshi-Medium", size: 18))
                                .foregroundColor(Color(hex: "#6A3060").opacity(0.8))

                            // Slider
                            VStack(spacing: 8) {
                                Slider(value: $frequency, in: 1...10, step: 1)
                                    .accentColor(Color(hex: "#E080C0"))
                                    .padding(.horizontal, 8)

                                // Labels
                                HStack {
                                    Text("1")
                                        .font(.custom("Satoshi-Medium", size: 14))
                                        .foregroundColor(Color(hex: "#6A3060").opacity(0.6))
                                    Spacer()
                                    Text("10")
                                        .font(.custom("Satoshi-Medium", size: 14))
                                        .foregroundColor(Color(hex: "#6A3060").opacity(0.6))
                                }
                                .padding(.horizontal, 8)
                            }
                        }
                        .padding(24)
                        .background(Color.white.opacity(0.6))
                        .cornerRadius(20)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color.white.opacity(0.3), lineWidth: 1)
                        )
                        .padding(.horizontal, 24)
                        .transition(.opacity.combined(with: .scale(scale: 0.95)))
                    }

                    Spacer()
                }
            } continueAction: {
                // Save frequency to UserDefaults
                UserDefaults.standard.set(Int(frequency), forKey: "mochi_checkin_frequency")

                flowController.saveData(for: "checkin_frequency", data: [
                    "frequency": Int(frequency),
                    "timestamp": Date().timeIntervalSince1970
                ])

                // Request notification permission
                requestNotificationPermission {
                    flowController.navigateNext()
                }
            }
        }
        .onAppear {
            typeNextPhrase()
        }
    }

    private var frequencyLabel: String {
        let freq = Int(frequency)
        if freq == 1 {
            return "time per day"
        } else {
            return "times per day"
        }
    }

    private func requestNotificationPermission(completion: @escaping () -> Void) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            DispatchQueue.main.async {
                UserDefaults.standard.set(granted, forKey: "notifications_enabled")
                completion()
            }
        }
    }

    private func typeNextPhrase() {
        guard currentPhrase < phrases.count else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                withAnimation(.easeOut(duration: 0.4)) {
                    showSlider = true
                }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                withAnimation(.easeOut(duration: 0.4)) {
                    showButton = true
                }
            }
            return
        }

        let phrase = phrases[currentPhrase]
        let characters = Array(phrase)
        var charIndex = 0
        let typingSpeed = 0.04

        let lightGenerator = UIImpactFeedbackGenerator(style: .light)
        lightGenerator.prepare()

        Timer.scheduledTimer(withTimeInterval: typingSpeed, repeats: true) { timer in
            if charIndex < characters.count {
                displayedText.append(characters[charIndex])
                charIndex += 1

                if charIndex % 3 == 0 {
                    lightGenerator.impactOccurred()
                }
            } else {
                timer.invalidate()
                currentPhrase += 1

                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    typeNextPhrase()
                }
            }
        }
    }
}

// MARK: - Speech Bubble Shape

private struct SpeechBubbleShape: Shape {
    var tailOffset: CGFloat = 60
    var tailSize: CGFloat = 12
    var cornerRadius: CGFloat = 20

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let tailX = tailOffset
        let tailWidth: CGFloat = 16

        path.move(to: CGPoint(x: cornerRadius, y: tailSize))
        path.addLine(to: CGPoint(x: tailX, y: tailSize))
        path.addLine(to: CGPoint(x: tailX + tailWidth / 2, y: 0))
        path.addLine(to: CGPoint(x: tailX + tailWidth, y: tailSize))
        path.addLine(to: CGPoint(x: rect.width - cornerRadius, y: tailSize))

        path.addQuadCurve(to: CGPoint(x: rect.width, y: tailSize + cornerRadius), control: CGPoint(x: rect.width, y: tailSize))
        path.addLine(to: CGPoint(x: rect.width, y: rect.height - cornerRadius))
        path.addQuadCurve(to: CGPoint(x: rect.width - cornerRadius, y: rect.height), control: CGPoint(x: rect.width, y: rect.height))
        path.addLine(to: CGPoint(x: cornerRadius, y: rect.height))
        path.addQuadCurve(to: CGPoint(x: 0, y: rect.height - cornerRadius), control: CGPoint(x: 0, y: rect.height))
        path.addLine(to: CGPoint(x: 0, y: tailSize + cornerRadius))
        path.addQuadCurve(to: CGPoint(x: cornerRadius, y: tailSize), control: CGPoint(x: 0, y: tailSize))

        path.closeSubpath()
        return path
    }
}

struct CheckInFrequencyScreen_Previews: PreviewProvider {
    static var previews: some View {
        CheckInFrequencyScreen()
            .environmentObject(OnboardingFlowController())
    }
}
