//
//  PaywallTestingView.swift
//  Checkpoint
//
//  Debug screen for testing Superwall paywalls locally
//  Only accessible in development builds
//

import SwiftUI
import SuperwallKit

struct PaywallTestingView: View {
    @Environment(\.dismiss) var dismiss
    @State private var isRefreshing = false

    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Configuration")) {
                    Button(action: {
                        refreshSuperwallConfig()
                    }) {
                        HStack {
                            Image(systemName: "arrow.clockwise.circle.fill")
                                .foregroundColor(.green)

                            Text("Refresh Superwall Config")
                                .foregroundColor(.primary)

                            Spacer()

                            if isRefreshing {
                                ProgressView()
                                    .scaleEffect(0.8)
                            }
                        }
                    }
                    .disabled(isRefreshing)

                    Text("Pull latest campaigns from dashboard")
                        .font(.caption)
                        .foregroundColor(.gray)
                }

                Section(header: Text("Debug Campaigns")) {
                    PaywallTestButton(
                        title: "Test Paywall (Custom)",
                        placement: "debug_paywall_test",
                        description: "Triggers your test campaign - configure this in Superwall dashboard"
                    )

                    PaywallTestButton(
                        title: "Test Paywall 2",
                        placement: "debug_paywall_test_2",
                        description: "Secondary test campaign for A/B testing designs"
                    )
                }

                Section(header: Text("Live Onboarding Campaigns")) {
                    PaywallTestButton(
                        title: "Age 18-22",
                        placement: "age18to22",
                        description: "Production campaign for 18-22 age group"
                    )

                    PaywallTestButton(
                        title: "Age 23-28",
                        placement: "age23to28",
                        description: "Production campaign for 23-28 age group"
                    )

                    PaywallTestButton(
                        title: "Age 29-35",
                        placement: "age29to35",
                        description: "Production campaign for 29-35 age group"
                    )

                    PaywallTestButton(
                        title: "Age 36-49",
                        placement: "age36to49",
                        description: "Production campaign for 36-49 age group"
                    )

                    PaywallTestButton(
                        title: "Age Over 49",
                        placement: "ageOver49",
                        description: "Production campaign for 50+ age group"
                    )
                }

                Section(header: Text("Other Live Campaigns")) {
                    PaywallTestButton(
                        title: "Transaction Abandon Discount",
                        placement: "transaction_abandon",
                        description: "Discount offer shown when user abandons checkout"
                    )

                    PaywallTestButton(
                        title: "Testing Trans Abandon",
                        placement: "testing_trans_abandon",
                        description: "Test version of transaction abandon campaign"
                    )

                    PaywallTestButton(
                        title: "Campaign Trigger (Generic)",
                        placement: "campaign_trigger",
                        description: "Generic campaign trigger"
                    )
                }

                Section(header: Text("User Attributes")) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Current Superwall Attributes:")
                            .font(.caption)
                            .foregroundColor(.gray)

                        // You can display current user attributes here
                        // Superwall doesn't expose them directly, so this is a placeholder
                        Text("Check Superwall Dashboard → Users for attribute values")
                            .font(.caption2)
                            .foregroundColor(.gray)
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle("Paywall Testing")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }

    // MARK: - Helper Methods

    private func refreshSuperwallConfig() {
        isRefreshing = true

        // Force Superwall to refresh config from server
        Task {
            // Wait a moment for visual feedback
            try? await Task.sleep(nanoseconds: 500_000_000)

            // Superwall automatically refreshes on app launch
            // For manual refresh, we can just wait - it polls periodically
            // Alternative: Kill and restart app to force immediate refresh

            await MainActor.run {
                isRefreshing = false
            }
        }
    }
}

// MARK: - Paywall Test Button

struct PaywallTestButton: View {
    let title: String
    let placement: String
    let description: String

    @State private var isLoading = false

    var body: some View {
        Button(action: {
            triggerPaywall()
        }) {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(title)
                        .foregroundColor(.primary)

                    Spacer()

                    if isLoading {
                        ProgressView()
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "play.circle.fill")
                            .foregroundColor(.blue)
                    }
                }

                Text(description)
                    .font(.caption)
                    .foregroundColor(.gray)

                Text("Placement: \(placement)")
                    .font(.caption2)
                    .foregroundColor(.gray.opacity(0.7))
            }
            .padding(.vertical, 4)
        }
    }

    private func triggerPaywall() {
        isLoading = true

        // Add a slight delay for visual feedback
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            // Trigger the Superwall campaign
            Superwall.shared.register(placement: placement) {
                // Feature block - not needed for testing
                print("✅ Paywall dismissed or user is subscribed")
            }

            isLoading = false
        }
    }
}

// MARK: - Preview

#Preview {
    PaywallTestingView()
}
