//
//  OnboardingResult.swift
//  Checkpoint
//
//  Result type for onboarding flow completion
//

import Foundation

/// Result of the onboarding flow - follows industry best practice for completion semantics
enum OnboardingResult {
    /// User successfully completed the entire onboarding flow
    case completed(collectedData: [String: Any])

    /// User cancelled/exited the onboarding flow
    case cancelled

    /// Onboarding failed due to an error
    case failed(error: OnboardingError)
}
