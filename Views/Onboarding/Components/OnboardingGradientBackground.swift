//
//  OnboardingGradientBackground.swift
//  Club Ralley
//
//  Gradient background view for onboarding screens — renders visual gradients
//

import SwiftUI

struct OnboardingGradientBackground: View {
    let style: OnboardingGradientStyle
    var animated: Bool = false

    @State private var animationPhase: CGFloat = 0
    @State private var pulsePhase: CGFloat = 1.0
    @State private var brightnessPhase: CGFloat = 0.75  // For breathing brightness

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                switch style.gradientType {
                case .radial:
                    radialGradientView(geometry: geometry)
                case .linear:
                    linearGradientView(geometry: geometry)
                case .diagonal:
                    diagonalGradientView(geometry: geometry)
                case .layeredRadial:
                    layeredRadialGradientView(geometry: geometry)
                case .sunrise:
                    sunriseGradientView(geometry: geometry)
                case .zigzagBeam:
                    zigzagBeamView(geometry: geometry)
                case .zigzagBeamSoft:
                    zigzagBeamSoftView(geometry: geometry)
                case .topLeftLight:
                    topLeftLightView(geometry: geometry)
                }
            }
        }
        .ignoresSafeArea()
        .onAppear {
            if animated {
                withAnimation(.easeInOut(duration: 4).repeatForever(autoreverses: true)) {
                    animationPhase = 1
                }
                // More noticeable pulse (1.0 → 1.2)
                withAnimation(.easeInOut(duration: 3).repeatForever(autoreverses: true)) {
                    pulsePhase = 1.2
                }
                // Breathing brightness (0.75 → 0.92)
                withAnimation(.easeInOut(duration: 3.5).repeatForever(autoreverses: true)) {
                    brightnessPhase = 0.92
                }
            }
        }
    }

    // MARK: - Linear Gradient View

    @ViewBuilder
    private func linearGradientView(geometry: GeometryProxy) -> some View {
        // Base gradient
        LinearGradient(
            colors: style.colors,
            startPoint: .top,
            endPoint: .bottom
        )

        // Optional glow effect at top
        RadialGradient(
            colors: [
                style.colors.first?.opacity(0.6) ?? .clear,
                .clear
            ],
            center: .init(x: 0.5, y: animated ? 0.1 + (animationPhase * 0.05) : 0.1),
            startRadius: 0,
            endRadius: geometry.size.width * 0.8
        )

        // Subtle bottom glow
        RadialGradient(
            colors: [
                style.colors.last?.opacity(0.4) ?? .clear,
                .clear
            ],
            center: .init(x: 0.5, y: 0.95),
            startRadius: 0,
            endRadius: geometry.size.width * 0.6
        )
    }

    // MARK: - Radial Gradient View

    @ViewBuilder
    private func radialGradientView(geometry: GeometryProxy) -> some View {
        let centerY: CGFloat = style == .spotlightGreen ? 0.35 : 0.45
        let maxDimension = max(geometry.size.width, geometry.size.height)

        // Deep black base
        Color(red: 0.01, green: 0.01, blue: 0.02)

        // Main radial gradient - the circular ring effect
        RadialGradient(
            colors: style.colors,
            center: .init(x: 0.5, y: centerY),
            startRadius: 0,
            endRadius: maxDimension * (animated ? (0.7 * pulsePhase) : 0.7)
        )
        .blendMode(.screen)

        // Secondary glow ring for depth
        RadialGradient(
            colors: [
                .clear,
                style.colors[safe: 2]?.opacity(0.3) ?? .clear,
                style.colors[safe: 1]?.opacity(0.2) ?? .clear,
                .clear
            ],
            center: .init(x: 0.5, y: centerY + 0.1),
            startRadius: maxDimension * 0.2,
            endRadius: maxDimension * 0.9
        )
        .blendMode(.plusLighter)

        // Top edge subtle glow
        if style == .spotlightGreen || style == .darkRadialTeal {
            RadialGradient(
                colors: [
                    style.colors[safe: 2]?.opacity(0.4) ?? .clear,
                    .clear
                ],
                center: .init(x: 0.5, y: -0.1),
                startRadius: 0,
                endRadius: geometry.size.width * 0.8
            )
        }

        // Bottom warm glow for tealToOrange-like effect
        if style == .darkRadialTeal || style == .spotlightGreen {
            RadialGradient(
                colors: [
                    Color(red: 0.3, green: 0.15, blue: 0.05).opacity(0.4),
                    .clear
                ],
                center: .init(x: 0.5, y: 1.1),
                startRadius: 0,
                endRadius: geometry.size.width * 0.7
            )
        }

        // Subtle vignette for depth
        RadialGradient(
            colors: [
                .clear,
                Color.black.opacity(0.3)
            ],
            center: .center,
            startRadius: maxDimension * 0.3,
            endRadius: maxDimension * 0.8
        )
    }

    // MARK: - Diagonal Gradient View (Growth, Rising)

    @ViewBuilder
    private func diagonalGradientView(geometry: GeometryProxy) -> some View {
        // Base diagonal - bottom-left to top-right (rising feeling)
        LinearGradient(
            colors: style.colors,
            startPoint: .bottomLeading,
            endPoint: .topTrailing
        )

        // Radial glow in upper area for depth
        RadialGradient(
            colors: [
                style.colors.last?.opacity(0.5) ?? .clear,
                style.colors.last?.opacity(0.2) ?? .clear,
                .clear
            ],
            center: .init(x: 0.7, y: 0.3),
            startRadius: 0,
            endRadius: geometry.size.width * 0.6
        )
        .blendMode(.plusLighter)

        // Subtle corner accents
        RadialGradient(
            colors: [
                style.colors.first?.opacity(0.4) ?? .clear,
                .clear
            ],
            center: .init(x: 0.1, y: 0.9),
            startRadius: 0,
            endRadius: geometry.size.width * 0.4
        )
    }

    // MARK: - Layered Radial Gradient View (Ceremonial, Important)

    @ViewBuilder
    private func layeredRadialGradientView(geometry: GeometryProxy) -> some View {
        let maxDimension = max(geometry.size.width, geometry.size.height)

        // Deep base
        Color(hex: "#080604")

        // Primary radial - center focus
        RadialGradient(
            colors: style.colors,
            center: .init(x: 0.5, y: 0.4),
            startRadius: 0,
            endRadius: maxDimension * 0.7
        )
        .blendMode(.screen)

        // Secondary ring - outer glow
        RadialGradient(
            colors: [
                .clear,
                style.colors[safe: 2]?.opacity(0.4) ?? .clear,
                style.colors[safe: 3]?.opacity(0.3) ?? .clear,
                .clear
            ],
            center: .init(x: 0.5, y: 0.5),
            startRadius: maxDimension * 0.3,
            endRadius: maxDimension * 0.9
        )
        .blendMode(.plusLighter)

        // Top accent glow
        RadialGradient(
            colors: [
                style.colors.last?.opacity(0.3) ?? .clear,
                .clear
            ],
            center: .init(x: 0.5, y: 0.1),
            startRadius: 0,
            endRadius: geometry.size.width * 0.5
        )
        .blendMode(.plusLighter)

        // Warm bottom glow
        RadialGradient(
            colors: [
                style.colors[safe: 3]?.opacity(0.4) ?? .clear,
                .clear
            ],
            center: .init(x: 0.5, y: 1.0),
            startRadius: 0,
            endRadius: geometry.size.width * 0.6
        )
    }

    // MARK: - Sunrise Gradient View (Hopeful, New Beginning)

    @ViewBuilder
    private func sunriseGradientView(geometry: GeometryProxy) -> some View {
        let maxDimension = max(geometry.size.width, geometry.size.height)
        let intensity = style.sunriseIntensity  // 0.25 to 1.0 based on stage

        // Scale factors based on intensity
        let orbSize = 0.3 + (intensity * 0.5)  // 0.3 to 0.8
        let orbBrightness = intensity  // 0.25 to 1.0
        let secondarySize = 0.2 + (intensity * 0.4)  // 0.2 to 0.6
        let ambientStrength = intensity * 0.2  // 0 to 0.2

        let isRose = style == .roseGlow

        // Dark base at top (night sky) - gets warmer with intensity
        LinearGradient(
            colors: isRose ? [
                Color(hex: "#0A0508"),
                Color(hex: "#1A0510").opacity(0.8 + (intensity * 0.2)),
                Color(hex: "#330A1A").opacity(0.5 + (intensity * 0.5)),
                Color(hex: "#4D1028").opacity(intensity)
            ] : [
                Color(hex: "#0A0505"),
                Color(hex: "#1A0A05").opacity(0.8 + (intensity * 0.2)),
                Color(hex: "#331505").opacity(0.5 + (intensity * 0.5)),
                Color(hex: "#4D2008").opacity(intensity)
            ],
            startPoint: .top,
            endPoint: .bottom
        )

        // Sun glow - radial from bottom center (breathing effect when animated)
        RadialGradient(
            colors: isRose ? [
                Color(hex: "#FF88BB").opacity((animated ? brightnessPhase + 0.1 : 0.9) * orbBrightness),
                Color(hex: "#FF44AA").opacity((animated ? brightnessPhase : 0.7) * orbBrightness),
                Color(hex: "#DD2288").opacity((animated ? brightnessPhase - 0.2 : 0.5) * orbBrightness),
                Color(hex: "#AA1166").opacity((animated ? brightnessPhase - 0.4 : 0.3) * orbBrightness),
                .clear
            ] : [
                Color(hex: "#FFDD88").opacity((animated ? brightnessPhase + 0.1 : 0.9) * orbBrightness),
                Color(hex: "#FFAA44").opacity((animated ? brightnessPhase : 0.7) * orbBrightness),
                Color(hex: "#FF6622").opacity((animated ? brightnessPhase - 0.2 : 0.5) * orbBrightness),
                Color(hex: "#CC3311").opacity((animated ? brightnessPhase - 0.4 : 0.3) * orbBrightness),
                .clear
            ],
            center: .init(x: 0.5, y: animated ? 0.85 - (animationPhase * 0.08) : 0.85),
            startRadius: 0,
            endRadius: maxDimension * (animated ? (orbSize * pulsePhase) : orbSize)
        )
        .blendMode(.plusLighter)

        // Secondary glow for depth (also breathes when animated)
        RadialGradient(
            colors: isRose ? [
                Color(hex: "#FFAADD").opacity((animated ? brightnessPhase - 0.25 : 0.4) * orbBrightness),
                Color(hex: "#FF77CC").opacity((animated ? brightnessPhase - 0.45 : 0.2) * orbBrightness),
                .clear
            ] : [
                Color(hex: "#FFEE99").opacity((animated ? brightnessPhase - 0.25 : 0.4) * orbBrightness),
                Color(hex: "#FFCC55").opacity((animated ? brightnessPhase - 0.45 : 0.2) * orbBrightness),
                .clear
            ],
            center: .init(x: 0.5, y: 0.9),
            startRadius: 0,
            endRadius: geometry.size.width * (animated ? (secondarySize * pulsePhase) : secondarySize)
        )
        .blendMode(.plusLighter)

        // Warm ambient overlay - scales with intensity
        LinearGradient(
            colors: isRose ? [
                .clear,
                Color(hex: "#FF55AA").opacity(ambientStrength * 0.75),
                Color(hex: "#FF77CC").opacity(ambientStrength)
            ] : [
                .clear,
                Color(hex: "#FFAA55").opacity(ambientStrength * 0.75),
                Color(hex: "#FFCC77").opacity(ambientStrength)
            ],
            startPoint: .top,
            endPoint: .bottom
        )

        // Soft vignette
        RadialGradient(
            colors: [
                .clear,
                Color.black.opacity(0.3 - (intensity * 0.1))  // Less vignette as it brightens
            ],
            center: .center,
            startRadius: maxDimension * 0.4,
            endRadius: maxDimension * 0.9
        )
    }

    // MARK: - Zigzag Beam View (Pink Lightning)

    @ViewBuilder
    private func zigzagBeamView(geometry: GeometryProxy) -> some View {
        // Dark base with pink hint
        Color(hex: "#100810")

        // First zigzag segment: top to upper-middle
        LinearGradient(
            colors: [
                Color(hex: "#D090D0").opacity(0.7),
                Color(hex: "#F0C0F0").opacity(0.5),
                .clear
            ],
            startPoint: .init(x: 0.3, y: 0),
            endPoint: .init(x: 0.6, y: 0.35)
        )
        .blendMode(.plusLighter)

        // Second zigzag segment: cuts back left
        LinearGradient(
            colors: [
                .clear,
                Color(hex: "#F0C0E0").opacity(0.6),
                Color(hex: "#FFE0F0").opacity(0.7),
                Color(hex: "#F0C0E0").opacity(0.6),
                .clear
            ],
            startPoint: .init(x: 0.6, y: 0.3),
            endPoint: .init(x: 0.25, y: 0.5)
        )
        .blendMode(.plusLighter)

        // Third zigzag segment: shoots down-right
        LinearGradient(
            colors: [
                .clear,
                Color(hex: "#E0B0D0").opacity(0.6),
                Color(hex: "#FFD0F0").opacity(0.7),
                Color(hex: "#D090C0").opacity(0.5)
            ],
            startPoint: .init(x: 0.25, y: 0.45),
            endPoint: .init(x: 0.7, y: 1.0)
        )
        .blendMode(.plusLighter)

        // Glow at the zigzag joints
        RadialGradient(
            colors: [
                Color(hex: "#FFFFFF").opacity(0.5),
                Color(hex: "#F0C0E0").opacity(0.3),
                .clear
            ],
            center: .init(x: 0.6, y: 0.33),
            startRadius: 0,
            endRadius: geometry.size.width * 0.2
        )
        .blendMode(.plusLighter)

        RadialGradient(
            colors: [
                Color(hex: "#FFFFFF").opacity(0.5),
                Color(hex: "#F0C0E0").opacity(0.3),
                .clear
            ],
            center: .init(x: 0.25, y: 0.48),
            startRadius: 0,
            endRadius: geometry.size.width * 0.2
        )
        .blendMode(.plusLighter)
    }

    // MARK: - Zigzag Beam Soft View (Bright Pink with Subtle Beams)

    @ViewBuilder
    private func zigzagBeamSoftView(geometry: GeometryProxy) -> some View {
        // Bright pink/rose gradient base using main color #FE9CDD
        LinearGradient(
            colors: [
                Color(hex: "#FFD0EB"),
                Color(hex: "#FE9CDD"),
                Color(hex: "#F080C8")
            ],
            startPoint: .top,
            endPoint: .bottom
        )

        // First zigzag segment: top to upper-middle (subtle)
        LinearGradient(
            colors: [
                Color(hex: "#FFFFFF").opacity(0.4),
                Color(hex: "#FFE0F0").opacity(0.3),
                .clear
            ],
            startPoint: .init(x: 0.3, y: 0),
            endPoint: .init(x: 0.6, y: 0.35)
        )
        .blendMode(.plusLighter)

        // Second zigzag segment: cuts back left (subtle)
        LinearGradient(
            colors: [
                .clear,
                Color(hex: "#FFFFFF").opacity(0.35),
                Color(hex: "#FFFFFF").opacity(0.45),
                Color(hex: "#FFFFFF").opacity(0.35),
                .clear
            ],
            startPoint: .init(x: 0.6, y: 0.3),
            endPoint: .init(x: 0.25, y: 0.5)
        )
        .blendMode(.plusLighter)

        // Third zigzag segment: shoots down-right (subtle)
        LinearGradient(
            colors: [
                .clear,
                Color(hex: "#FFFFFF").opacity(0.3),
                Color(hex: "#FFFFFF").opacity(0.4),
                Color(hex: "#FFE0F0").opacity(0.3)
            ],
            startPoint: .init(x: 0.25, y: 0.45),
            endPoint: .init(x: 0.7, y: 1.0)
        )
        .blendMode(.plusLighter)

        // Soft glow at the zigzag joints
        RadialGradient(
            colors: [
                Color(hex: "#FFFFFF").opacity(0.4),
                Color(hex: "#FFFFFF").opacity(0.2),
                .clear
            ],
            center: .init(x: 0.6, y: 0.33),
            startRadius: 0,
            endRadius: geometry.size.width * 0.12
        )
        .blendMode(.plusLighter)

        RadialGradient(
            colors: [
                Color(hex: "#FFFFFF").opacity(0.4),
                Color(hex: "#FFFFFF").opacity(0.2),
                .clear
            ],
            center: .init(x: 0.25, y: 0.48),
            startRadius: 0,
            endRadius: geometry.size.width * 0.12
        )
        .blendMode(.plusLighter)
    }

    // MARK: - Top Left Light View (Healing Welcome)

    @ViewBuilder
    private func topLeftLightView(geometry: GeometryProxy) -> some View {
        let maxDimension = max(geometry.size.width, geometry.size.height)

        // Base pink gradient - diagonal from top-left to bottom-right
        LinearGradient(
            colors: [
                Color(hex: "#FFF8FA"),
                Color(hex: "#FFE8F0"),
                Color(hex: "#FE9CDD"),
                Color(hex: "#F080C8")
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )

        // Strong light source from top-left corner
        RadialGradient(
            colors: [
                Color.white.opacity(animated ? 0.95 : 0.9),
                Color.white.opacity(animated ? 0.7 : 0.6),
                Color(hex: "#FFF0F5").opacity(0.4),
                .clear
            ],
            center: .init(x: 0.0, y: 0.0),
            startRadius: 0,
            endRadius: maxDimension * (animated ? 0.7 * pulsePhase : 0.65)
        )

        // Secondary soft glow for warmth
        RadialGradient(
            colors: [
                Color(hex: "#FFFFFF").opacity(0.5),
                Color(hex: "#FFE0EC").opacity(0.3),
                .clear
            ],
            center: .init(x: 0.15, y: 0.1),
            startRadius: 0,
            endRadius: maxDimension * 0.5
        )
        .blendMode(.plusLighter)

        // Subtle pink accent at bottom-right for depth
        RadialGradient(
            colors: [
                Color(hex: "#F080C8").opacity(0.3),
                Color(hex: "#FE9CDD").opacity(0.2),
                .clear
            ],
            center: .init(x: 0.9, y: 0.9),
            startRadius: 0,
            endRadius: maxDimension * 0.4
        )
    }
}

// MARK: - Safe Array Access

extension Array {
    subscript(safe index: Int) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

// MARK: - View Modifier for Easy Application

struct GradientBackgroundModifier: ViewModifier {
    let style: OnboardingGradientStyle
    var animated: Bool = false

    func body(content: Content) -> some View {
        ZStack {
            OnboardingGradientBackground(style: style, animated: animated)
            content
        }
    }
}

extension View {
    /// Apply a gradient background to any view
    func gradientBackground(_ style: OnboardingGradientStyle, animated: Bool = false) -> some View {
        modifier(GradientBackgroundModifier(style: style, animated: animated))
    }
}

// MARK: - Preview

#Preview("Dark Radial Teal") {
    OnboardingGradientBackground(style: .darkRadialTeal)
}

#Preview("Spotlight Green") {
    OnboardingGradientBackground(style: .spotlightGreen, animated: true)
}
