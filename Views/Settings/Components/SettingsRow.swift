//
//  SettingsRow.swift
//  Dial
//
//  A reusable row component for settings screens
//

import SwiftUI

struct SettingsRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String?
    let showChevron: Bool
    let showToggle: Bool
    let isToggleOn: Binding<Bool>?
    let trailingText: String?
    let isCustomIcon: Bool
    
    init(
        icon: String,
        iconColor: Color = Color(hex: "#E080C0"),
        title: String,
        subtitle: String? = nil,
        showChevron: Bool = true,
        showToggle: Bool = false,
        isToggleOn: Binding<Bool>? = nil,
        trailingText: String? = nil,
        isCustomIcon: Bool = false
    ) {
        self.icon = icon
        self.iconColor = iconColor
        self.title = title
        self.subtitle = subtitle
        self.showChevron = showChevron
        self.showToggle = showToggle
        self.isToggleOn = isToggleOn
        self.trailingText = trailingText
        self.isCustomIcon = isCustomIcon
    }
    
    var body: some View {
        HStack(spacing: AppTheme.Spacing.md) {
            // Icon
            if isCustomIcon {
                Image(icon)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 60, height: 60)
            } else {
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundColor(iconColor)
                    .frame(width: 32, height: 32)
            }
            
            // Text content
            VStack(alignment: .leading, spacing: 4) {
                Text(title.lowercased())
                    .font(.custom("Satoshi-Regular", size: 17))
                    .foregroundColor(Color(hex: "#4A2040"))

                if let subtitle = subtitle {
                    Text(subtitle.lowercased())
                        .font(.system(size: 14))
                        .foregroundColor(Color(hex: "#6A3060").opacity(0.7))
                }
            }

            Spacer()

            // Trailing content
            if let trailingText = trailingText {
                Text(trailingText.lowercased())
                    .font(.system(size: 17))
                    .foregroundColor(Color(hex: "#6A3060").opacity(0.7))
            }

            if showToggle, let isToggleOn = isToggleOn {
                Toggle("", isOn: isToggleOn)
                    .labelsHidden()
                    .tint(Color(hex: "#E080C0"))
            }

            if showChevron && !showToggle {
                Image(systemName: "chevron.right")
                    .font(.custom("Satoshi-Bold", size: 14))
                    .foregroundColor(Color(hex: "#6A3060").opacity(0.5))
            }
        }
        .padding(.vertical, subtitle != nil ? 12 : 16)
        .padding(.horizontal, 20)
        .background(Color.white.opacity(0.6))
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.white.opacity(0.3), lineWidth: 1)
        )
    }
}

// Preview
struct SettingsRow_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 16) {
            SettingsRow(
                icon: "globe",
                title: "Language",
                subtitle: "Select your preferred language",
                trailingText: "English"
            )
            
            SettingsRow(
                icon: "bell.fill",
                iconColor: .blue,
                title: "Push Notifications",
                subtitle: "Receive important app notifications",
                showChevron: false,
                showToggle: true,
                isToggleOn: .constant(true)
            )
            
            SettingsRow(
                icon: "questionmark.circle",
                title: "Help Center",
                subtitle: "Get help and support"
            )
        }
        .padding()
        .background(AppTheme.Colors.background)
    }
}