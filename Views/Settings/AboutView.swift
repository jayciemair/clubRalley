//
//  AboutView.swift
//  Club Ralley
//
//  About the app information
//

import SwiftUI

struct AboutView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: ClubRalleyTheme.Spacing.lg) {
                // App info
                VStack {
                    Image(systemName: "figure.run.circle.fill")
                        .font(.system(size: 80))
                        .foregroundColor(ClubRalleyTheme.Colors.accent)

                    Text("Club Ralley")
                        .font(ClubRalleyTheme.Typography.title1)
                        .foregroundColor(ClubRalleyTheme.Colors.text)

                    Text("GFTO - Get the F*** Outside")
                        .font(ClubRalleyTheme.Typography.subheadline)
                        .foregroundColor(ClubRalleyTheme.Colors.accent)

                    Text("Version 1.0.0")
                        .font(ClubRalleyTheme.Typography.caption)
                        .foregroundColor(ClubRalleyTheme.Colors.secondaryText)
                }
                .frame(maxWidth: .infinity)
                .padding(.top, ClubRalleyTheme.Spacing.xl)

                // Description
                VStack(alignment: .leading, spacing: ClubRalleyTheme.Spacing.md) {
                    Text("About Club Ralley")
                        .font(ClubRalleyTheme.Typography.headline)
                        .foregroundColor(ClubRalleyTheme.Colors.text)

                    Text("Club Ralley is a social platform designed for former athletes navigating post-grad life. Think of it as a LinkedIn-style network for the athletic side of your identity.")
                        .font(ClubRalleyTheme.Typography.body)
                        .foregroundColor(ClubRalleyTheme.Colors.secondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()
            }
            .padding(ClubRalleyTheme.Spacing.lg)
        }
        .navigationTitle("About")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct AthleteVerificationView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 60))
                .foregroundColor(ClubRalleyTheme.Colors.accent)

            Text("Athlete Verification")
                .font(ClubRalleyTheme.Typography.title2)
                .foregroundColor(ClubRalleyTheme.Colors.text)

            Text("Verify your athletic background to get a verified badge on your profile.")
                .font(ClubRalleyTheme.Typography.body)
                .foregroundColor(ClubRalleyTheme.Colors.secondaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            Button(action: {}) {
                Text("Start Verification")
                    .font(ClubRalleyTheme.Typography.bodyBold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 14)
                    .background(ClubRalleyTheme.Colors.accent)
                    .cornerRadius(12)
            }
            .padding(.top, 20)

            Spacer()
        }
        .padding(.top, 40)
        .navigationTitle("Verification")
        .navigationBarTitleDisplayMode(.inline)
    }
}
