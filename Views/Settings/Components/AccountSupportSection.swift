//
//  AccountSupportSection.swift
//  Dial
//
//  Account & Support section component for settings
//  Contains feedback, help, legal links, and account management
//

import SwiftUI

struct AccountSupportSection: View {
    @Environment(\.openURL) var openURL

    var body: some View {
        VStack(spacing: 8) {

            // Need help? (FAQ)
            Button(action: {
                if let url = URL(string: AppLinks.Website.faq) {
                    UIApplication.shared.open(url)
                }
            }) {
                HStack {
                    Image(systemName: "questionmark.circle")
                        .font(.system(size: 24))
                        .foregroundColor(Color(hex: "#E080C0"))
                        .frame(width: 32, height: 32)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("need help?")
                            .font(.custom("Satoshi-Regular", size: 17))
                            .foregroundColor(Color(hex: "#4A2040"))

                        Text("visit our faq")
                            .font(.system(size: 14))
                            .foregroundColor(Color(hex: "#6A3060").opacity(0.7))
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

            // Terms of Service
            Button(action: {
                if let url = URL(string: AppLinks.Website.termsOfService) {
                    openURL(url)
                }
            }) {
                HStack {
                    Image(systemName: "doc.text")
                        .font(.system(size: 24))
                        .foregroundColor(Color(hex: "#E080C0"))
                        .frame(width: 32, height: 32)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("terms of service")
                            .font(.custom("Satoshi-Regular", size: 17))
                            .foregroundColor(Color(hex: "#4A2040"))

                        Text("view our terms and conditions")
                            .font(.system(size: 14))
                            .foregroundColor(Color(hex: "#6A3060").opacity(0.7))
                    }

                    Spacer()

                    Image(systemName: "arrow.up.right")
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

            // Privacy Policy
            Button(action: {
                if let url = URL(string: AppLinks.Website.privacyPolicy) {
                    openURL(url)
                }
            }) {
                HStack {
                    Image(systemName: "lock.doc")
                        .font(.system(size: 24))
                        .foregroundColor(Color(hex: "#E080C0"))
                        .frame(width: 32, height: 32)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("privacy policy")
                            .font(.custom("Satoshi-Regular", size: 17))
                            .foregroundColor(Color(hex: "#4A2040"))

                        Text("how we protect your data")
                            .font(.system(size: 14))
                            .foregroundColor(Color(hex: "#6A3060").opacity(0.7))
                    }

                    Spacer()

                    Image(systemName: "arrow.up.right")
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
        }
    }
}

struct AccountSupportSection_Previews: PreviewProvider {
    static var previews: some View {
        AccountSupportSection()
            .background(AppTheme.Colors.background)
    }
}
