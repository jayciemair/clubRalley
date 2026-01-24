//
//  SimulatorStatsManager.swift
//  goh
//
//  Manages aggregated stats from post-simulation reflections
//  Fetches from Supabase with local cache fallback
//

import Foundation

@MainActor
class SimulatorStatsManager: ObservableObject {
    static let shared = SimulatorStatsManager()

    // MARK: - Published Stats

    @Published var noLongerWantToTextPercent: Int = 76
    @Published var notWorthItPercent: Int = 91
    @Published var predictedRegretPercent: Int = 88
    @Published var helpedPercent: Int = 94
    @Published var totalSessions: Int = 0

    private let supabase = SupabaseClientManager.shared

    // MARK: - Init

    private init() {
        Task {
            await fetchStats()
        }
    }

    // MARK: - Fetch Stats from Supabase

    func fetchStats() async {
        print("[SimulatorStats] 🔄 Fetching stats from Supabase...")
        do {
            let response: [SimulatorStatsResponse] = try await supabase.database
                .from("simulator_stats")
                .select()
                .execute()
                .value

            print("[SimulatorStats] ✅ Got response: \(response)")

            if let stats = response.first {
                print("[SimulatorStats] 📊 Stats: noLonger=\(stats.no_longer_wanted_percent), notWorth=\(stats.not_worth_it_percent), regret=\(stats.predicted_regret_percent), helped=\(stats.helped_percent), total=\(stats.total_sessions)")
                self.noLongerWantToTextPercent = stats.no_longer_wanted_percent
                self.notWorthItPercent = stats.not_worth_it_percent
                self.predictedRegretPercent = stats.predicted_regret_percent
                self.helpedPercent = stats.helped_percent
                self.totalSessions = stats.total_sessions
            } else {
                print("[SimulatorStats] ⚠️ No stats returned from view")
            }
        } catch {
            print("[SimulatorStats] ❌ Failed to fetch stats: \(error)")
            // Keep default values on error
        }
    }

    // MARK: - Record Reflection to Supabase

    func recordReflection(
        stillWantToText: StillWantToTextAnswer,
        wasItWorthIt: WasItWorthItAnswer,
        whatWouldHappen: WhatWouldHappenAnswer,
        didThisHelp: DidThisHelpAnswer
    ) async {
        print("[SimulatorStats] 📝 Recording reflection...")
        print("[SimulatorStats] Answers: stillWant=\(stillWantToText.dbValue), worthIt=\(wasItWorthIt.dbValue), wouldHappen=\(whatWouldHappen.dbValue), helped=\(didThisHelp.dbValue)")

        do {
            let userId = try await supabase.getCurrentUser()?.id
            print("[SimulatorStats] 👤 User ID: \(String(describing: userId))")

            let reflection = SimulatorReflectionInsert(
                user_id: userId,
                still_want_to_text: stillWantToText.dbValue,
                was_it_worth_it: wasItWorthIt.dbValue,
                what_would_happen: whatWouldHappen.dbValue,
                did_this_help: didThisHelp.dbValue
            )

            try await supabase.database
                .from("simulator_reflections")
                .insert(reflection)
                .execute()

            print("[SimulatorStats] ✅ Reflection saved successfully!")

            // Refresh stats after recording
            await fetchStats()

        } catch {
            print("[SimulatorStats] ❌ Failed to record reflection: \(error)")
        }
    }

    // MARK: - Answer Types

    enum StillWantToTextAnswer: String, CaseIterable {
        case no = "No"
        case lessThanBefore = "Less than before"
        case stillDo = "Still do"

        var dbValue: String {
            switch self {
            case .no: return "no"
            case .lessThanBefore: return "less_than_before"
            case .stillDo: return "still_do"
            }
        }
    }

    enum WasItWorthItAnswer: String, CaseIterable {
        case no = "No"
        case probablyNot = "Probably not"
        case maybe = "Maybe"

        var dbValue: String {
            switch self {
            case .no: return "no"
            case .probablyNot: return "probably_not"
            case .maybe: return "maybe"
            }
        }
    }

    enum WhatWouldHappenAnswer: String, CaseIterable {
        case regret = "Regret"
        case nothingGood = "Nothing good"
        case drama = "Drama"

        var dbValue: String {
            switch self {
            case .regret: return "regret"
            case .nothingGood: return "nothing_good"
            case .drama: return "drama"
            }
        }
    }

    enum DidThisHelpAnswer: String, CaseIterable {
        case yes = "Yes"
        case kinda = "Kinda"
        case notReally = "Not really"

        var dbValue: String {
            switch self {
            case .yes: return "yes"
            case .kinda: return "kinda"
            case .notReally: return "not_really"
            }
        }
    }
}

// MARK: - Supabase Models

private struct SimulatorStatsResponse: Decodable {
    let no_longer_wanted_percent: Int
    let not_worth_it_percent: Int
    let predicted_regret_percent: Int
    let helped_percent: Int
    let total_sessions: Int
}

private struct SimulatorReflectionInsert: Encodable {
    let user_id: UUID?
    let still_want_to_text: String
    let was_it_worth_it: String
    let what_would_happen: String
    let did_this_help: String
}
