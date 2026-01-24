//
//  UserRequestsSection.swift
//  Checkpoint
//
//  User feedback and request buttons for settings
//

import SwiftUI

struct UserRequestsSection: View {
    @Binding var showWebsiteBlockRequest: Bool
    @Binding var showFeatureRequest: Bool

    var body: some View {
        VStack(spacing: AppTheme.Spacing.sm) {
            // Request Website Block
            Button(action: {
                showWebsiteBlockRequest = true
            }) {
                HStack {
                    Image(systemName: "shield.lefthalf.filled")
                        .font(.system(size: 24))
                        .foregroundColor(AppTheme.Colors.primary)
                        .frame(width: 32, height: 32)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Request Website Block")
                            .font(.custom("Satoshi-Regular", size: 17))
                            .foregroundColor(AppTheme.Colors.textPrimary)

                        Text("Submit a site to be blocked")
                            .font(.system(size: 14))
                            .foregroundColor(AppTheme.Colors.textSecondary)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 14))
                        .foregroundColor(AppTheme.Colors.textSecondary)
                }
                .padding(.vertical, 12)
                .padding(.horizontal, AppTheme.Spacing.lg)
                .background(AppTheme.Colors.darkSurface)
                .cornerRadius(AppTheme.Radius.medium)
            }
            .buttonStyle(PlainButtonStyle())
            .padding(.horizontal, AppTheme.Spacing.lg)

            // Request Feature
            Button(action: {
                showFeatureRequest = true
            }) {
                HStack {
                    Image(systemName: "lightbulb.fill")
                        .font(.system(size: 24))
                        .foregroundColor(AppTheme.Colors.primary)
                        .frame(width: 32, height: 32)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Request Feature")
                            .font(.custom("Satoshi-Regular", size: 17))
                            .foregroundColor(AppTheme.Colors.textPrimary)

                        Text("Share your ideas with us")
                            .font(.system(size: 14))
                            .foregroundColor(AppTheme.Colors.textSecondary)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 14))
                        .foregroundColor(AppTheme.Colors.textSecondary)
                }
                .padding(.vertical, 12)
                .padding(.horizontal, AppTheme.Spacing.lg)
                .background(AppTheme.Colors.darkSurface)
                .cornerRadius(AppTheme.Radius.medium)
            }
            .buttonStyle(PlainButtonStyle())
            .padding(.horizontal, AppTheme.Spacing.lg)
        }
    }
}

struct UserRequestsSection_Previews: PreviewProvider {
    static var previews: some View {
        UserRequestsSection(showWebsiteBlockRequest: .constant(false), showFeatureRequest: .constant(false))
            .background(AppTheme.Colors.background)
    }
}