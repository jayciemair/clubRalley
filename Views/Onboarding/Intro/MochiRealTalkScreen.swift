//
//  MochiRealTalkScreen.swift
//  Get Over Him
//
//  Mochi gets real - "Heartbreak sucks"
//

import SwiftUI

struct MochiRealTalkScreen: View {
    @EnvironmentObject var flowController: OnboardingFlowController

    @State private var displayedText: String = ""
    @State private var showButton: Bool = false
    @State private var currentPhrase: Int = 0

    // Phrases
    private let phrases: [String] = [
        "let's be real.",
        "heartbreak sucks.",
        "there's no way around it"
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

                    // Mochi - no animation
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
                        Text("let's be real.\n\nheartbreak sucks.\n\nthere's no way around it")
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

                    Spacer()
                }
            } continueAction: {
                flowController.saveData(for: "mochi_real_talk", data: [
                    "viewed": true,
                    "timestamp": Date().timeIntervalSince1970
                ])
                flowController.navigateNext()
            }
        }
        .onAppear {
            typeNextPhrase()
        }
    }

    private func typeNextPhrase() {
        guard currentPhrase < phrases.count else {
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
                if currentPhrase > 0 && charIndex == 0 {
                    displayedText.append("\n\n")
                }
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

struct MochiRealTalkScreen_Previews: PreviewProvider {
    static var previews: some View {
        MochiRealTalkScreen()
            .environmentObject(OnboardingFlowController())
    }
}
