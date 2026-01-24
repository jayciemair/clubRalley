//
//  OnboardingTypeManager.swift
//  Dial
//
//  Manages onboarding flow selection and completion status

import Foundation

enum OnboardingType: String, CaseIterable {
    case software = "software"

    var flowFileName: String {
        switch self {
        case .software:
            return "software_onboarding"
        }
    }
    
    var completionKey: String {
        return "hasCompleted\(rawValue.capitalized)Onboarding"
    }
    
    var analyticsPrefix: String {
        return "\(rawValue)_onboarding"
    }
}

final class OnboardingTypeManager {
    static let shared = OnboardingTypeManager()
    
    private let userDefaults = UserDefaults.standard

    private enum Keys {
        static let currentOnboardingType = "currentOnboardingType"
    }
    
    private init() {}

    var currentOnboardingType: OnboardingType {
        get {
            guard let rawValue = userDefaults.string(forKey: Keys.currentOnboardingType),
                  let type = OnboardingType(rawValue: rawValue) else {
                return .software
            }
            return type
        }
        set {
            userDefaults.set(newValue.rawValue, forKey: Keys.currentOnboardingType)
        }
    }
    
    func hasCompletedOnboarding(for type: OnboardingType) -> Bool {
        return userDefaults.bool(forKey: type.completionKey)
    }
    
    func markOnboardingCompleted(for type: OnboardingType) {
        userDefaults.set(true, forKey: type.completionKey)
        userDefaults.set(Date(), forKey: "\(type.completionKey)Date")
    }

    func shouldShowSoftwareOnboarding() -> Bool {
        return !hasCompletedOnboarding(for: .software)
    }
    
    func determineRequiredOnboarding() -> OnboardingType? {
        if shouldShowSoftwareOnboarding() {
            return .software
        }

        return nil
    }

    func resetOnboarding(for type: OnboardingType) {
        #if DEBUG
        userDefaults.removeObject(forKey: type.completionKey)
        userDefaults.removeObject(forKey: "\(type.completionKey)Date")
        #endif
    }
    
    func resetAllOnboarding() {
        #if DEBUG
        OnboardingType.allCases.forEach { resetOnboarding(for: $0) }
        userDefaults.removeObject(forKey: Keys.currentOnboardingType)
        // Reset manifesto viewed flag
        userDefaults.removeObject(forKey: "hasSeenManifesto")
        #endif
    }
}