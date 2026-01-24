//
//  ModuleCompletionHUD.swift
//  Checkpoint
//
//  Full-screen confetti celebration HUD for completing a recovery module
//

import SwiftUI

struct ModuleCompletionHUD: View {

    // MARK: - Properties

    @Binding var isShowing: Bool
    let moduleTitle: String
    let moduleColor: Color
    let onDismiss: () -> Void

    @State private var opacity: Double = 0
    @State private var scale: CGFloat = 0.5
    @State private var confettiPieces: [ModuleConfettiPiece] = []

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
                    ModuleConfettiView(piece: piece)
                }
            }

            // Content
            VStack(spacing: AppTheme.Spacing.xl) {
                // Checkmark icon with module color
                ZStack {
                    Circle()
                        .fill(moduleColor)
                        .frame(width: 100, height: 100)

                    Image(systemName: "checkmark")
                        .font(.system(size: 48, weight: .bold))
                        .foregroundColor(.white)
                }
                .scaleEffect(scale)

                // Celebration text
                Text("Module Complete!")
                    .font(.custom("Satoshi-Bold", size: 32))
                    .foregroundColor(.white)

                // Tap to continue
                Text("Tap to continue")
                    .font(.custom("Satoshi-Regular", size: 16))
                    .foregroundColor(.white.opacity(0.6))
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

        // Launch confetti bursts with module color
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
            onDismiss()
        }
    }

    // MARK: - Confetti

    /// Generate confetti colors based on module color
    private func generateConfettiColors() -> [Color] {
        return [
            moduleColor,
            moduleColor.opacity(0.8),
            moduleColor.opacity(0.6),
            adjustBrightness(moduleColor, by: 0.2),
            adjustBrightness(moduleColor, by: -0.2),
            .white,
            .white.opacity(0.8),
            moduleColor.opacity(0.9)
        ]
    }

    /// Adjust color brightness
    private func adjustBrightness(_ color: Color, by amount: CGFloat) -> Color {
        let uiColor = UIColor(color)
        var hue: CGFloat = 0
        var saturation: CGFloat = 0
        var brightness: CGFloat = 0
        var alpha: CGFloat = 0

        uiColor.getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha)

        let newBrightness = max(0, min(1, brightness + amount))
        return Color(UIColor(hue: hue, saturation: saturation, brightness: newBrightness, alpha: alpha))
    }

    private func launchConfettiBursts() {
        let burstTimes: [Double] = [0.1, 0.35, 0.6]
        let confettiColors = generateConfettiColors()

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

                self.launchSingleBurst(burstNumber: index, colors: confettiColors)
            }
        }

        // Clear confetti after delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
            confettiPieces = []
        }
    }

    private func launchSingleBurst(burstNumber: Int, colors: [Color]) {
        var pieces: [ModuleConfettiPiece] = []
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

            pieces.append(ModuleConfettiPiece(
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

struct ModuleConfettiPiece: Identifiable {
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

struct ModuleConfettiView: View {
    let piece: ModuleConfettiPiece
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

struct ModuleCompletionHUDModifier: ViewModifier {
    @Binding var isShowing: Bool
    let moduleTitle: String
    let moduleColor: Color
    let onDismiss: () -> Void

    func body(content: Content) -> some View {
        content
            .overlay(
                Group {
                    if isShowing {
                        ModuleCompletionHUD(
                            isShowing: $isShowing,
                            moduleTitle: moduleTitle,
                            moduleColor: moduleColor,
                            onDismiss: onDismiss
                        )
                        .transition(.opacity)
                    }
                }
                .ignoresSafeArea(.all)
            )
    }
}

extension View {
    func moduleCompletionHUD(
        isShowing: Binding<Bool>,
        moduleTitle: String,
        moduleColor: Color,
        onDismiss: @escaping () -> Void
    ) -> some View {
        modifier(ModuleCompletionHUDModifier(
            isShowing: isShowing,
            moduleTitle: moduleTitle,
            moduleColor: moduleColor,
            onDismiss: onDismiss
        ))
    }
}

// MARK: - Preview

struct ModuleCompletionHUD_Previews: PreviewProvider {
    static var previews: some View {
        ModuleCompletionHUD(
            isShowing: .constant(true),
            moduleTitle: "Calming Techniques",
            moduleColor: Color(red: 0.85, green: 0.68, blue: 0.32), // Yellow/gold
            onDismiss: {}
        )
    }
}
