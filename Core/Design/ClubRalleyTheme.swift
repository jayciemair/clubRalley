//
//  ClubRalleyTheme.swift
//  Club Ralley
//
//  Design system based on Figma style guide
//

import SwiftUI

// MARK: - Club Ralley Design System

struct ClubRalleyTheme {
    
    // MARK: - Colors (from Figma Style Guide)
    
    struct Colors {
        // Primary brand colors
        static let darkGreen = Color(hex: "#2C4F40")
        static let sageGreen = Color(hex: "#E2E4D6") 
        static let black = Color(hex: "#000000")
        static let white = Color.white
        
        // UI Colors
        static let background = white
        static let secondaryBackground = sageGreen
        static let sageBackground = sageGreen.opacity(0.3)
        static let statCardBackground = sageGreen
        static let text = black
        static let secondaryText = black.opacity(0.5)
        static let accent = darkGreen

        // Button colors
        static let primaryButton = darkGreen
        static let secondaryButton = sageGreen
        static let textButton = black

        // Surface colors
        static let warmBackground = Color(hex: "#F6F5F1")
        static let coolBackground = Color(hex: "#F5F5F5")
        static let separator = Color(hex: "#ECE9E2")
        static let feedSeparator = Color(hex: "#ECE9E2")

        // Text variants
        static let mutedText = Color(hex: "#7a9088")
        static let subtleText = Color(hex: "#5a7268")

        // Icon / tab colors
        static let inactiveIcon = Color(hex: "#999999")
        static let unselectedTab = Color(hex: "#bbbbbb")
        static let tabDivider = Color(hex: "#d5d7cb")

        // Badges & disabled
        static let badgeRed = Color(hex: "#E74C3C")
        static let disabledButton = Color(hex: "#c4cabe")

        // System colors (for alerts, validation, settings only — not in profile/home UI)
        static let success = Color(hex: "#4CAF50")
        static let warning = Color(hex: "#FF9800")
        static let error = Color(hex: "#F44336")
        static let info = darkGreen
    }
    
    // MARK: - Typography
    
    struct Typography {
        // Font weights
        static let light = Font.Weight.light
        static let regular = Font.Weight.regular
        static let medium = Font.Weight.medium
        static let semibold = Font.Weight.semibold
        static let bold = Font.Weight.bold
        
        // Text styles
        static let largeTitle = Font.largeTitle.weight(.bold)
        static let title1 = Font.title.weight(.bold)
        static let title2 = Font.title2.weight(.bold)
        static let title3 = Font.title3.weight(.semibold)
        static let headline = Font.headline.weight(.semibold)
        static let subheadline = Font.subheadline.weight(.medium)
        static let body = Font.body.weight(.regular)
        static let bodyBold = Font.body.weight(.semibold)
        static let callout = Font.callout.weight(.regular)
        static let footnote = Font.footnote.weight(.regular)
        static let caption = Font.caption.weight(.regular)
        static let caption2 = Font.caption2.weight(.regular)
    }
    
    // MARK: - Spacing
    
    struct Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 16
        static let lg: CGFloat = 24
        static let xl: CGFloat = 32
        static let xxl: CGFloat = 48
    }
    
    // MARK: - Corner Radius
    
    struct CornerRadius {
        static let small: CGFloat = 8
        static let medium: CGFloat = 12
        static let large: CGFloat = 16
        static let xlarge: CGFloat = 20
        static let circular: CGFloat = 50
    }
    
    // MARK: - Shadows
    
    struct Shadows {
        static let light = Shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        static let medium = Shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)
        static let heavy = Shadow(color: .black.opacity(0.2), radius: 12, x: 0, y: 6)
    }
    
    struct Shadow {
        let color: Color
        let radius: CGFloat
        let x: CGFloat
        let y: CGFloat
    }

    // MARK: - Animation Durations

    struct Animation {
        static let quick: Double = 0.15
        static let standard: Double = 0.3
        static let slow: Double = 0.5
    }
}

// MARK: - Color Extension

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - View Extensions

extension View {
    func clubRalleyButtonStyle(_ style: ClubRalleyButtonStyle = .primary) -> some View {
        modifier(ClubRalleyButtonModifier(style: style))
    }

    func clubRalleyShadow(_ shadow: ClubRalleyTheme.Shadow = ClubRalleyTheme.Shadows.light) -> some View {
        self.shadow(color: shadow.color, radius: shadow.radius, x: shadow.x, y: shadow.y)
    }

    func polishedCard() -> some View {
        self
            .background(Color.white)
            .cornerRadius(14)
            .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 4)
    }

    func pressableButton() -> some View {
        self.buttonStyle(PressableButtonStyle())
    }

}

// MARK: - Pressable Button Style

struct PressableButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: ClubRalleyTheme.Animation.quick), value: configuration.isPressed)
    }
}

// MARK: - Club Ralley Spinner

struct ClubRalleySpinner: View {
    @State private var isSpinning = false

    var body: some View {
        Circle()
            .trim(from: 0, to: 0.7)
            .stroke(ClubRalleyTheme.Colors.darkGreen, style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
            .frame(width: 20, height: 20)
            .rotationEffect(.degrees(isSpinning ? 360 : 0))
            .onAppear {
                withAnimation(.linear(duration: 0.8).repeatForever(autoreverses: false)) {
                    isSpinning = true
                }
            }
    }
}

// MARK: - Button Styles

enum ClubRalleyButtonStyle {
    case primary
    case secondary 
    case outline
    case text
}

struct ClubRalleyButtonModifier: ViewModifier {
    let style: ClubRalleyButtonStyle
    
    func body(content: Content) -> some View {
        content
            .font(ClubRalleyTheme.Typography.bodyBold)
            .padding(.horizontal, ClubRalleyTheme.Spacing.lg)
            .padding(.vertical, ClubRalleyTheme.Spacing.md)
            .background(backgroundColor)
            .foregroundColor(textColor)
            .cornerRadius(ClubRalleyTheme.CornerRadius.large)
            .overlay(
                RoundedRectangle(cornerRadius: ClubRalleyTheme.CornerRadius.large)
                    .stroke(strokeColor, lineWidth: strokeWidth)
            )
    }
    
    private var backgroundColor: Color {
        switch style {
        case .primary:
            return ClubRalleyTheme.Colors.primaryButton
        case .secondary:
            return ClubRalleyTheme.Colors.secondaryButton
        case .outline, .text:
            return Color.clear
        }
    }
    
    private var textColor: Color {
        switch style {
        case .primary:
            return ClubRalleyTheme.Colors.white
        case .secondary, .outline, .text:
            return ClubRalleyTheme.Colors.text
        }
    }
    
    private var strokeColor: Color {
        switch style {
        case .primary, .secondary, .text:
            return Color.clear
        case .outline:
            return ClubRalleyTheme.Colors.accent
        }
    }
    
    private var strokeWidth: CGFloat {
        switch style {
        case .outline:
            return 1.5
        case .primary, .secondary, .text:
            return 0
        }
    }
}