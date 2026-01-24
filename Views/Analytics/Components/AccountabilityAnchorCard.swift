//
//  AccountabilityAnchorCard.swift
//  Checkpoint
//
//  Card displaying the user's accountability anchors (why they're doing this)
//

import SwiftUI

struct AccountabilityAnchorCard: View {

    // MARK: - Properties

    let anchors: [String]

    // MARK: - Computed Properties

    private var anchorText: String {
        guard !anchors.isEmpty else { return "" }

        // Convert anchors to lowercase for proper grammar
        let lowercaseAnchors = anchors.map { $0.lowercased() }

        if lowercaseAnchors.count == 1 {
            return "I am doing this for \(lowercaseAnchors[0])."
        } else if lowercaseAnchors.count == 2 {
            return "I am doing this for \(lowercaseAnchors[0]) and \(lowercaseAnchors[1])."
        } else {
            // Take first 3 anchors
            let displayAnchors = Array(lowercaseAnchors.prefix(3))
            let allButLast = displayAnchors.dropLast().joined(separator: ", ")
            let last = displayAnchors.last ?? ""
            return "I am doing this for \(allButLast), and \(last)."
        }
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: AppTheme.Spacing.sm) {
            if !anchors.isEmpty {
                Text(anchorText)
                    .font(.custom("Satoshi-Medium", size: 17))
                    .foregroundColor(AppTheme.Colors.textPrimary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppTheme.Spacing.lg)
        .padding(.horizontal, AppTheme.Spacing.lg)
        .background(AppTheme.Colors.darkSurface)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.medium))
    }
}

// MARK: - Preview

struct AccountabilityAnchorCard_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            AccountabilityAnchorCard(anchors: ["My family"])

            AccountabilityAnchorCard(anchors: ["My wife", "My kids"])

            AccountabilityAnchorCard(anchors: ["My health", "My family", "My future"])
        }
        .padding()
        .background(AppTheme.Colors.background)
    }
}