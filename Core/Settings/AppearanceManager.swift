//
//  AppearanceManager.swift
//  Checkpoint
//
//  Manages app appearance mode (Light/Dark/System)
//

import SwiftUI

/// Enum representing the app's appearance mode
enum AppearanceMode: String, CaseIterable {
    case light = "Light"
    case dark = "Dark"

    /// Convert to SwiftUI ColorScheme
    var colorScheme: ColorScheme? {
        switch self {
        case .light:
            return .light
        case .dark:
            return .dark
        }
    }
}

/// Manager for app appearance settings
class AppearanceManager: ObservableObject {
    static let shared = AppearanceManager()

    @AppStorage("appearance_mode") private var storedMode: String = AppearanceMode.light.rawValue

    /// Current appearance mode
    var appearanceMode: AppearanceMode {
        get {
            AppearanceMode(rawValue: storedMode) ?? .light
        }
        set {
            storedMode = newValue.rawValue
            objectWillChange.send()
        }
    }

    /// Get the color scheme to apply
    var colorScheme: ColorScheme? {
        appearanceMode.colorScheme
    }

    /// Toggle between light and dark mode
    func toggle() {
        appearanceMode = appearanceMode == .light ? .dark : .light
    }
}
