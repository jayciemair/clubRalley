//
//  AnalyticsHeaderView.swift
//  Checkpoint
//
//  Header view for Analytics screen with title and streak indicator
//

import SwiftUI

struct AnalyticsHeaderView: View {

    // MARK: - Body

    var body: some View {
        HStack {
            Text("Growth")
                .font(.custom("Satoshi-Bold", size: 34))
                .foregroundColor(AppTheme.Colors.textPrimary)

            Spacer()
        }
        .padding(.top, 10)
        .padding(.bottom, AppTheme.Spacing.md)
    }
}

// MARK: - Preview

struct AnalyticsHeaderView_Previews: PreviewProvider {
    static var previews: some View {
        AnalyticsHeaderView()
            .padding()
            .background(AppTheme.Colors.background)
    }
}
