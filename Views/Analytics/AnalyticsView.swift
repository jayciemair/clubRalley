//
//  AnalyticsView.swift
//  Checkpoint
//
//  Analytics tracker - shows user's recovery progress and statistics
//

import SwiftUI
import CoreHaptics

struct AnalyticsView: View {

    // MARK: - State

    @ObservedObject private var viewModel = AnalyticsViewModel.shared
    @State private var showingSavingsExplanation = false

    // MARK: - Body

    var body: some View {
        ZStack {
            AppGradientBackground()

            ScrollView {
                VStack(spacing: AppTheme.Spacing.lg) {
                    // Header
                    AnalyticsHeaderView()
                        .padding(.horizontal, AppTheme.Spacing.lg)

                    // Frozen analytics banner (show when not eligible)
                    if !viewModel.isEligible {
                        FrozenAnalyticsBanner()
                            .padding(.horizontal, AppTheme.Spacing.lg)
                    }

                    // 1. Main balance card (hero)
                    TotalSavedCard(
                        amount: viewModel.displayedAmount,
                        showingExplanation: $showingSavingsExplanation
                    )
                    .padding(.horizontal, AppTheme.Spacing.lg)

                    // 3. Accountability anchor
                    if !viewModel.accountabilityAnchors.isEmpty {
                        AccountabilityAnchorCard(anchors: viewModel.accountabilityAnchors)
                            .padding(.horizontal, AppTheme.Spacing.lg)
                    }

                    // 4. Stats grid
                    StatsGridLayout(stats: [
                        .init(
                            icon: "shield.checkered",
                            value: "\(viewModel.displayedGamblingDaysPrevented)",
                            title: "Contact-Free \nDays",
                            iconColor: .green
                        ),
                        .init(
                            icon: "heart.fill",
                            value: viewModel.formattedDailySavings,
                            title: "Healing \nProgress",
                            iconColor: .green
                        ),
                        .init(
                            icon: "calendar",
                            value: "\(viewModel.daysActive)",
                            title: "Days Since Joining",
                            iconColor: .green
                        ),
                        .init(
                            icon: "xmark.circle.fill",
                            value: "\(viewModel.displayedBetsAvoided)",
                            title: "Texts Avoided",
                            iconColor: .green
                        ),
                        .init(
                            icon: "trophy.fill",
                            value: viewModel.userPercentile,
                            title: "Of All Users",
                            iconColor: .orange
                        )
                    ])
                    .padding(.horizontal, AppTheme.Spacing.lg)

                    // Bottom padding for tab bar
                    Color.clear
                        .frame(height: 100)
                }
            }
            .scrollIndicators(.hidden)

            // Fullscreen overlay for explanation popup
            if showingSavingsExplanation {
                SavingsExplanationView(isShowing: $showingSavingsExplanation)
                    .transition(.opacity)
                    .animation(.easeInOut(duration: 0.2), value: showingSavingsExplanation)
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            viewModel.onAppear()
        }
        .onDisappear {
            viewModel.onDisappear()
        }
    }
}

// MARK: - Preview

struct AnalyticsView_Previews: PreviewProvider {
    static var previews: some View {
        AnalyticsView()
    }
}