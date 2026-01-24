//
//  SimulatorHeader.swift
//  goh
//
//  iMessage-style header for text simulator
//

import SwiftUI

struct SimulatorHeader: View {
    let contactStatus: ContactStatus
    let onBack: () -> Void
    @Environment(\.colorScheme) private var colorScheme

    private let pinkColor = Color(red: 1.0, green: 0.61, blue: 0.87) // #FE9CDD

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                // Back button
                Button(action: onBack) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(pinkColor)
                }

                // Trash can avatar
                ZStack {
                    Circle()
                        .fill(pinkColor.opacity(0.15))
                        .frame(width: 36, height: 36)

                    Image(systemName: "trash.fill")
                        .font(.system(size: 16))
                        .foregroundColor(pinkColor)
                }

                // Name and status
                VStack(alignment: .leading, spacing: 2) {
                    Text("him")
                        .font(.custom("Satoshi-Bold", size: 17))
                        .foregroundColor(colorScheme == .dark ? .white : .black)

                    Text(contactStatus.displayText)
                        .font(.custom("Satoshi-Regular", size: 12))
                        .foregroundColor(statusColor)
                }

                Spacer()

                // Branding
                Text("GET OVER HIM")
                    .font(.custom("Satoshi-Black", size: 22))
                    .foregroundColor(pinkColor)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(colorScheme == .dark ? Color(red: 0.17, green: 0.17, blue: 0.18) : Color.white)  // #2C2C2E

            // Separator
            Rectangle()
                .fill(Color.gray.opacity(0.2))
                .frame(height: 0.5)
        }
    }

    private var statusColor: Color {
        switch contactStatus {
        case .online, .typing:
            return .green
        case .currentlyDoing:
            return .orange
        case .offline:
            return .gray
        }
    }
}

#Preview {
    VStack {
        SimulatorHeader(contactStatus: .online, onBack: {})
        SimulatorHeader(contactStatus: .typing, onBack: {})
        SimulatorHeader(contactStatus: .offline(lastActive: Date().addingTimeInterval(-300)), onBack: {})
        SimulatorHeader(contactStatus: .currentlyDoing(activity: "at a bar with friends"), onBack: {})
    }
    .background(Color(red: 0.98, green: 0.96, blue: 0.97))
}
