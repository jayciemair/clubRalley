//
//  OnboardingGradientBackground.swift
//  Checkpoint
//
//  Gradient backgrounds for onboarding screens - creates visual interest
//  Uses color to evoke emotion throughout the onboarding journey
//

import SwiftUI

// MARK: - Hex Color Extension

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
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

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

    /// Mochi's signature blue (#1F53A9) - for MeetVeto and VetoCheckIns screens
    /// Deep trustworthy blue that matches Mochi's character
    case mochiBlue

    /// Protection/security teal - for blocking and anti-deletion screens
    /// Conveys safety, security, and protection
    case protectionTeal

    /// Growth green - for tracking progress screens
    /// Fresh, alive, growing - shows progress
    case growthGreen

    /// Commitment gold/amber - for signature and commitment screens
    /// Warm, meaningful, like signing something important
    case commitmentGold

    /// Sunrise bright - warmest, for final "Invest in Yourself" screen
    /// Yellows, whites, warm glow - new beginning, hope, sunrise feeling
    case sunriseBright

    /// Recovery program - educational, calm blue-green
    case recoveryProgram

    /// Projected loss - dramatic red, alarming
    /// For yearly/lifetime loss screens - makes the numbers feel impactful
    case projectedLossRed

    /// Fight back - dramatic diagonal gradient for "gambling companies taking advantage" screen
    /// Dark purple/indigo with hints of ember - represents fighting back against manipulation
    case fightBack

    /// Results teaser - linear Mochi blue at top to red at bottom
    /// For "Your Results Are In" screen - Mochi is there with concerning news
    case resultsVetoBlueToRed

    /// Analyzing/processing - subtle animated pulse, neutral tech feel
    /// For loading/analyzing screens
    case analyzingPulse

    /// Science credibility - light/white top for logos, transitioning to trustworthy slate blue
    /// For "Science-backed recovery methods" screen with institution logos
    case scienceCredibility

    /// Blocking shield - orange/amber "stop" feeling for blocking coverage screen
    /// Conveys active protection, blocking, firewall
    case blockingShield

    /// Locked secure - steel/silver secure feeling for anti-deletion screen
    /// Conveys permanence, security, can't be bypassed
    case lockedSecure

    /// Building plan - constructive, progress-oriented gradient
    /// For "Creating Your Plan" screen - building something positive
    case buildingPlan

    /// Personalization - deep introspective blue/purple for self-reflection questions
    /// Used for challenges, triggers, goals screens - still in the dark but gathering insight
    case personalizationDeep

    // MARK: - Relapse Reflection Flow Gradients

    /// Compassionate embrace - warm, safe, non-judgmental
    /// Deep plum/burgundy with soft rose glow - like being wrapped in a blanket
    /// For "Recovery isn't linear" opening screen
    case compassionateEmbrace

    /// Grounded truth - stable, honest, real
    /// Deep earth tones with subtle warmth - feet on the ground
    /// For "How much did you lose?" screen
    case groundedTruth

    /// Inner depths - contemplative, introspective
    /// Deep ocean blue/indigo - diving into yourself to understand
    /// For "What triggered you?" screen
    case innerDepths

    /// First light - hope emerging, dawn breaking
    /// Purple/indigo transitioning to warm amber - the tunnel is ending
    /// For "How were you feeling?" screen (before the sunrise finale)
    case firstLight

    /// Rose glow - pink/rose version of sunrise for feminine screens
    /// For welcome/splash screens in Get Over Him
    case roseGlow

    /// Mochi welcome - soft light from top-left, warm pink below
    /// Healing, welcoming, feminine - for Mochi intro screen
    case mochiWelcome

    // MARK: - Setup Flow Gradients

    /// Clarity window - calm blue, mental clarity, focused thinking
    /// For ClarityTimeExplanationScreen - about making decisions with a clear mind
    case clarityWindow

    /// Enable shield - empowering purple/magenta, taking action
    /// For ScreenTimePermissionScreen - enabling protection
    case enableShield

    /// Stay connected - warm coral/pink, engagement, community
    /// For PushNotificationPermissionScreen - staying on track
    case stayConnected

    /// Complete setup - accomplished teal to green, finishing strong
    /// For DNSSetupPermissionScreen - final step, completion
    case completeSetup

    // MARK: - Legacy styles
    case tealToOrange
    case greenToTeal
    case purpleToRed
    case blueToPurple
    case successGlow
    case darkAmbient
    case deepSpace

    var colors: [Color] {
        switch self {

        // MARK: - Cost Screen Progression (Descent into Darkness)

        case .costLevel1:
            // Starting point - dark but still has visible color
            return [
                Color(hex: "#0A0510"),  // Dark purple-black
                Color(hex: "#1A0A1F"),  // Deep purple
                Color(hex: "#2D1025"),  // Plum
                Color(hex: "#3D1520")   // Dark wine
            ]

        case .costLevel2:
            // Red undertones bleeding in
            return [
                Color(hex: "#08040C"),  // Darker base
                Color(hex: "#150812"),  // Deep maroon-purple
                Color(hex: "#25101A"),  // Crimson undertone
                Color(hex: "#351518")   // Blood red hint
            ]

        case .costLevel3:
            // Shame - crimson creeping, center darkening
            return [
                Color(hex: "#050308"),  // Near black
                Color(hex: "#10060D"),  // Very dark purple
                Color(hex: "#1D0B12"),  // Deep crimson
                Color(hex: "#2A1015")   // Dark blood
            ]

        case .costLevel4:
            // Guilt - oppressive, suffocating
            return [
                Color(hex: "#030205"),  // Almost black
                Color(hex: "#0A050A"),  // Barely visible purple
                Color(hex: "#15080D"),  // Faint crimson
                Color(hex: "#200C10")   // Muted blood red
            ]

        case .costLevel5:
            // Despair - very dark, hope fading
            return [
                Color(hex: "#020203"),  // Deep black
                Color(hex: "#070407"),  // Whisper of color
                Color(hex: "#0D0609"),  // Trace of red
                Color(hex: "#15090C")   // Dying ember
            ]

        case .costLevel6:
            // Mortality - the darkest point, almost void
            return [
                Color(hex: "#010102"),  // Void black
                Color(hex: "#040304"),  // Barely there
                Color(hex: "#080506"),  // Ghost of red
                Color(hex: "#0C0708")   // Faintest warmth
            ]

        // MARK: - Hope & Recovery (Ascent to Light)

        case .hopeTransition:
            // Light breaking through darkness
            return [
                Color(hex: "#050508"),  // Dark base (still from the depths)
                Color(hex: "#0A1015"),  // Teal emerging
                Color(hex: "#102820"),  // Green breaking through
                Color(hex: "#1A4035")   // Hope color appearing
            ]

        case .solutionHopeful:
            // Hopeful - greens and teals, warmth returning
            return [
                Color(hex: "#081210"),  // Dark green base
                Color(hex: "#0F2520"),  // Forest emerging
                Color(hex: "#184035"),  // Teal-green
                Color(hex: "#205545")   // Alive, growing
            ]

        case .recoveryBright:
            // Recovery - brightest, optimistic
            return [
                Color(hex: "#0A1A15"),  // Rich dark green
                Color(hex: "#153328"),  // Healthy green
                Color(hex: "#204D3D"),  // Vibrant teal
                Color(hex: "#2A6652")   // Success, achievement
            ]

        // MARK: - Purpose-Specific Gradients

        case .mochiBlue:
            // Mochi's signature blue - trustworthy, calm, supportive
            // Base color: #1F53A9
            return [
                Color(hex: "#050A15"),  // Deep navy base
                Color(hex: "#0D1A33"),  // Dark blue
                Color(hex: "#152D54"),  // Mochi blue emerging
                Color(hex: "#1F53A9"),  // Mochi's signature blue
                Color(hex: "#2A6BC4")   // Lighter accent
            ]

        case .protectionTeal:
            // Security, safety - shield-like feeling
            return [
                Color(hex: "#030A0A"),  // Dark base
                Color(hex: "#0A1F20"),  // Deep teal
                Color(hex: "#143835"),  // Protective teal
                Color(hex: "#1A524D"),  // Shield green
                Color(hex: "#0D2E2B")   // Fade back
            ]

        case .growthGreen:
            // Fresh, alive, progress - vertical growth feeling
            return [
                Color(hex: "#051008"),  // Dark earth
                Color(hex: "#0D2615"),  // Deep forest
                Color(hex: "#1A4025"),  // Growing green
                Color(hex: "#2A6638"),  // Vibrant life
                Color(hex: "#3D8C4D")   // Fresh growth
            ]

        case .commitmentGold:
            // Warm, meaningful, ceremonial
            return [
                Color(hex: "#0A0805"),  // Dark warm base
                Color(hex: "#1A1508"),  // Deep amber
                Color(hex: "#33280D"),  // Rich gold
                Color(hex: "#594512"),  // Warm amber
                Color(hex: "#806318")   // Golden highlight
            ]

        case .sunriseBright:
            // New beginning - warmest, most hopeful
            // Yellows, oranges, whites - like a sunrise
            return [
                Color(hex: "#1A1005"),  // Warm dark base
                Color(hex: "#33200A"),  // Pre-dawn amber
                Color(hex: "#664010"),  // Sunrise orange
                Color(hex: "#996618"),  // Golden sun
                Color(hex: "#CC9933"),  // Bright gold
                Color(hex: "#FFCC66")   // Sunrise yellow
            ]

        case .recoveryProgram:
            // Educational, calm, trustworthy
            return [
                Color(hex: "#050A10"),  // Dark base
                Color(hex: "#0D1A2E"),  // Deep blue
                Color(hex: "#143352"),  // Calm blue
                Color(hex: "#1A4D75"),  // Educational blue
                Color(hex: "#0F3350")   // Fade
            ]

        case .projectedLossRed:
            // Dark gradient with subtle red undertones - serious and impactful
            // Diagonal with warm/red hint shining through
            return [
                Color(hex: "#0A0608"),  // Near black with red hint
                Color(hex: "#150A10"),  // Dark with crimson undertone
                Color(hex: "#1A0D14"),  // Deep burgundy-black
                Color(hex: "#251218"),  // Subtle red emerging
                Color(hex: "#30181E"),  // Warm dark
                Color(hex: "#3D2028")   // Muted crimson highlight
            ]

        case .fightBack:
            // Dramatic diagonal - dark indigo to deep purple with ember accents
            // Represents fighting back, breaking free from manipulation
            return [
                Color(hex: "#0A0812"),  // Deep space purple
                Color(hex: "#12101F"),  // Dark indigo
                Color(hex: "#1A152D"),  // Rich purple
                Color(hex: "#251A3D"),  // Vivid purple
                Color(hex: "#33204D"),  // Brighter purple
                Color(hex: "#2D1A1A")   // Hint of ember (fighting spirit)
            ]

        case .resultsVetoBlueToRed:
            // Mochi blue gradient - he's delivering serious news
            // Clean blue tones matching Veto's character (#1F53A9)
            return [
                Color(hex: "#050A15"),  // Deep navy base
                Color(hex: "#0A1525"),  // Dark blue
                Color(hex: "#122040"),  // Mid navy
                Color(hex: "#1A3366"),  // Rich blue
                Color(hex: "#1F53A9"),  // Mochi's signature blue
                Color(hex: "#2660B8")   // Lighter blue accent
            ]

        case .analyzingPulse:
            // Subtle neutral processing gradient - purple/blue tech feel
            return [
                Color(hex: "#08080F"),  // Dark base
                Color(hex: "#10101F"),  // Subtle blue
                Color(hex: "#181828"),  // Mid purple-blue
                Color(hex: "#202035"),  // Lighter purple
                Color(hex: "#181828"),  // Fade back
                Color(hex: "#10101F")   // Symmetrical
            ]

        case .scienceCredibility:
            // Light top for logos visibility, transitioning to professional slate blue
            // Clean, credible, institutional feel
            return [
                Color(hex: "#E8EEF4"),  // Light gray-blue (almost white)
                Color(hex: "#C5D4E3"),  // Soft slate
                Color(hex: "#8AA4BE"),  // Mid slate blue
                Color(hex: "#4A6A8A"),  // Professional blue
                Color(hex: "#2D4A66"),  // Deep slate
                Color(hex: "#1A3348")   // Dark professional base
            ]

        case .blockingShield:
            // Dark slate with bright electric accent - force field effect
            // Dramatic white/blue beam shining through
            return [
                Color(hex: "#08080C"),  // Dark slate base
                Color(hex: "#101018"),  // Deep charcoal
                Color(hex: "#181825"),  // Slate
                Color(hex: "#3030550"),  // Blue emerging
                Color(hex: "#6060A0"),  // Electric blue
                Color(hex: "#9090D0"),  // Bright electric
                Color(hex: "#C0C0F0")   // Near-white electric beam
            ]

        case .lockedSecure:
            // Steel/vault gradient - serious, impenetrable
            // Like a bank vault or high-security lock
            return [
                Color(hex: "#0A0A0C"),  // Near black base
                Color(hex: "#151518"),  // Dark steel
                Color(hex: "#222228"),  // Steel gray
                Color(hex: "#353540"),  // Mid steel
                Color(hex: "#484858"),  // Lighter steel
                Color(hex: "#606075")   // Steel highlight
            ]

        case .buildingPlan:
            // Constructive purple/indigo - building something meaningful
            return [
                Color(hex: "#0A0810"),  // Dark base
                Color(hex: "#151025"),  // Deep indigo
                Color(hex: "#251840"),  // Rich purple
                Color(hex: "#352555"),  // Mid purple
                Color(hex: "#45336A"),  // Lighter purple
                Color(hex: "#554080")   // Bright accent
            ]

        case .personalizationDeep:
            // Deep introspective blue/indigo - self-reflection in darkness
            // Still dark (post-costs) but with thoughtful blue undertones
            return [
                Color(hex: "#050510"),  // Deep void base
                Color(hex: "#0A0A1A"),  // Dark indigo
                Color(hex: "#101025"),  // Deep blue-purple
                Color(hex: "#181835"),  // Introspective blue
                Color(hex: "#202045"),  // Thoughtful purple
                Color(hex: "#151530")   // Fade back to dark
            ]

        // MARK: - Relapse Reflection Flow Gradients

        case .compassionateEmbrace:
            // Sunrise Stage 1: Night before dawn - very dim, warmth barely visible
            // The sun is there but hidden, just hints of what's coming
            return [
                Color(hex: "#0D0805"),  // Deep night base
                Color(hex: "#1A1008"),  // Barely warm
                Color(hex: "#26180C"),  // First hint of amber
                Color(hex: "#332010"),  // Dim glow
                Color(hex: "#402814"),  // Muted warmth
                Color(hex: "#4D3018")   // Faint pre-dawn
            ]

        case .groundedTruth:
            // Sunrise Stage 2: First light - the horizon is warming
            // Sun starting to make its presence known
            return [
                Color(hex: "#120A05"),  // Dark warm base
                Color(hex: "#261508"),  // Deep amber
                Color(hex: "#3D220D"),  // Warming up
                Color(hex: "#523012"),  // Orange emerging
                Color(hex: "#664018"),  // Soft sunrise orange
                Color(hex: "#7A4D1D")   // Early glow
            ]

        case .innerDepths:
            // Sunrise Stage 3: Pre-dawn - real color now, sun rising
            // Getting brighter, hope is visible
            return [
                Color(hex: "#1A0D05"),  // Warm base
                Color(hex: "#33180A"),  // Rich amber
                Color(hex: "#4D2810"),  // Sunrise orange
                Color(hex: "#663815"),  // Golden orange
                Color(hex: "#80481A"),  // Bright amber
                Color(hex: "#995820")   // Strong glow
            ]

        case .firstLight:
            // Sunrise Stage 4: Dawn breaking - bright and warm
            // Almost there, the sun is cresting
            return [
                Color(hex: "#1A1005"),  // Warm base (matching sunriseBright)
                Color(hex: "#33200A"),  // Pre-dawn amber
                Color(hex: "#4D3010"),  // Rich orange
                Color(hex: "#664015"),  // Golden
                Color(hex: "#88551D"),  // Bright gold
                Color(hex: "#AA6B28")   // Dawn gold
            ]

        case .roseGlow:
            // Pink/rose version of innerDepths - feminine sunrise
            return [
                Color(hex: "#150510"),  // Deep pink-purple base
                Color(hex: "#2A0A1A"),  // Rich rose
                Color(hex: "#3D1025"),  // Pink emerging
                Color(hex: "#521535"),  // Rose pink
                Color(hex: "#6A1A45"),  // Bright rose
                Color(hex: "#802055")   // Strong pink glow
            ]

        case .mochiWelcome:
            // Soft light from top-left, warm pink below
            return [
                Color(hex: "#FFFFFF"),  // Pure white light
                Color(hex: "#FFF5F8"),  // Very soft pink
                Color(hex: "#FFE0EC"),  // Light pink
                Color(hex: "#FE9CDD"),  // Mochi pink (main color)
                Color(hex: "#F080C8")   // Deeper pink at bottom
            ]

        // MARK: - Setup Flow Gradients

        case .clarityWindow:
            // Calm sky blue - mental clarity, focused thinking
            // Linear top to bottom - like a clear sky
            return [
                Color(hex: "#0A1520"),  // Deep night base
                Color(hex: "#102535"),  // Pre-dawn blue
                Color(hex: "#1A4055"),  // Morning sky blue
                Color(hex: "#255570"),  // Clear sky
                Color(hex: "#306A85"),  // Bright clarity
                Color(hex: "#1A4560")   // Fade back
            ]

        case .enableShield:
            // Empowering purple/magenta - taking action, strength
            // Diagonal from bottom-left - rising up
            return [
                Color(hex: "#100818"),  // Deep purple base
                Color(hex: "#1A1030"),  // Rich purple
                Color(hex: "#2A1848"),  // Magenta emerging
                Color(hex: "#3D2060"),  // Empowering purple
                Color(hex: "#502878"),  // Vibrant magenta
                Color(hex: "#3A1D55")   // Accent
            ]

        case .stayConnected:
            // Warm coral/salmon - engagement, human connection
            // Radial from center - warmth emanating
            return [
                Color(hex: "#150A0A"),  // Dark warm base
                Color(hex: "#251515"),  // Deep coral
                Color(hex: "#3D2020"),  // Warm red
                Color(hex: "#553030"),  // Salmon emerging
                Color(hex: "#6D4040"),  // Soft coral
                Color(hex: "#4A2828")   // Warm accent
            ]

        case .completeSetup:
            // Accomplished cyan to green - finishing strong, success ahead
            // Diagonal from top-right - achievement shining down
            return [
                Color(hex: "#051015"),  // Deep base
                Color(hex: "#0A2025"),  // Dark cyan
                Color(hex: "#103035"),  // Teal emerging
                Color(hex: "#184545"),  // Cyan-green
                Color(hex: "#205550"),  // Success green hint
                Color(hex: "#153A3A")   // Accomplished teal
            ]

        // MARK: - Quiz & Reflection

        case .darkRadialTeal:
            return [
                Color(hex: "#030508"),  // Near black center
                Color(hex: "#0A1F1F"),  // Dark teal
                Color(hex: "#14332E"),  // Teal ring
                Color(hex: "#081414")   // Fade to dark
            ]

        case .darkRadialPurple:
            return [
                Color(hex: "#05050A"),  // Near black center
                Color(hex: "#140D26"),  // Dark purple
                Color(hex: "#1F1438"),  // Purple ring
                Color(hex: "#0D081A")   // Fade to dark
            ]

        case .spotlightGreen:
            return [
                Color(hex: "#020305"),  // Deep black
                Color(hex: "#051410"),  // Hint of green
                Color(hex: "#0F2E24"),  // Green spotlight
                Color(hex: "#05100D")   // Fade
            ]

        // MARK: - Legacy Styles

        case .tealToOrange:
            return [
                Color(hex: "#0D2626"),  // Dark teal
                Color(hex: "#143833"),  // Mid teal
                Color(hex: "#331F14"),  // Transition
                Color(hex: "#73330D"),  // Deep orange
                Color(hex: "#99400D")   // Warm orange
            ]

        case .greenToTeal:
            return [
                Color(hex: "#051F1A"),  // Dark green
                Color(hex: "#0D332E"),  // Forest green
                Color(hex: "#144740")   // Teal
            ]

        case .purpleToRed:
            return [
                Color(hex: "#1F0D2E"),  // Dark purple
                Color(hex: "#331426"),  // Mid purple
                Color(hex: "#591A1A"),  // Transition
                Color(hex: "#801F14")   // Deep red
            ]

        case .blueToPurple:
            return [
                Color(hex: "#0D1433"),  // Dark blue
                Color(hex: "#1A1A40"),  // Mid blue
                Color(hex: "#2E1A47")   // Purple
            ]

        case .successGlow:
            return [
                Color(hex: "#05261F"),  // Dark green
                Color(hex: "#0D4033"),  // Success green dark
                Color(hex: "#142E26")   // Subtle fade
            ]

        case .darkAmbient:
            return [
                Color(hex: "#08080D"),  // Dark center
                Color(hex: "#140F14"),  // Subtle warmth
                Color(hex: "#1F140F")   // Warm edge
            ]

        case .deepSpace:
            return [
                Color(hex: "#030308"),  // Deep black
                Color(hex: "#080814"),  // Hint of blue
                Color(hex: "#05050D")   // Dark blue
            ]
        }
    }

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

