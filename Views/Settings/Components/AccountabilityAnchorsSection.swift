//
//  AccountabilityAnchorsSection.swift
//  Checkpoint
//
//  Displays current accountability anchors with edit button
//

import SwiftUI

struct AccountabilityAnchorsSection: View {
    @Binding var showEditSheet: Bool

    // State to force refresh when anchors update
    @State private var refreshID = UUID()

    // Load from UserDefaults cache
    private var anchors: [String] {
        _ = refreshID
        return UserDefaults.standard.array(forKey: "accountability_anchors") as? [String] ?? []
    }

    private var anchorsSummary: String {
        let validAnchors = anchors.filter { !$0.isEmpty }
        if validAnchors.isEmpty {
            return "not set"
        } else if validAnchors.count == 1 {
            return validAnchors[0].lowercased()
        } else {
            return "\(validAnchors.count) people/things"
        }
    }

    var body: some View {
        Button(action: {
            let impact = UIImpactFeedbackGenerator(style: .light)
            impact.impactOccurred()
            showEditSheet = true
        }) {
            HStack {
                Image(systemName: "person.2.fill")
                    .font(.system(size: 22))
                    .foregroundColor(Color(hex: "#E080C0"))
                    .frame(width: 32, height: 32)

                VStack(alignment: .leading, spacing: 4) {
                    Text("my why")
                        .font(.custom("Satoshi-Regular", size: 17))
                        .foregroundColor(Color(hex: "#4A2040"))

                    Text(anchorsSummary)
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
        .onReceive(NotificationCenter.default.publisher(for: .accountabilityAnchorsDidUpdate)) { _ in
            print("[debugEditAnchors] 🔄 AccountabilityAnchorsSection received update notification, refreshing...")
            refreshID = UUID()
        }
    }
}

struct AccountabilityAnchorsSection_Previews: PreviewProvider {
    static var previews: some View {
        AccountabilityAnchorsSection(showEditSheet: .constant(false))
            .background(AppTheme.Colors.background)
    }
}
