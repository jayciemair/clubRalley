//
//  AppGradientBackground.swift
//  Checkpoint
//
//  Subtle background gradient for main app tabs
//

import SwiftUI

struct AppGradientBackground: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                if colorScheme == .dark {
                    // Dark mode - nearly black like onboarding (#1C1C1E)
                    Color(red: 0.11, green: 0.11, blue: 0.12)
                } else {
                    // Light mode - bright pink gradient
                    LinearGradient(
                        colors: [
                            Color(red: 1.0, green: 0.82, blue: 0.90),   // Light pink top #FFD0E6
                            Color(red: 1.0, green: 0.61, blue: 0.87),   // Main pink #FE9CDD
                            Color(red: 0.94, green: 0.50, blue: 0.78),  // Deeper pink #F080C8
                            Color(red: 0.85, green: 0.40, blue: 0.68)   // Rich pink bottom #D966AD
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )

                    // Soft white glow from top-left
                    RadialGradient(
                        colors: [
                            Color.white.opacity(0.6),
                            Color.white.opacity(0.3),
                            Color.clear
                        ],
                        center: .init(x: 0.1, y: 0.0),
                        startRadius: 0,
                        endRadius: geometry.size.height * 0.5
                    )

                    // Subtle lighter accent
                    RadialGradient(
                        colors: [
                            Color.white.opacity(0.2),
                            Color.clear
                        ],
                        center: .init(x: 0.8, y: 0.3),
                        startRadius: 0,
                        endRadius: geometry.size.width * 0.4
                    )
                }
            }
        }
        .ignoresSafeArea()
    }
}

#Preview {
    ZStack {
        AppGradientBackground()

        Text("Content")
            .foregroundColor(.white)
    }
}
