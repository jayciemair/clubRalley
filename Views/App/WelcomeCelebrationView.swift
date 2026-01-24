//
//  WelcomeCelebrationView.swift
//  Get Over Him
//
//  Confetti celebration shown when user completes onboarding
//

import SwiftUI

struct WelcomeCelebrationView: View {

    // MARK: - Properties

    @Binding var isShowing: Bool

    @State private var confettiPieces: [WelcomeConfettiPiece] = []
    @State private var showMessage = false
    @State private var messageOpacity: Double = 0
    @State private var messageScale: CGFloat = 0.8

    // MARK: - Body

    var body: some View {
        ZStack {
            // Semi-transparent background
            Color.black.opacity(0.3)
                .ignoresSafeArea()
                .allowsHitTesting(false)

            // Welcome message
            if showMessage {
                VStack(spacing: 16) {
                    Text("you're in")
                        .font(.custom("Satoshi-Bold", size: 32))
                        .foregroundColor(.white)

                    Text("let's get you over him")
                        .font(.custom("Satoshi-Medium", size: 18))
                        .foregroundColor(.white.opacity(0.8))
                }
                .scaleEffect(messageScale)
                .opacity(messageOpacity)
            }

            // Confetti layer
            ForEach(confettiPieces) { piece in
                WelcomeConfettiItemView(piece: piece)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .allowsHitTesting(false)
        .onAppear {
            showCelebration()
        }
    }

    // MARK: - Animations

    private func showCelebration() {
        // Trigger haptic feedback
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)

        // Launch confetti bursts
        launchConfettiBursts()

        // Show message after a beat
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            showMessage = true
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                messageOpacity = 1
                messageScale = 1
            }
        }

        // Fade out message
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            withAnimation(.easeOut(duration: 0.4)) {
                messageOpacity = 0
                messageScale = 0.9
            }
        }

        // Auto-dismiss after confetti finishes
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            isShowing = false
        }
    }

    // MARK: - Confetti

    private func launchConfettiBursts() {
        let burstTimes: [Double] = [0.1, 0.35, 0.6]

        let mediumGenerator = UIImpactFeedbackGenerator(style: .medium)
        let heavyGenerator = UIImpactFeedbackGenerator(style: .heavy)
        mediumGenerator.prepare()
        heavyGenerator.prepare()

        for (index, delay) in burstTimes.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                if index == 1 {
                    heavyGenerator.impactOccurred()
                } else {
                    mediumGenerator.impactOccurred()
                }

                self.launchSingleBurst(burstNumber: index)
            }
        }

        // Clear confetti after delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            confettiPieces = []
        }
    }

    private func launchSingleBurst(burstNumber: Int) {
        var pieces: [WelcomeConfettiPiece] = []
        let pieceCount = burstNumber == 1 ? 50 : 35
        let screenWidth = UIScreen.main.bounds.width
        let screenHeight = UIScreen.main.bounds.height

        // Pink/rose color palette matching the app theme
        let colors: [Color] = [
            Color(hex: "#E080C0"),       // Primary pink
            Color(hex: "#F0A0D0"),       // Light pink
            Color(hex: "#D060A0"),       // Deep pink
            Color.white,
            Color.white.opacity(0.9)
        ]

        for _ in 0..<pieceCount {
            // Random starting position at top of screen
            let startX = CGFloat.random(in: -screenWidth/2...screenWidth/2)
            let startY = CGFloat.random(in: -screenHeight/2 - 100 ... -screenHeight/4)

            // Fall down with some horizontal drift
            let endX = startX + CGFloat.random(in: -100...100)
            let endY = screenHeight/2 + CGFloat.random(in: 50...150)

            pieces.append(WelcomeConfettiPiece(
                id: UUID(),
                color: colors.randomElement()!,
                startX: startX,
                startY: startY,
                endX: endX,
                endY: endY,
                rotation: Double.random(in: 360...1080),
                scale: CGFloat.random(in: 0.5...1.2),
                animationDelay: Double.random(in: 0...0.1),
                shapeType: Int.random(in: 0...2)
            ))
        }

        confettiPieces.append(contentsOf: pieces)
    }
}

// MARK: - Confetti Models

struct WelcomeConfettiPiece: Identifiable {
    let id: UUID
    let color: Color
    let startX: CGFloat
    let startY: CGFloat
    let endX: CGFloat
    let endY: CGFloat
    let rotation: Double
    let scale: CGFloat
    let animationDelay: Double
    let shapeType: Int
}

struct WelcomeConfettiItemView: View {
    let piece: WelcomeConfettiPiece
    @State private var animate = false

    var body: some View {
        Group {
            if piece.shapeType == 0 {
                Circle()
                    .fill(piece.color)
                    .frame(width: 10, height: 10)
            } else if piece.shapeType == 1 {
                RoundedRectangle(cornerRadius: 2)
                    .fill(piece.color)
                    .frame(width: 14, height: 7)
            } else {
                Rectangle()
                    .fill(piece.color)
                    .frame(width: 12, height: 12)
            }
        }
        .scaleEffect(animate ? piece.scale * 0.3 : piece.scale)
        .rotationEffect(.degrees(animate ? piece.rotation : 0))
        .offset(x: animate ? piece.endX : piece.startX,
                y: animate ? piece.endY : piece.startY)
        .opacity(animate ? 0 : 1)
        .onAppear {
            withAnimation(.easeOut(duration: 3.5).delay(piece.animationDelay)) {
                animate = true
            }
        }
    }
}

// MARK: - Preview

struct WelcomeCelebrationView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            WelcomeCelebrationView(isShowing: .constant(true))
        }
    }
}
