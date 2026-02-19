//
//  OnboardingGradientColors.swift
//  Club Ralley
//
//  Color definitions for each onboarding gradient style
//

import SwiftUI

// Note: Color.init(hex:) extension is defined in ClubRalleyTheme.swift

// MARK: - Gradient Style Colors

extension OnboardingGradientStyle {

    var colors: [Color] {
        switch self {

        // MARK: - Cost Screen Progression (Descent into Darkness)

        case .costLevel1:
            return [
                Color(hex: "#0A0510"),
                Color(hex: "#1A0A1F"),
                Color(hex: "#2D1025"),
                Color(hex: "#3D1520")
            ]

        case .costLevel2:
            return [
                Color(hex: "#08040C"),
                Color(hex: "#150812"),
                Color(hex: "#25101A"),
                Color(hex: "#351518")
            ]

        case .costLevel3:
            return [
                Color(hex: "#050308"),
                Color(hex: "#10060D"),
                Color(hex: "#1D0B12"),
                Color(hex: "#2A1015")
            ]

        case .costLevel4:
            return [
                Color(hex: "#030205"),
                Color(hex: "#0A050A"),
                Color(hex: "#15080D"),
                Color(hex: "#200C10")
            ]

        case .costLevel5:
            return [
                Color(hex: "#020203"),
                Color(hex: "#070407"),
                Color(hex: "#0D0609"),
                Color(hex: "#15090C")
            ]

        case .costLevel6:
            return [
                Color(hex: "#010102"),
                Color(hex: "#040304"),
                Color(hex: "#080506"),
                Color(hex: "#0C0708")
            ]

        // MARK: - Hope & Recovery (Ascent to Light)

        case .hopeTransition:
            return [
                Color(hex: "#050508"),
                Color(hex: "#0A1015"),
                Color(hex: "#102820"),
                Color(hex: "#1A4035")
            ]

        case .solutionHopeful:
            return [
                Color(hex: "#081210"),
                Color(hex: "#0F2520"),
                Color(hex: "#184035"),
                Color(hex: "#205545")
            ]

        case .recoveryBright:
            return [
                Color(hex: "#0A1A15"),
                Color(hex: "#153328"),
                Color(hex: "#204D3D"),
                Color(hex: "#2A6652")
            ]

        // MARK: - Purpose-Specific Gradients

        case .mochiBlue:
            return [
                Color(hex: "#050A15"),
                Color(hex: "#0D1A33"),
                Color(hex: "#152D54"),
                Color(hex: "#1F53A9"),
                Color(hex: "#2A6BC4")
            ]

        case .protectionTeal:
            return [
                Color(hex: "#030A0A"),
                Color(hex: "#0A1F20"),
                Color(hex: "#143835"),
                Color(hex: "#1A524D"),
                Color(hex: "#0D2E2B")
            ]

        case .growthGreen:
            return [
                Color(hex: "#051008"),
                Color(hex: "#0D2615"),
                Color(hex: "#1A4025"),
                Color(hex: "#2A6638"),
                Color(hex: "#3D8C4D")
            ]

        case .commitmentGold:
            return [
                Color(hex: "#0A0805"),
                Color(hex: "#1A1508"),
                Color(hex: "#33280D"),
                Color(hex: "#594512"),
                Color(hex: "#806318")
            ]

        case .sunriseBright:
            return [
                Color(hex: "#1A1005"),
                Color(hex: "#33200A"),
                Color(hex: "#664010"),
                Color(hex: "#996618"),
                Color(hex: "#CC9933"),
                Color(hex: "#FFCC66")
            ]

        case .recoveryProgram:
            return [
                Color(hex: "#050A10"),
                Color(hex: "#0D1A2E"),
                Color(hex: "#143352"),
                Color(hex: "#1A4D75"),
                Color(hex: "#0F3350")
            ]

        case .projectedLossRed:
            return [
                Color(hex: "#0A0608"),
                Color(hex: "#150A10"),
                Color(hex: "#1A0D14"),
                Color(hex: "#251218"),
                Color(hex: "#30181E"),
                Color(hex: "#3D2028")
            ]

        case .fightBack:
            return [
                Color(hex: "#0A0812"),
                Color(hex: "#12101F"),
                Color(hex: "#1A152D"),
                Color(hex: "#251A3D"),
                Color(hex: "#33204D"),
                Color(hex: "#2D1A1A")
            ]

        case .resultsVetoBlueToRed:
            return [
                Color(hex: "#050A15"),
                Color(hex: "#0A1525"),
                Color(hex: "#122040"),
                Color(hex: "#1A3366"),
                Color(hex: "#1F53A9"),
                Color(hex: "#2660B8")
            ]

        case .analyzingPulse:
            return [
                Color(hex: "#08080F"),
                Color(hex: "#10101F"),
                Color(hex: "#181828"),
                Color(hex: "#202035"),
                Color(hex: "#181828"),
                Color(hex: "#10101F")
            ]

        case .scienceCredibility:
            return [
                Color(hex: "#E8EEF4"),
                Color(hex: "#C5D4E3"),
                Color(hex: "#8AA4BE"),
                Color(hex: "#4A6A8A"),
                Color(hex: "#2D4A66"),
                Color(hex: "#1A3348")
            ]

        case .blockingShield:
            return [
                Color(hex: "#08080C"),
                Color(hex: "#101018"),
                Color(hex: "#181825"),
                Color(hex: "#3030550"),
                Color(hex: "#6060A0"),
                Color(hex: "#9090D0"),
                Color(hex: "#C0C0F0")
            ]

        case .lockedSecure:
            return [
                Color(hex: "#0A0A0C"),
                Color(hex: "#151518"),
                Color(hex: "#222228"),
                Color(hex: "#353540"),
                Color(hex: "#484858"),
                Color(hex: "#606075")
            ]

        case .buildingPlan:
            return [
                Color(hex: "#0A0810"),
                Color(hex: "#151025"),
                Color(hex: "#251840"),
                Color(hex: "#352555"),
                Color(hex: "#45336A"),
                Color(hex: "#554080")
            ]

        case .personalizationDeep:
            return [
                Color(hex: "#050510"),
                Color(hex: "#0A0A1A"),
                Color(hex: "#101025"),
                Color(hex: "#181835"),
                Color(hex: "#202045"),
                Color(hex: "#151530")
            ]

        // MARK: - Relapse Reflection Flow Gradients

        case .compassionateEmbrace:
            return [
                Color(hex: "#0D0805"),
                Color(hex: "#1A1008"),
                Color(hex: "#26180C"),
                Color(hex: "#332010"),
                Color(hex: "#402814"),
                Color(hex: "#4D3018")
            ]

        case .groundedTruth:
            return [
                Color(hex: "#120A05"),
                Color(hex: "#261508"),
                Color(hex: "#3D220D"),
                Color(hex: "#523012"),
                Color(hex: "#664018"),
                Color(hex: "#7A4D1D")
            ]

        case .innerDepths:
            return [
                Color(hex: "#1A0D05"),
                Color(hex: "#33180A"),
                Color(hex: "#4D2810"),
                Color(hex: "#663815"),
                Color(hex: "#80481A"),
                Color(hex: "#995820")
            ]

        case .firstLight:
            return [
                Color(hex: "#1A1005"),
                Color(hex: "#33200A"),
                Color(hex: "#4D3010"),
                Color(hex: "#664015"),
                Color(hex: "#88551D"),
                Color(hex: "#AA6B28")
            ]

        case .roseGlow:
            return [
                Color(hex: "#150510"),
                Color(hex: "#2A0A1A"),
                Color(hex: "#3D1025"),
                Color(hex: "#521535"),
                Color(hex: "#6A1A45"),
                Color(hex: "#802055")
            ]

        case .mochiWelcome:
            return [
                Color(hex: "#FFFFFF"),
                Color(hex: "#FFF5F8"),
                Color(hex: "#FFE0EC"),
                Color(hex: "#FE9CDD"),
                Color(hex: "#F080C8")
            ]

        // MARK: - Setup Flow Gradients

        case .clarityWindow:
            return [
                Color(hex: "#0A1520"),
                Color(hex: "#102535"),
                Color(hex: "#1A4055"),
                Color(hex: "#255570"),
                Color(hex: "#306A85"),
                Color(hex: "#1A4560")
            ]

        case .enableShield:
            return [
                Color(hex: "#100818"),
                Color(hex: "#1A1030"),
                Color(hex: "#2A1848"),
                Color(hex: "#3D2060"),
                Color(hex: "#502878"),
                Color(hex: "#3A1D55")
            ]

        case .stayConnected:
            return [
                Color(hex: "#150A0A"),
                Color(hex: "#251515"),
                Color(hex: "#3D2020"),
                Color(hex: "#553030"),
                Color(hex: "#6D4040"),
                Color(hex: "#4A2828")
            ]

        case .completeSetup:
            return [
                Color(hex: "#051015"),
                Color(hex: "#0A2025"),
                Color(hex: "#103035"),
                Color(hex: "#184545"),
                Color(hex: "#205550"),
                Color(hex: "#153A3A")
            ]

        // MARK: - Quiz & Reflection

        case .darkRadialTeal:
            return [
                Color(hex: "#030508"),
                Color(hex: "#0A1F1F"),
                Color(hex: "#14332E"),
                Color(hex: "#081414")
            ]

        case .darkRadialPurple:
            return [
                Color(hex: "#05050A"),
                Color(hex: "#140D26"),
                Color(hex: "#1F1438"),
                Color(hex: "#0D081A")
            ]

        case .spotlightGreen:
            return [
                Color(hex: "#020305"),
                Color(hex: "#051410"),
                Color(hex: "#0F2E24"),
                Color(hex: "#05100D")
            ]

        // MARK: - Legacy Styles

        case .tealToOrange:
            return [
                Color(hex: "#0D2626"),
                Color(hex: "#143833"),
                Color(hex: "#331F14"),
                Color(hex: "#73330D"),
                Color(hex: "#99400D")
            ]

        case .greenToTeal:
            return [
                Color(hex: "#051F1A"),
                Color(hex: "#0D332E"),
                Color(hex: "#144740")
            ]

        case .purpleToRed:
            return [
                Color(hex: "#1F0D2E"),
                Color(hex: "#331426"),
                Color(hex: "#591A1A"),
                Color(hex: "#801F14")
            ]

        case .blueToPurple:
            return [
                Color(hex: "#0D1433"),
                Color(hex: "#1A1A40"),
                Color(hex: "#2E1A47")
            ]

        case .successGlow:
            return [
                Color(hex: "#05261F"),
                Color(hex: "#0D4033"),
                Color(hex: "#142E26")
            ]

        case .darkAmbient:
            return [
                Color(hex: "#08080D"),
                Color(hex: "#140F14"),
                Color(hex: "#1F140F")
            ]

        case .deepSpace:
            return [
                Color(hex: "#030308"),
                Color(hex: "#080814"),
                Color(hex: "#05050D")
            ]
        }
    }
}
