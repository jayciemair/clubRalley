//
//  OnboardingGradientStyle.swift
//  Club Ralley
//
//  Gradient style definitions for onboarding screens
//  Defines available styles, their gradient types, and rendering properties
//

import SwiftUI

// MARK: - Gradient Styles

enum OnboardingGradientStyle {
    // MARK: - Quiz & Assessment
    /// Dark center with teal/green radial ring - for quiz questions
    case darkRadialTeal
    /// Dark center with purple/blue radial ring - for reflection questions
    case darkRadialPurple

    // MARK: - Welcome & Landing
    /// Dramatic spotlight from center - for welcome/landing
    case spotlightGreen

    // MARK: - Cost Screens (Progressive Darkening)
    /// Level 1: Introduction to costs - still has some light
    case costLevel1
    /// Level 2: Red undertones bleeding in
    case costLevel2
    /// Level 3: Shame creeping in, darker
    case costLevel3
    /// Level 4: Guilt, getting heavy
    case costLevel4
    /// Level 5: Despair, very dark
    case costLevel5
    /// Level 6: Mortality, darkest point (near void)
    case costLevel6

    // MARK: - Hope & Recovery (Progressive Brightening)
    /// Transition from dark to hope - light returning
    case hopeTransition
    /// Solution screens - hopeful, growth
    case solutionHopeful
    /// Recovery/success - bright, optimistic
    case recoveryBright

    // MARK: - Purpose-Specific Gradients
    case mochiBlue
    case protectionTeal
    case growthGreen
    case commitmentGold
    case sunriseBright
    case recoveryProgram
    case projectedLossRed
    case fightBack
    case resultsVetoBlueToRed
    case analyzingPulse
    case scienceCredibility
    case blockingShield
    case lockedSecure
    case buildingPlan
    case personalizationDeep

    // MARK: - Relapse Reflection Flow Gradients
    case compassionateEmbrace
    case groundedTruth
    case innerDepths
    case firstLight
    case roseGlow
    case mochiWelcome

    // MARK: - Setup Flow Gradients
    case clarityWindow
    case enableShield
    case stayConnected
    case completeSetup

    // MARK: - Legacy styles
    case tealToOrange
    case greenToTeal
    case purpleToRed
    case blueToPurple
    case successGlow
    case darkAmbient
    case deepSpace

    // MARK: - Gradient Type

    /// The type of gradient layout to use
    enum GradientType {
        case radial          // Circular, emanating from center
        case linear          // Top to bottom
        case diagonal        // Corner to corner
        case layeredRadial   // Multiple radial layers
        case sunrise         // Special sunrise effect with multiple layers
        case zigzagBeam      // Lightning bolt zigzag pattern
        case zigzagBeamSoft  // Softer zigzag for backgrounds
        case topLeftLight    // Light emanating from top-left corner
    }

    /// The gradient type for this style
    var gradientType: GradientType {
        switch self {
        // Radial gradients
        case .darkRadialTeal, .darkRadialPurple, .spotlightGreen, .darkAmbient, .deepSpace,
             .costLevel1, .costLevel2, .costLevel3,
             .costLevel4, .costLevel5, .costLevel6,
             .hopeTransition, .solutionHopeful, .recoveryBright, .protectionTeal, .mochiBlue,
             .stayConnected:
            return .radial

        // Linear gradients
        case .tealToOrange, .greenToTeal, .purpleToRed, .blueToPurple, .successGlow,
             .recoveryProgram, .resultsVetoBlueToRed, .analyzingPulse, .scienceCredibility,
             .buildingPlan, .personalizationDeep, .clarityWindow:
            return .linear

        // Diagonal - light shining from corner
        case .growthGreen, .fightBack, .blockingShield, .lockedSecure, .projectedLossRed,
             .enableShield, .completeSetup:
            return .diagonal

        // Sunrise stages - sun orb gaining strength (relapse flow)
        case .compassionateEmbrace, .groundedTruth, .innerDepths, .firstLight:
            return .sunrise

        // Rose glow - soft zigzag beam pink
        case .roseGlow:
            return .zigzagBeamSoft

        // Mochi welcome - light from top-left
        case .mochiWelcome:
            return .topLeftLight

        // Layered radial - commitment feels ceremonial
        case .commitmentGold:
            return .layeredRadial

        // Special sunrise effect
        case .sunriseBright:
            return .sunrise
        }
    }

    /// Whether this style uses radial (circular) gradients as primary
    var isRadial: Bool {
        switch gradientType {
        case .radial, .layeredRadial:
            return true
        default:
            return false
        }
    }

    /// Sunrise intensity for staged sunrise effects (0.0 to 1.0)
    /// Used by relapse flow to show sun gaining strength
    var sunriseIntensity: CGFloat {
        switch self {
        case .compassionateEmbrace: return 0.25  // Stage 1: Dim, small orb
        case .groundedTruth: return 0.45         // Stage 2: Warming up
        case .innerDepths: return 0.65           // Stage 3: Getting bright
        case .firstLight: return 0.85            // Stage 4: Almost there
        case .sunriseBright: return 1.0          // Stage 5: Full sunrise
        case .roseGlow: return 0.65              // Same intensity as innerDepths
        default: return 1.0
        }
    }
}
