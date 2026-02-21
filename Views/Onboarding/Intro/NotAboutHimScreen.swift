//
//  NotAboutHimScreen.swift
//  Club Ralley
//
//  Funny screen - we're not asking about his name
//

import SwiftUI

struct NotAboutHimScreen: View {
    @EnvironmentObject var flowController: OnboardingFlowController

    @State private var mochiOpacity: Double = 0
    @State private var mochiScale: CGFloat = 0.8
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

    // Phrases
    private var phrases: [String] {
        [
            "so \(userName)... what's his name?",
            "just kidding 😉",
            "i mean, the app is called club ralley...",
            "but this is about YOU, not him 💕"
        ]
    }

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

                    // Mochi offset to the left
                    HStack {
                        Image("Mochi")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 180, height: 180)
                            .scaleEffect(mochiScale)
                            .opacity(mochiOpacity)
                        Spacer()
                    }
                    .padding(.leading, 24)

                    Spacer()
                        .frame(height: 8)

                    // Chat bubble with tail - fixed height so content below doesn't shift
                    ZStack(alignment: .topLeading) {
                        // Invisible placeholder for full text size
                        Text("so name... what's his name?\n\njust kidding 😉\n\ni mean, the app is called club ralley...\n\nbut this is about YOU, not him 💕")
                            .font(.custom("Satoshi-Medium", size: 22))
                            .foregroundColor(.clear)
                            .multilineTextAlignment(.leading)
                            .lineLimit(nil)
                            .fixedSize(horizontal: false, vertical: true)

                        // Actual displayed text
                        Text(displayedText)
                            .font(.custom("Satoshi-Medium", size: 22))
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
                flowController.saveData(for: "not_about_him", data: [
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
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.prepare()

        withAnimation(.spring(response: 0.7, dampingFraction: 0.7)) {
            mochiScale = 1
            mochiOpacity = 1
        }
        generator.impactOccurred()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation(.easeOut(duration: 0.3)) {
                bubbleOpacity = 1
            }
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

// MARK: - Speech Bubble Shape with Tail

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

        path.addQuadCurve(
            to: CGPoint(x: rect.width, y: tailSize + cornerRadius),
            control: CGPoint(x: rect.width, y: tailSize)
        )

        path.addLine(to: CGPoint(x: rect.width, y: rect.height - cornerRadius))

        path.addQuadCurve(
            to: CGPoint(x: rect.width - cornerRadius, y: rect.height),
            control: CGPoint(x: rect.width, y: rect.height)
        )

        path.addLine(to: CGPoint(x: cornerRadius, y: rect.height))

        path.addQuadCurve(
            to: CGPoint(x: 0, y: rect.height - cornerRadius),
            control: CGPoint(x: 0, y: rect.height)
        )

        path.addLine(to: CGPoint(x: 0, y: tailSize + cornerRadius))

        path.addQuadCurve(
            to: CGPoint(x: cornerRadius, y: tailSize),
            control: CGPoint(x: 0, y: tailSize)
        )

        path.closeSubpath()
        return path
    }
}

struct NotAboutHimScreen_Previews: PreviewProvider {
    static var previews: some View {
        NotAboutHimScreen()
            .environmentObject(OnboardingFlowController())
    }
}
