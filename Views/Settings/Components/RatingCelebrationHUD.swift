//
//  RatingCelebrationHUD.swift
//  Checkpoint
//
//  Confetti celebration HUD that triggers App Store rating request
//

import SwiftUI

struct RatingCelebrationHUD: View {

    // MARK: - Properties

    @Binding var isShowing: Bool
    let onRequestReview: () -> Void

    @State private var confettiPieces: [RatingConfettiPiece] = []
    @State private var hasRequestedReview = false

    // MARK: - Body

    var body: some View {
        ZStack {
            // Confetti layer only - no background
            ForEach(confettiPieces) { piece in
                RatingConfettiView(piece: piece)
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

        // Request review 0.5 seconds after confetti starts
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            if !hasRequestedReview {
                hasRequestedReview = true
                onRequestReview()
            }
        }

        // Auto-dismiss after confetti finishes
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.5) {
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
        var pieces: [RatingConfettiPiece] = []
        let pieceCount = burstNumber == 1 ? 50 : 35
        let screenWidth = UIScreen.main.bounds.width
        let screenHeight = UIScreen.main.bounds.height

        for _ in 0..<pieceCount {
            // Random starting position at top of screen
            let startX = CGFloat.random(in: -screenWidth/2...screenWidth/2)
            let startY = CGFloat.random(in: -screenHeight/2 - 100 ... -screenHeight/4)

            // Fall down with some horizontal drift
            let endX = startX + CGFloat.random(in: -100...100)
            let endY = screenHeight/2 + CGFloat.random(in: 50...150)

            pieces.append(RatingConfettiPiece(
                id: UUID(),
                color: [
                    Color(red: 1.0, green: 0.84, blue: 0.0),  // Gold
                    Color(red: 0.85, green: 0.65, blue: 0.13), // Dark gold
                    Color.white,
                    Color.white.opacity(0.9)
                ].randomElement()!,
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

struct RatingConfettiPiece: Identifiable {
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

struct RatingConfettiView: View {
    let piece: RatingConfettiPiece
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

// MARK: - View Modifier

struct RatingCelebrationHUDModifier: ViewModifier {
    @Binding var isShowing: Bool
    let onRequestReview: () -> Void

    func body(content: Content) -> some View {
        content
            .overlay(
                Group {
                    if isShowing {
                        RatingCelebrationHUD(
                            isShowing: $isShowing,
                            onRequestReview: onRequestReview
                        )
                        .transition(.opacity)
                    }
                }
                .ignoresSafeArea(.all)
            )
    }
}

extension View {
    func ratingCelebrationHUD(
        isShowing: Binding<Bool>,
        onRequestReview: @escaping () -> Void
    ) -> some View {
        modifier(RatingCelebrationHUDModifier(
            isShowing: isShowing,
            onRequestReview: onRequestReview
        ))
    }
}
