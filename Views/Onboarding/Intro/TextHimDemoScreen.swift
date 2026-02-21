//
//  TextHimDemoScreen.swift
//  Club Ralley
//
//  Shows the mock "hey" text left on read
//

import SwiftUI
import StoreKit

struct TextHimDemoScreen: View {
    @EnvironmentObject var flowController: OnboardingFlowController

    @State private var statusText: String = "Last seen 2 minutes ago"
    @State private var statusColor: Color = .gray
    @State private var showMessage: Bool = false
    @State private var showReadReceipt: Bool = false
    @State private var showScreenshotAlert: Bool = false
    @State private var showBottomText: Bool = false
    @State private var showButton: Bool = false
    @State private var hasSentMessage: Bool = false
    @State private var showScreenshotFlash: Bool = false
    @State private var bottomTextPart1: String = ""
    @State private var bottomTextPart2: String = ""

    var body: some View {
        ZStack {
            // Dark/grey background for chat vibe
            Color(hex: "#1C1C1E")
                .ignoresSafeArea()

            OnboardingScrollableLayout(
                showBackButton: false,
                showContinueButton: showButton,
                backgroundColor: .clear
            ) {
                VStack(spacing: 0) {
                    // Chat header - always visible
                    HStack(spacing: 12) {
                        // Trash can avatar (he belongs in the trash)
                        ZStack {
                            Circle()
                                .fill(Color(red: 1.0, green: 0.61, blue: 0.87).opacity(0.15))
                                .frame(width: 44, height: 44)

                            Image(systemName: "trash.fill")
                                .font(.system(size: 20))
                                .foregroundColor(Color(red: 1.0, green: 0.61, blue: 0.87))
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text("him")
                                .font(.custom("Satoshi-Bold", size: 18))
                                .foregroundColor(.white)

                            Text(statusText)
                                .font(.custom("Satoshi-Regular", size: 12))
                                .foregroundColor(statusColor)
                        }

                        Spacer()
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 20)
                    .padding(.bottom, 16)

                    Divider()
                        .background(Color.gray.opacity(0.3))

                    Spacer()
                        .frame(height: 60)

                    // The "hey" message bubble (sent by user, right side)
                    if showMessage {
                        HStack {
                            Spacer()

                            VStack(alignment: .trailing, spacing: 4) {
                                Text("hey")
                                    .font(.custom("Satoshi-Medium", size: 17))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 10)
                                    .background(Color(hex: "#E080C0"))
                                    .clipShape(RoundedRectangle(cornerRadius: 18))

                                // Read receipt
                                if showReadReceipt {
                                    Text("Read 11:04 PM")
                                        .font(.custom("Satoshi-Regular", size: 11))
                                        .foregroundColor(.gray)
                                }
                            }
                        }
                        .padding(.horizontal, 24)
                    }

                    // Screenshot alert
                    if showScreenshotAlert {
                        HStack(spacing: 8) {
                            Image(systemName: "camera.fill")
                                .font(.system(size: 14))
                                .foregroundColor(.gray)

                            Text("he screenshotted your message and sent it to his group chat...")
                                .font(.custom("Satoshi-Regular", size: 14))
                                .foregroundColor(.gray)
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 16)
                    }

                    // Bottom message - appears below screenshot alert
                    if showBottomText {
                        VStack(spacing: 4) {
                            Text(bottomTextPart1)
                                .font(.custom("Satoshi-Medium", size: 18))
                                .foregroundColor(.white)
                                .multilineTextAlignment(.center)

                            Text(bottomTextPart2)
                                .font(.custom("Satoshi-Medium", size: 18))
                                .foregroundColor(.white)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.horizontal, 32)
                        .padding(.top, 48)
                    }

                    Spacer()

                    // Replay button
                    if showButton {
                        Button(action: {
                            replaySequence()
                        }) {
                            Image(systemName: "arrow.counterclockwise")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.white.opacity(0.7))
                                .frame(width: 44, height: 44)
                                .background(Color.white.opacity(0.1))
                                .clipShape(Circle())
                        }
                        .padding(.bottom, 12)
                    }
                }
            } continueAction: {
                flowController.saveData(for: "text_him_demo", data: [
                    "viewed": true,
                    "timestamp": Date().timeIntervalSince1970
                ])
                flowController.navigateNext()
            }

