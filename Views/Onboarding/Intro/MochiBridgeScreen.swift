//
//  MochiBridgeScreen.swift
//  Club Ralley
//
//  Bridge screen - Mochi acknowledges the user's name and asks about their situation
//

import SwiftUI

struct MochiBridgeScreen: View {
    @EnvironmentObject var flowController: OnboardingFlowController

    @State private var bubbleOpacity: Double = 0
    @State private var displayedText: String = ""
    @State private var showButton: Bool = false
    @State private var currentPhrase: Int = 0

    // Get user's name from flow controller
    private var userName: String {
        if let data = flowController.getData(for: "user_name"),
           let name = data["name"] as? String {
            return name
        }
        return "there"
    }

    // Phrases with pauses between them
    private var phrases: [String] {
        [
            "so \(userName),",
            "tell me a bit about what's going on"
        ]
    }

    var body: some View {
        ZStack {
            // Light from top-left, warm pink below
            OnboardingGradientBackground(style: .mochiWelcome, animated: true)

            OnboardingScrollableLayout(
                showBackButton: true,
                showContinueButton: showButton,
                backgroundColor: .clear
            ) {
                VStack(spacing: 0) {
                    Spacer()
                        .frame(height: 24)

                    // Mochi offset to the left - larger (no animation)
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

                    // Chat bubble with tail - fixed height so content below doesn't shift
                    ZStack(alignment: .topLeading) {
                        // Invisible placeholder for full text size
                        Text("so name,\n\ntell me a bit about what's going on")
                            .font(.custom("Satoshi-Medium", size: 24))
                            .foregroundColor(.clear)
                            .multilineTextAlignment(.leading)
                            .lineLimit(nil)
                            .fixedSize(horizontal: false, vertical: true)

                        // Actual displayed text
                        Text(displayedText)
                            .font(.custom("Satoshi-Medium", size: 24))
                            .foregroundColor(Color(hex: "#4A2040"))
                            .multilineTextAlignment(.leading)
                            .lineLimit(nil)
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
                    .opacity(bubbleOpacity)

                    Spacer()
                }
            } continueAction: {
                flowController.saveData(for: "mochi_bridge", data: [
                    "viewed": true,
                    "timestamp": Date().timeIntervalSince1970
                ])
                flowController.navigateNext()
            }
        }
        .onAppear {
            animateEntrance()
        }
    }

    private func animateEntrance() {
        // Show bubble and start typing immediately (Mochi already visible)
        withAnimation(.easeOut(duration: 0.3)) {
            bubbleOpacity = 1
        }
        typeNextPhrase()
    }

    private func typeNextPhrase() {
        guard currentPhrase < phrases.count else {
            // All phrases done - show button
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
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
                // Add character
                if currentPhrase > 0 && charIndex == 0 {
                    // Add newline before new phrases
                    displayedText.append("\n\n")
                }
                displayedText.append(characters[charIndex])
                charIndex += 1

                // Haptic on every few characters
                if charIndex % 3 == 0 {
                    lightGenerator.impactOccurred()
                }
            } else {
                timer.invalidate()
                currentPhrase += 1

                // Pause before next phrase
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    typeNextPhrase()
                }
            }
        }
    }
}

// MARK: - Speech Bubble Shape with Tail

private struct SpeechBubbleShape: Shape {
    var tailOffset: CGFloat = 60 // Distance from left edge
    var tailSize: CGFloat = 12
    var cornerRadius: CGFloat = 20

    func path(in rect: CGRect) -> Path {
        var path = Path()

        let tailX = tailOffset
        let tailWidth: CGFloat = 16

        // Start at top-left corner (after radius)
        path.move(to: CGPoint(x: cornerRadius, y: tailSize))

        // Tail pointing up
        path.addLine(to: CGPoint(x: tailX, y: tailSize))
        path.addLine(to: CGPoint(x: tailX + tailWidth / 2, y: 0))
        path.addLine(to: CGPoint(x: tailX + tailWidth, y: tailSize))

        // Top edge to top-right corner
        path.addLine(to: CGPoint(x: rect.width - cornerRadius, y: tailSize))

        // Top-right corner
        path.addQuadCurve(
            to: CGPoint(x: rect.width, y: tailSize + cornerRadius),
            control: CGPoint(x: rect.width, y: tailSize)
        )

        // Right edge
        path.addLine(to: CGPoint(x: rect.width, y: rect.height - cornerRadius))

        // Bottom-right corner
        path.addQuadCurve(
            to: CGPoint(x: rect.width - cornerRadius, y: rect.height),
            control: CGPoint(x: rect.width, y: rect.height)
        )

        // Bottom edge
        path.addLine(to: CGPoint(x: cornerRadius, y: rect.height))

        // Bottom-left corner
        path.addQuadCurve(
            to: CGPoint(x: 0, y: rect.height - cornerRadius),
            control: CGPoint(x: 0, y: rect.height)
        )

        // Left edge
        path.addLine(to: CGPoint(x: 0, y: tailSize + cornerRadius))

        // Top-left corner
        path.addQuadCurve(
            to: CGPoint(x: cornerRadius, y: tailSize),
            control: CGPoint(x: 0, y: tailSize)
        )

        path.closeSubpath()
        return path
    }
}

struct MochiBridgeScreen_Previews: PreviewProvider {
    static var previews: some View {
        MochiBridgeScreen()
            .environmentObject(OnboardingFlowController())
    }
}
