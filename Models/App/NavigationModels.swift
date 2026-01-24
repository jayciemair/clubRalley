//
//  NavigationModels.swift
//  Checkpoint
//
//  Navigation-related models and enums
//

import SwiftUI

// MARK: - Tab Enum
enum Tab: String {
    case blocks         // Main blocking tab
    case analytics      // Analytics and progress tracker
    case community      // Community chat (hidden by default - v2 feature)
    case textSimulator  // Text simulator tab
    case settings       // Settings tab
    case v3test         // Legacy name for blocks (keeping for compatibility)
}

// MARK: - Tab Item Model
struct TabItem: Identifiable {
    var id = UUID()
    var tab: Tab
}

// MARK: - Tab Configuration
var tabItems = [
    TabItem(tab: .v3test),        // Main - progress and blocking
    TabItem(tab: .analytics),     // Analytics - statistics
    TabItem(tab: .textSimulator), // Text simulator
    TabItem(tab: .settings)       // Settings
]