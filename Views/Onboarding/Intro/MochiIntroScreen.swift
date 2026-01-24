//
//  MochiIntroScreen.swift
//  Get Over Him
//
//  Mochi introduces herself and asks for the user's name
//

import SwiftUI

struct MochiIntroScreen: View {
    @EnvironmentObject var flowController: OnboardingFlowController

    @State private var mochiOpacity: Double = 0
    @State private var mochiScale: CGFloat = 0.8
    @State private var bubbleOpacity: Double = 0
    @State private var displayedText: String = ""
    @State private var showNameInput: Bool = false
    @State private var showButton: Bool = false
    @State private var currentPhrase: Int = 0
    @State private var nameText: String = ""
    @FocusState private var isTextFieldFocused: Bool

    // Phrases with pauses between them
    private let phrases = [
        "hi, i'm mochi :)",
        "i'm here to help you get over him.",
        "what should i call you"
    ]

    var body: some View {
        ZStack {
            // Light from top-left, warm pink below - healing/welcoming
            OnboardingGradientBackground(style: .mochiWelcome, animated: true)

            OnboardingScrollableLayout(
                showBackButton: false,
                showContinueButton: showButton && !nameText.trimmingCharacters(in: .whitespaces).isEmpty,
                backgroundColor: .clear
            ) {
                VStack(spacing: 0) {
                    Spacer()
                        .frame(height: 24)

                    // Mochi with chat bubble - left aligned
                    HStack(alignment: .top, spacing: 16) {
                        // Mochi image on left
                        Image("Mochi")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 100, height: 100)
                            .scaleEffect(mochiScale)
                            .opacity(mochiOpacity)

                        // Chat bubble
                        if bubbleOpacity > 0 {
                            VStack(alignment: .leading) {
                                Text(displayedText)
                                    .font(.custom("Satoshi-Medium", size: 18))
                                    .foregroundColor(Color(hex: "#4A2040"))
                                    .multilineTextAlignment(.leading)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            .padding(.horizontal, 18)
                            .padding(.vertical, 14)
                            .background(
                                ChatBubbleShape()
                                    .fill(Color.white.opacity(0.7))
                            )
                            .overlay(
                                ChatBubbleShape()
                                    .stroke(Color(hex: "#E080C0").opacity(0.5), lineWidth: 1.5)
                            )
                            .frame(maxWidth: 220, alignment: .leading)
                            .opacity(bubbleOpacity)
                        }

                        Spacer()
                    }
                    .padding(.horizontal, AppTheme.Spacing.lg)

                    // Name input field - always in layout, fades in
                    VStack(spacing: 12) {
                        TextField("your name", text: $nameText)
                            .font(.custom("Satoshi-Bold", size: 32))
                            .foregroundColor(Color(hex: "#4A2040"))
                            .multilineTextAlignment(.center)
                            .focused($isTextFieldFocused)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 20)
                            .background(
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(Color.white.opacity(0.6))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(isTextFieldFocused ? Color(hex: "#FE9CDD") : Color.white.opacity(0.3), lineWidth: 2)
                            )
                            .onChange(of: nameText) { newValue in
                                let lowercased = newValue.lowercased()
                                if lowercased != newValue || newValue.count > 20 {
                                    nameText = String(lowercased.prefix(20))
                                }
                            }
                            .disabled(!showNameInput)
                    }
                    .padding(.horizontal, AppTheme.Spacing.xl)
                    .padding(.top, 40)
                    .opacity(showNameInput ? 1 : 0)

                    Spacer()
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    isTextFieldFocused = false
                }
            } continueAction: {
                let trimmedName = nameText.trimmingCharacters(in: .whitespaces)
                guard !trimmedName.isEmpty else { return }

                flowController.saveData(for: "user_name", data: [
                    "name": trimmedName,
                    "timestamp": Date().timeIntervalSince1970
                ])
                flowController.saveData(for: "mochi_intro", data: [
                    "viewed": true,
                    "timestamp": Date().timeIntervalSince1970
                ])
                flowController.navigateNext()
            }
        }
        .ignoresSafeArea(.keyboard)
        .onAppear {
            // Restore saved name if exists
            if let data = flowController.getData(for: "user_name"),
               let savedName = data["name"] as? String {
                nameText = savedName
            }
            animateEntrance()
        }
    }

    private func animateEntrance() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.prepare()

        // Mochi appears first
        withAnimation(.spring(response: 0.7, dampingFraction: 0.7)) {
            mochiScale = 1
            mochiOpacity = 1
        }
        generator.impactOccurred()

        // Show bubble and start typing
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation(.easeOut(duration: 0.3)) {
                bubbleOpacity = 1
            }
            typeNextPhrase()
        }
    }

    private func typeNextPhrase() {
        guard currentPhrase < phrases.count else {
            // All phrases done - show name input and button
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                withAnimation(.easeOut(duration: 0.4)) {
                    showNameInput = true
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

// MARK: - Chat Bubble Shape

private struct ChatBubbleShape: Shape {
    func path(in rect: CGRect) -> Path {
        let radius: CGFloat = 16
        let tailSize: CGFloat = 10

        var path = Path()

        // Main bubble (rounded rect)
        let bubbleRect = CGRect(
            x: tailSize,
            y: 0,
            width: rect.width - tailSize,
            height: rect.height
        )

        path.addRoundedRect(in: bubbleRect, cornerSize: CGSize(width: radius, height: radius))

        // Tail pointing left
        path.move(to: CGPoint(x: tailSize, y: 20))
        path.addLine(to: CGPoint(x: 0, y: 28))
        path.addLine(to: CGPoint(x: tailSize, y: 36))

        return path
    }
}

struct MochiIntroScreen_Previews: PreviewProvider {
    static var previews: some View {
        MochiIntroScreen()
            .environmentObject(OnboardingFlowController())
    }
}
