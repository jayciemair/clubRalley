//
//  SettingsSection.swift
//  Dial
//
//  Section header component for settings screens
//

import SwiftUI

struct SettingsSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: () -> Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Section header
            Text(title.lowercased())
                .font(.custom("Satoshi-Bold", size: 18))
                .foregroundColor(.white)
                .padding(.horizontal, 20)

            // Section content
            VStack(spacing: 8) {
                content()
            }
        }
    }
}

// Preview
struct SettingsSection_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 32) {
            SettingsSection(title: "Core Settings & Functionality") {
                SettingsRow(
                    icon: "globe",
                    title: "Language",
                    subtitle: "Select your preferred language",
                    trailingText: "English"
                )
                
                SettingsRow(
                    icon: "music.note",
                    iconColor: AppTheme.Colors.primary,
                    title: "Alarm Sound",
                    subtitle: "Customize the sound for important alerts"
                )
            }
            
            SettingsSection(title: "App Settings") {
                SettingsRow(
                    icon: "bell.fill",
                    title: "Push Notifications",
                    subtitle: "Receive important app notifications",
                    showChevron: false,
                    showToggle: true,
                    isToggleOn: .constant(true)
                )
            }
        }
        .padding()
        .background(AppTheme.Colors.background)
    }
}