//
//  FrozenAnalyticsBanner.swift
//  Checkpoint
//
//  Banner displayed when analytics are frozen due to no active subscription
//

import SwiftUI

struct FrozenAnalyticsBanner: View {

    @StateObject private var viewModel = FrozenAnalyticsBannerViewModel()

    var body: some View {
        VStack(spacing: 12) {
            // Icon and title row
            HStack(spacing: 12) {
                // Snowflake icon
                Image(systemName: "snowflake")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.blue)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Analytics Frozen")
                        .font(.custom("Satoshi-Bold", size: 18))
                        .foregroundColor(AppTheme.Colors.textPrimary)

                    Text("No Active Subscription")
                        .font(.custom("Satoshi-Regular", size: 14))
                        .foregroundColor(AppTheme.Colors.textSecondary)
                }

                Spacer()
            }

            // Explanation text
            Text("Your progress is paused. Subscribe to resume tracking your savings and continue your protection.")
                .font(.custom("Satoshi-Regular", size: 14))
                .foregroundColor(AppTheme.Colors.textSecondary)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)

            // Subscribe button
            Button(action: {
                let generator = UIImpactFeedbackGenerator(style: .medium)
                generator.impactOccurred()

                Task {
                    await viewModel.showPaywall()
                }
            }) {
                if viewModel.isLoadingPaywallData {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(Color.blue)
                        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.medium))
                } else {
                    Text("Subscribe Now")
                        .font(.custom("Satoshi-Bold", size: 16))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(Color.blue)
                        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.medium))
                }
            }
            .disabled(viewModel.isLoadingPaywallData)
        }
        .padding(AppTheme.Spacing.lg)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.Radius.medium)
                .fill(Color.blue.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.Radius.medium)
                        .stroke(Color.blue.opacity(0.3), lineWidth: 2)
                )
        )
    }
}

// MARK: - Preview

struct FrozenAnalyticsBanner_Previews: PreviewProvider {
    static var previews: some View {
        FrozenAnalyticsBanner()
            .padding()
            .background(AppTheme.Colors.background)
    }
}