            // Input area fixed at bottom (before message is sent)
            if !hasSentMessage {
                VStack {
                    Spacer()

                    HStack(spacing: 12) {
                        // Message input field
                        HStack {
                            Text("hey")
                                .font(.custom("Satoshi-Medium", size: 17))
                                .foregroundColor(.white)
                            Spacer()
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(Color(hex: "#2C2C2E"))
                        .clipShape(RoundedRectangle(cornerRadius: 20))

                        // Send button
                        Button(action: {
                            hasSentMessage = true
                            animateSequence()
                        }) {
                            Image(systemName: "arrow.up.circle.fill")
                                .font(.system(size: 32))
                                .foregroundColor(Color(hex: "#E080C0"))
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 40)
                }
            }
        }
        // Screenshot flash overlay
        .overlay(
            Color.white
                .ignoresSafeArea()
                .opacity(showScreenshotFlash ? 1 : 0)
        )
    }

    private func replaySequence() {
        // Reset all state
        withAnimation(.easeOut(duration: 0.2)) {
            showMessage = false
            showReadReceipt = false
            showScreenshotAlert = false
            showBottomText = false
            showButton = false
            hasSentMessage = false
        }
        statusText = "Last seen 2 minutes ago"
        statusColor = .gray
        bottomTextPart1 = ""
        bottomTextPart2 = ""
    }

    private func animateSequence() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.prepare()

        // Initial pause before animation starts
        let startDelay: Double = 0.8

        // Show the "hey" message after pause
        DispatchQueue.main.asyncAfter(deadline: .now() + startDelay) {
            generator.impactOccurred()
            withAnimation(.easeOut(duration: 0.2)) {
                self.showMessage = true
            }
        }

        // Change to "Active now" (he sees it)
        DispatchQueue.main.asyncAfter(deadline: .now() + startDelay + 1.5) {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            self.statusText = "Active now"
            self.statusColor = .green
        }

        // Show read receipt (the painful moment)
        DispatchQueue.main.asyncAfter(deadline: .now() + startDelay + 3.0) {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            self.showReadReceipt = true
        }

        // Screenshot flash effect
        DispatchQueue.main.asyncAfter(deadline: .now() + startDelay + 4.5) {
            UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
            withAnimation(.easeIn(duration: 0.05)) {
                self.showScreenshotFlash = true
            }
            // Fade out the flash
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.easeOut(duration: 0.2)) {
                    self.showScreenshotFlash = false
                }
            }
        }

        // Show screenshot alert (after flash)
        DispatchQueue.main.asyncAfter(deadline: .now() + startDelay + 4.8) {
            withAnimation(.easeOut(duration: 0.3)) {
                self.showScreenshotAlert = true
            }
        }

        // Show bottom text with typing animation
        DispatchQueue.main.asyncAfter(deadline: .now() + startDelay + 6.3) {
            showBottomText = true
            typeTextPart1("yeah...") {
                // Pause after "yeah..."
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                    typeTextPart2("that's usually how it goes.") {
                        // Request App Store rating right after the emotional moment
                        requestAppReview()

                        // Show continue button after rating prompt
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                            withAnimation(.easeOut(duration: 0.3)) {
                                showButton = true
                            }
                        }
                    }
                }
            }
        }
    }

    private func typeTextPart1(_ text: String, completion: @escaping () -> Void) {
        let characters = Array(text)
        let lightGenerator = UIImpactFeedbackGenerator(style: .light)
        lightGenerator.prepare()

        for (index, character) in characters.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 0.04) {
                bottomTextPart1.append(character)
                if index % 3 == 0 {
                    lightGenerator.impactOccurred()
                }
                if index == characters.count - 1 {
                    completion()
                }
            }
        }
    }

    private func typeTextPart2(_ text: String, completion: @escaping () -> Void) {
        let characters = Array(text)
        let lightGenerator = UIImpactFeedbackGenerator(style: .light)
        lightGenerator.prepare()

        for (index, character) in characters.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 0.04) {
                bottomTextPart2.append(character)
                if index % 3 == 0 {
                    lightGenerator.impactOccurred()
                }
                if index == characters.count - 1 {
                    completion()
                }
            }
        }
    }

    private func requestAppReview() {
        if let windowScene = UIApplication.shared.connectedScenes
            .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene {
            SKStoreReviewController.requestReview(in: windowScene)
        }
    }
}

struct TextHimDemoScreen_Previews: PreviewProvider {
    static var previews: some View {
        TextHimDemoScreen()
            .environmentObject(OnboardingFlowController())
    }
}
