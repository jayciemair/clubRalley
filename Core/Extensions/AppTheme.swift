//
//  AppTheme.swift
//  Dial
//
//  Central theme configuration for design tokens and reusable styles
//

import SwiftUI

// MARK: - App Theme
/// Central configuration for all design tokens used throughout the app
struct AppTheme {
    
    // MARK: - Colors
    struct Colors {
        /// Primary brand color - Dark Gray in light mode, Light Gray in dark mode (buttons, CTAs)
        static let primary = Color("PrimaryColor")

        /// Secondary brand color - Purple (same in both modes)
        static let secondary = Color("SecondaryColor")

        /// Success/Selection color - Emerald Green (positive states, non-threatening selections)
        static let success = Color("SuccessColor")

        /// Warning/Awareness color - Red (confrontational, reality check, gambling behavior)
        static let warning = Color("WarningColor")

        /// Surface color for cards and containers - White in light mode, Dark Gray in dark mode
        static let darkSurface = Color("SurfaceColor")

        /// Main background color - Light Gray in light mode, Very Dark Gray in dark mode
        static let background = Color("BackgroundColor")

        /// Primary text color - Black in light mode, White in dark mode
        static let textPrimary = Color("TextPrimaryColor")

        /// Secondary text color with reduced opacity - Adapts to both modes
        static let textSecondary = Color("TextSecondaryColor")

        /// Border color - Adapts to both modes
        static let border = Color("BorderColor")
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
    
    // MARK: - Border Radius
    struct Radius {
        /// Default radius for buttons and inputs
        static let small: CGFloat = 8
        
        /// Radius for cards and larger containers
        static let medium: CGFloat = 16
        
        /// Radius for modals and sheets
        static let large: CGFloat = 24
    }
    
    // MARK: - Lesson Colors
    /// Color palette for recovery program lessons
    struct LessonColors {
        /// A lesson color with primary (card) and light (content) variants
        struct LessonColor {
            let primary: Color    // For lesson cards in overview
            let light: Color      // For content cards within lesson
        }

        /// The color palette - cycles through for each lesson
        static let palette: [LessonColor] = [
            // Gold
            LessonColor(
                primary: Color(red: 0.85, green: 0.68, blue: 0.32),
                light: Color(red: 0.92, green: 0.82, blue: 0.55)
            ),
            // Pink
            LessonColor(
                primary: Color(red: 0.90, green: 0.30, blue: 0.58),
                light: Color(red: 0.95, green: 0.55, blue: 0.72)
            ),
            // Orange
            LessonColor(
                primary: Color(red: 0.96, green: 0.56, blue: 0.26),
                light: Color(red: 0.98, green: 0.72, blue: 0.48)
            ),
            // Purple
            LessonColor(
                primary: Color(red: 0.67, green: 0.28, blue: 0.74),
                light: Color(red: 0.78, green: 0.50, blue: 0.83)
            ),
            // Blue
            LessonColor(
                primary: Color(red: 0.26, green: 0.65, blue: 0.96),
                light: Color(red: 0.50, green: 0.76, blue: 0.98)
            ),
            // Teal
            LessonColor(
                primary: Color(red: 0.15, green: 0.65, blue: 0.60),
                light: Color(red: 0.40, green: 0.78, blue: 0.73)
            ),
            // Red
            LessonColor(
                primary: Color(red: 0.93, green: 0.35, blue: 0.35),
                light: Color(red: 0.96, green: 0.55, blue: 0.55)
            )
        ]

        /// Get color for a lesson by index (cycles through palette)
        static func color(for index: Int) -> LessonColor {
            palette[index % palette.count]
        }
    }

    // MARK: - Shadows
    struct Shadows {
        /// Primary shadow for elevated elements
        static let primaryColor = Colors.primary.opacity(0.3)
        static let primaryRadius: CGFloat = 12
        static let primaryX: CGFloat = 0
        static let primaryY: CGFloat = 6
        
        /// Subtle shadow for cards
        static let subtleColor = Color.black.opacity(0.2)
        static let subtleRadius: CGFloat = 8
        static let subtleX: CGFloat = 0
        static let subtleY: CGFloat = 4
    }
}

// MARK: - Button Styles
/// Primary button style with teal background
struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .customFont(.headline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(AppTheme.Colors.primary)
            .cornerRadius(AppTheme.Radius.medium)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: configuration.isPressed)
    }
}

/// Secondary button style with transparent background and border
struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .customFont(.body)
            .foregroundColor(AppTheme.Colors.primary)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.Radius.small)
                    .stroke(AppTheme.Colors.primary, lineWidth: 2)
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: configuration.isPressed)
    }
}

/// Text-only button style
struct TextButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .customFont(.callout)
            .foregroundColor(AppTheme.Colors.primary)
            .opacity(configuration.isPressed ? 0.7 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: configuration.isPressed)
    }
}

// MARK: - View Modifiers
/// Card style modifier
struct CardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(AppTheme.Colors.darkSurface)
            .cornerRadius(AppTheme.Radius.medium)
    }
}

/// Info card style modifier with border
struct InfoCardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(AppTheme.Colors.primary.opacity(0.1))
            .cornerRadius(AppTheme.Radius.small)
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.Radius.small)
                    .stroke(AppTheme.Colors.primary.opacity(0.3), lineWidth: 1)
            )
    }
}

// MARK: - View Extensions
extension View {
    /// Apply primary button styling
    func primaryButtonStyle() -> some View {
        self.buttonStyle(PrimaryButtonStyle())
    }
    
    /// Apply secondary button styling
    func secondaryButtonStyle() -> some View {
        self.buttonStyle(SecondaryButtonStyle())
    }
    
    /// Apply text button styling
    func textButtonStyle() -> some View {
        self.buttonStyle(TextButtonStyle())
    }
    
    /// Apply card styling
    func cardStyle() -> some View {
        self.modifier(CardStyle())
    }
    
    /// Apply info card styling
    func infoCardStyle() -> some View {
        self.modifier(InfoCardStyle())
    }
}

// MARK: - Typography Extensions
extension Text {
    /// Large heading style
    func headingLarge() -> some View {
        self
            .customFont(.title)
            .foregroundColor(AppTheme.Colors.textPrimary)
    }
    
    /// Medium heading style
    func headingMedium() -> some View {
        self
            .customFont(.title2)
            .foregroundColor(AppTheme.Colors.textPrimary)
    }
    
    /// Body text style
    func bodyStyle() -> some View {
        self
            .customFont(.body)
            .foregroundColor(AppTheme.Colors.textPrimary)
    }
    
    /// Secondary text style
    func secondaryStyle() -> some View {
        self
            .customFont(.body)
            .foregroundColor(AppTheme.Colors.textSecondary)
    }
}