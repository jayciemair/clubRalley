//
//  RecoveryModels.swift
//  Checkpoint
//
//  Models for recovery program
//

import Foundation
import SwiftUI

// MARK: - Lesson Content

struct LessonContent {
    let slug: String // Unique identifier (e.g., "calming_techniques", "understanding_dopamine")
    let title: String
    let subtitle: String
    let icon: String // SF Symbol name for the card
    let cards: [ModuleCard]
    let hasInteractiveFeature: Bool // For special views like box breathing, Mochi
}

// MARK: - Week Module

struct WeekModule: Identifiable, Equatable, Hashable {
    let id: UUID
    let weekNumber: Int
    let title: String
    let subtitle: String
    let days: [Exercise]
    let color: Color

    var completedCount: Int {
        days.filter { $0.isCompleted }.count
    }

    var totalCount: Int {
        days.count
    }

    var isCompleted: Bool {
        completedCount == totalCount
    }

    var isLocked: Bool {
        days.allSatisfy { $0.isLocked }
    }

    static func == (lhs: WeekModule, rhs: WeekModule) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

// MARK: - Exercise (Lesson)

struct Exercise: Identifiable, Equatable, Hashable {
    let id: UUID
    let type: ExerciseType
    let slug: String // Unique identifier (e.g., "calming_techniques")
    let title: String
    let subtitle: String
    let icon: String // SF Symbol name
    let duration: Int // minutes
    var isCompleted: Bool
    var isLocked: Bool

    static func == (lhs: Exercise, rhs: Exercise) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

// MARK: - Exercise Type

enum ExerciseType {
    case calmingTechniques
    case replaceRush
    case removeTriggers
    case selfExclusion
    case aiChat
    case mindfulHeadspace
    case understandingDopamine

    var icon: String {
        switch self {
        case .calmingTechniques: return "wind"
        case .replaceRush: return "bolt.fill"
        case .removeTriggers: return "xmark.circle.fill"
        case .selfExclusion: return "hand.raised.fill"
        case .aiChat: return "message.fill"
        case .mindfulHeadspace: return "sparkles"
        case .understandingDopamine: return "brain.head.profile"
        }
    }

    var moduleKey: String {
        switch self {
        case .calmingTechniques: return "calming_techniques"
        case .replaceRush: return "replace_rush"
        case .removeTriggers: return "remove_triggers"
        case .selfExclusion: return "self_exclusion"
        case .aiChat: return "ai_chat"
        case .mindfulHeadspace: return "mindful_headspace"
        case .understandingDopamine: return "understanding_dopamine"
        }
    }
}

// MARK: - Completion State

enum CompletionState {
    case notStarted
    case inProgress(completed: Int, total: Int)
    case completed

    var progress: Double {
        switch self {
        case .notStarted:
            return 0.0
        case .inProgress(let completed, let total):
            return Double(completed) / Double(total)
        case .completed:
            return 1.0
        }
    }

    var completedCount: Int {
        switch self {
        case .notStarted:
            return 0
        case .inProgress(let completed, _):
            return completed
        case .completed:
            return 0 // Not used when completed
        }
    }
}

// MARK: - Recovery Progress (Database Model)

struct RecoveryProgress: Codable {
    let id: UUID?
    let userId: String
    let moduleType: String
    let completedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case moduleType = "module_type"
        case completedAt = "completed_at"
    }

    init(userId: String, moduleType: String) {
        self.id = nil
        self.userId = userId
        self.moduleType = moduleType
        self.completedAt = nil
    }
}
