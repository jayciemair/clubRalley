//
//  BreathingEntryView.swift
//  Checkpoint
//
//  Simple breathing animation entry for recovery program
//

import SwiftUI

struct BreathingEntryView: View {
    let onComplete: () -> Void

    @State private var scale: CGFloat = 0.8
    @State private var opacity: Double = 0.3
    @State private var phase: String = "Breathe in..."

    var body: some View {
        ZStack {
            // Background
            RecoveryGradientBackground()

            VStack(spacing: 40) {
                Spacer()

                // Breathing circle
                ZStack {
                    Circle()
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.4, green: 0.5, blue: 0.9).opacity(0.3),
                                    Color(red: 0.5, green: 0.4, blue: 0.8).opacity(0.3)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 2
                        )
                        .frame(width: 200, height: 200)
                        .scaleEffect(scale)
                        .opacity(opacity)

                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.4, green: 0.5, blue: 0.9),
                                    Color(red: 0.3, green: 0.4, blue: 0.8)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 120, height: 120)
                        .scaleEffect(scale)
                }

                // Text
                Text(phase)
                    .font(.custom("Satoshi-Bold", size: 28))
                    .foregroundColor(.white)

                Spacer()
            }
        }
        .onAppear {
            // Breathe in
            withAnimation(.easeInOut(duration: 3.0)) {
                scale = 1.2
                opacity = 0.6
            }

            // Breathe out
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                phase = "Breathe out..."
                withAnimation(.easeInOut(duration: 3.0)) {
                    scale = 0.8
                    opacity = 0.3
                }
            }

            // Done - go to recovery
            DispatchQueue.main.asyncAfter(deadline: .now() + 6.0) {
                withAnimation(.easeOut(duration: 0.5)) {
                    onComplete()
                }
            }
        }
    }
}

#Preview {
    BreathingEntryView(onComplete: {})
}
