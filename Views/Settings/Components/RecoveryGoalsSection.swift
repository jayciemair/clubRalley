//
//  RecoveryGoalsSection.swift
//  Checkpoint
//
//  Displays current recovery goals with edit button
//

import SwiftUI

struct RecoveryGoalsSection: View {
    @Binding var showEditSheet: Bool

    // State to force refresh when goals update
    @State private var refreshID = UUID()

    // Load from UserDefaults cache
    private var goals: [String] {
        _ = refreshID
        return UserDefaults.standard.array(forKey: "recovery_goals") as? [String] ?? []
    }

    private var goalsSummary: String {
        let validGoals = goals.filter { !$0.isEmpty }
        if validGoals.isEmpty {
            return "not set"
        } else if validGoals.count == 1 {
            return validGoals[0].lowercased()
        } else {
            return "\(validGoals.count) goals"
        }
    }

    var body: some View {
        Button(action: {
            let impact = UIImpactFeedbackGenerator(style: .light)
            impact.impactOccurred()
            showEditSheet = true
        }) {
            HStack {
                Image(systemName: "target")
                    .font(.system(size: 22))
                    .foregroundColor(Color(hex: "#E080C0"))
                    .frame(width: 32, height: 32)

                VStack(alignment: .leading, spacing: 4) {
                    Text("my goals")
                        .font(.custom("Satoshi-Regular", size: 17))
                        .foregroundColor(Color(hex: "#4A2040"))

                    Text(goalsSummary)
                        .font(.system(size: 14))
                        .foregroundColor(Color(hex: "#6A3060").opacity(0.7))
                        .lineLimit(1)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Color(hex: "#6A3060").opacity(0.5))
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 20)
            .background(Color.white.opacity(0.6))
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.white.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .padding(.horizontal, 20)
        .onReceive(NotificationCenter.default.publisher(for: .recoveryGoalsDidUpdate)) { _ in
            refreshID = UUID()
        }
    }
}

struct RecoveryGoalsSection_Previews: PreviewProvider {
    static var previews: some View {
        RecoveryGoalsSection(showEditSheet: .constant(false))
            .background(AppTheme.Colors.background)
    }
}
