//
//  RecoveryGradientBackground.swift
//  Checkpoint
//
//  Calming gradient background for recovery program screens
//  Deep blue/purple tones that evoke peace and introspection
//

import SwiftUI

struct RecoveryGradientBackground: View {
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Base gradient - deep calming blues/purples
                LinearGradient(
                    stops: [
                        .init(color: Color(red: 0.06, green: 0.08, blue: 0.16), location: 0.0),
                        .init(color: Color(red: 0.08, green: 0.10, blue: 0.20), location: 0.2),
                        .init(color: Color(red: 0.12, green: 0.14, blue: 0.28), location: 0.4),
                        .init(color: Color(red: 0.18, green: 0.20, blue: 0.38), location: 0.6),
                        .init(color: Color(red: 0.22, green: 0.24, blue: 0.45), location: 0.8),
                        .init(color: Color(red: 0.15, green: 0.18, blue: 0.35), location: 1.0)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )

                // Subtle radial glow from top center - soft light source
                RadialGradient(
                    colors: [
                        Color(red: 0.3, green: 0.4, blue: 0.7).opacity(0.3),
                        Color(red: 0.2, green: 0.3, blue: 0.6).opacity(0.15),
                        Color.clear
                    ],
                    center: .init(x: 0.5, y: 0.1),
                    startRadius: 0,
                    endRadius: geometry.size.width * 0.8
                )
                .blendMode(.plusLighter)

                // Secondary glow - bottom accent
                RadialGradient(
                    colors: [
                        Color(red: 0.4, green: 0.3, blue: 0.6).opacity(0.15),
                        Color.clear
                    ],
                    center: .init(x: 0.3, y: 0.9),
                    startRadius: 0,
                    endRadius: geometry.size.width * 0.6
                )
                .blendMode(.plusLighter)
            }
        }
        .ignoresSafeArea()
    }
}

#Preview {
    RecoveryGradientBackground()
}
