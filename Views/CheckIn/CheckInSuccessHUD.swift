//
//  CheckInSuccessHUD.swift
//  Checkpoint
//
//  Full-screen confetti celebration HUD for successful daily check-in
//

import SwiftUI

struct CheckInSuccessHUD: View {

    // MARK: - Properties

    @Binding var isShowing: Bool
    let dayNumber: Int
    let checkInStreak: Int

    @State private var opacity: Double = 0
    @State private var scale: CGFloat = 0.5
    @State private var confettiPieces: [CheckInConfettiPiece] = []

    // MARK: - Body

    var body: some View {
        ZStack {
            // Dark background overlay
            Color.black.opacity(0.92)
                .ignoresSafeArea(.all, edges: .all)
                .opacity(opacity)

            // Confetti layer
            ZStack {
                ForEach(confettiPieces) { piece in
                    CheckInConfettiView(piece: piece)
                }
            }

            // Content
            VStack(spacing: AppTheme.Spacing.xl) {
                // Checkmark icon
                ZStack {
                    Circle()
                        .fill(AppTheme.Colors.success)
                        .frame(width: 100, height: 100)

                    Image(systemName: "checkmark")
                        .font(.system(size: 48, weight: .bold))
                        .foregroundColor(.white)
                }
                .scaleEffect(scale)

                // Celebration text
                VStack(spacing: AppTheme.Spacing.sm) {
                    Text("Day \(dayNumber) Complete!")
                        .font(.custom("Satoshi-Bold", size: 32))
                        .foregroundColor(.white)

                    if checkInStreak > 1 {
                        Text("\(checkInStreak) day check-in streak")
                            .font(.custom("Satoshi-Medium", size: 18))
                            .foregroundColor(.white.opacity(0.8))
                    } else {
                        Text("You're doing great!")
                            .font(.custom("Satoshi-Medium", size: 18))
                            .foregroundColor(.white.opacity(0.8))
                    }
                }

                // Tap to continue
                Text("Tap to continue")
                    .font(.custom("Satoshi-Regular", size: 16))
                    .foregroundColor(.white.opacity(0.6))
                    .padding(.top, AppTheme.Spacing.lg)
            }
            .opacity(opacity)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            showCelebration()
        }
        .onTapGesture {
            dismiss()
        }
    }

    // MARK: - Animations

    private func showCelebration() {
        // Trigger haptic feedback
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)

        // Animate in
        withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
            scale = 1.0
        }

        withAnimation(.easeOut(duration: 0.4)) {
            opacity = 1.0
        }

        // Launch confetti bursts
        launchConfettiBursts()
    }

    private func dismiss() {
        // Animate out
        withAnimation(.easeIn(duration: 0.2)) {
            opacity = 0.0
            scale = 0.9
        }

        // Dismiss after animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
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
        DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
            confettiPieces = []
        }
    }

    private func launchSingleBurst(burstNumber: Int) {
        var pieces: [CheckInConfettiPiece] = []
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

            pieces.append(CheckInConfettiPiece(
                id: UUID(),
                color: [
                    AppTheme.Colors.success,
                    Color.green.opacity(0.8),
                    Color.yellow,
                    Color.green,
                    Color.mint,
                    Color.teal,
                    Color.cyan,
                    Color.white
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

struct CheckInConfettiPiece: Identifiable {
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

struct CheckInConfettiView: View {
    let piece: CheckInConfettiPiece
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
            withAnimation(.easeOut(duration: 2.0).delay(piece.animationDelay)) {
                animate = true
            }
        }
    }
}

// MARK: - View Modifier

struct CheckInSuccessHUDModifier: ViewModifier {
    @Binding var isShowing: Bool
    let dayNumber: Int
    let checkInStreak: Int

    func body(content: Content) -> some View {
        content
            .overlay(
                Group {
                    if isShowing {
                        CheckInSuccessHUD(
                            isShowing: $isShowing,
                            dayNumber: dayNumber,
                            checkInStreak: checkInStreak
                        )
                        .transition(.opacity)
                    }
                }
                .ignoresSafeArea(.all)
            )
    }
}

extension View {
    func checkInSuccessHUD(
        isShowing: Binding<Bool>,
        dayNumber: Int,
        checkInStreak: Int
    ) -> some View {
        modifier(CheckInSuccessHUDModifier(
            isShowing: isShowing,
            dayNumber: dayNumber,
            checkInStreak: checkInStreak
        ))
    }
}

// MARK: - Preview

struct CheckInSuccessHUD_Previews: PreviewProvider {
    static var previews: some View {
        CheckInSuccessHUD(
            isShowing: .constant(true),
            dayNumber: 248,
            checkInStreak: 45
        )
    }
}
