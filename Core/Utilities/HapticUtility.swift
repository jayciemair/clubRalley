//
//  HapticUtility.swift
//  Checkpoint
//
//  Centralized haptic feedback utilities for consistent feel across app
//

import UIKit
import CoreHaptics

struct HapticUtility {

    /// Play a continuous haptic for a specified duration (used during counter animations)
    static func playContinuousHaptic(duration: Double, intensity: Float = 0.4, sharpness: Float = 0.3) {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else {
            // Fallback to standard haptic
            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
            impactFeedback.impactOccurred()
            return
        }

        do {
            let engine = try CHHapticEngine()
            try engine.start()

            // Create continuous haptic event
            let intensityParam = CHHapticEventParameter(parameterID: .hapticIntensity, value: intensity)
            let sharpnessParam = CHHapticEventParameter(parameterID: .hapticSharpness, value: sharpness)

            let event = CHHapticEvent(
                eventType: .hapticContinuous,
                parameters: [intensityParam, sharpnessParam],
                relativeTime: 0,
                duration: duration
            )

            let pattern = try CHHapticPattern(events: [event], parameters: [])
            let player = try engine.makePlayer(with: pattern)
            try player.start(atTime: 0)

            // Stop engine after duration
            DispatchQueue.main.asyncAfter(deadline: .now() + duration + 0.1) {
                engine.stop()
            }

        } catch {
            // Fallback to standard haptic if Core Haptics fails
            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
            impactFeedback.impactOccurred()
        }
    }

    /// Play a simple impact haptic
    static func impact(style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.impactOccurred()
    }

    /// Play a notification haptic
    static func notification(type: UINotificationFeedbackGenerator.FeedbackType) {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(type)
    }

    /// Play a selection changed haptic
    static func selection() {
        let generator = UISelectionFeedbackGenerator()
        generator.selectionChanged()
    }
}
