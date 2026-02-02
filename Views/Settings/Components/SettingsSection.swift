//
//  SettingsSection.swift
//  Club Ralley
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