// MARK: - Gradient Background View

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
                Color(hex: "#0A0508"),  // Dark top with pink hint
                Color(hex: "#1A0510").opacity(0.8 + (intensity * 0.2)),
                Color(hex: "#330A1A").opacity(0.5 + (intensity * 0.5)),
                Color(hex: "#4D1028").opacity(intensity)
            ] : [
                Color(hex: "#0A0505"),  // Dark top (always dark)
                Color(hex: "#1A0A05").opacity(0.8 + (intensity * 0.2)),  // Transition
                Color(hex: "#331505").opacity(0.5 + (intensity * 0.5)),  // Pre-dawn
                Color(hex: "#4D2008").opacity(intensity)  // Warm base - scales with intensity
            ],
            startPoint: .top,
            endPoint: .bottom
        )

        // Sun glow - radial from bottom center (breathing effect when animated)
        RadialGradient(
            colors: isRose ? [
                Color(hex: "#FF88BB").opacity((animated ? brightnessPhase + 0.1 : 0.9) * orbBrightness),  // Bright pink center
                Color(hex: "#FF44AA").opacity((animated ? brightnessPhase : 0.7) * orbBrightness),  // Pink glow
                Color(hex: "#DD2288").opacity((animated ? brightnessPhase - 0.2 : 0.5) * orbBrightness),  // Deeper pink
                Color(hex: "#AA1166").opacity((animated ? brightnessPhase - 0.4 : 0.3) * orbBrightness),  // Rose
                .clear
            ] : [
                Color(hex: "#FFDD88").opacity((animated ? brightnessPhase + 0.1 : 0.9) * orbBrightness),  // Bright sun center
                Color(hex: "#FFAA44").opacity((animated ? brightnessPhase : 0.7) * orbBrightness),  // Orange glow
                Color(hex: "#FF6622").opacity((animated ? brightnessPhase - 0.2 : 0.5) * orbBrightness),  // Deeper orange
                Color(hex: "#CC3311").opacity((animated ? brightnessPhase - 0.4 : 0.3) * orbBrightness),  // Red horizon
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
                Color(hex: "#FFD0EB"),  // Lighter pink top
                Color(hex: "#FE9CDD"),  // Main app color
                Color(hex: "#F080C8")   // Deeper pink bottom
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
                Color(hex: "#FFF8FA"),  // Almost white with pink hint
                Color(hex: "#FFE8F0"),  // Very light pink
                Color(hex: "#FE9CDD"),  // Mochi pink
                Color(hex: "#F080C8")   // Deeper pink at bottom
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

struct OnboardingGradientBackground_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            // Radial Teal (for quiz)
            OnboardingGradientBackground(style: .darkRadialTeal)
                .overlay(
                    VStack {
                        Text("Quiz Question")
                            .font(.custom("Satoshi-Bold", size: 32))
                            .foregroundColor(.white)
                        Text("Have you ever...?")
                            .font(.custom("Satoshi-Regular", size: 18))
                            .foregroundColor(.white.opacity(0.7))
                    }
                )
                .previewDisplayName("Dark Radial Teal")

            // Spotlight Green (for welcome)
            OnboardingGradientBackground(style: .spotlightGreen, animated: true)
                .overlay(
                    VStack {
                        Text("Welcome to\nCheckpoint")
                            .font(.custom("Satoshi-Bold", size: 36))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                    }
                )
                .previewDisplayName("Spotlight Green (Animated)")

            // Dark Radial Purple (for reflection)
            OnboardingGradientBackground(style: .darkRadialPurple)
                .previewDisplayName("Dark Radial Purple")

            // Teal to Orange (original)
            OnboardingGradientBackground(style: .tealToOrange)
                .previewDisplayName("Teal to Orange")

            // Purple to Red (for costs)
            OnboardingGradientBackground(style: .purpleToRed)
                .previewDisplayName("Purple to Red")
        }
    }
}
