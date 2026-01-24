//
//  CustomTabBar.swift
//  Checkpoint
//
//  Custom floating pill tab bar
//

import SwiftUI

struct CustomTabBar: View {
    @Binding var selectedTab: Tab
    @AppStorage("community_chat_enabled") private var communityChatEnabled = false
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack(spacing: 40) {
            // Main Tab
            TabBarButton(
                icon: "heart.fill",
                isSystemIcon: true,
                isSelected: selectedTab == .v3test,
                action: {
                    selectedTab = .v3test
                }
            )

            // Text Him Tab
            TabBarButton(
                icon: "trash.fill",
                isSystemIcon: true,
                isSelected: selectedTab == .textSimulator,
                action: {
                    selectedTab = .textSimulator
                }
            )

            // Community Tab (only shown if feature flag enabled)
            if communityChatEnabled {
                TabBarButton(
                    icon: "message.fill",
                    isSystemIcon: true,
                    isSelected: selectedTab == .community,
                    action: {
                        selectedTab = .community
                    }
                )
            }

            // Settings Tab
            TabBarButton(
                icon: "gearshape.fill",
                isSystemIcon: true,
                isSelected: selectedTab == .settings,
                action: {
                    selectedTab = .settings
                }
            )
        }
        .padding(.horizontal, 36)
        .padding(.vertical, 16)
        .background(
            Capsule()
                .fill(Color.white.opacity(0.85))
                .overlay(
                    Capsule()
                        .stroke(Color.white.opacity(0.5), lineWidth: 1)
                )
        )
        .padding(.horizontal, 50)
        .padding(.bottom, 16)
    }
}

struct TabBarButton: View {
    let icon: String
    let isSystemIcon: Bool
    let isSelected: Bool
    var selectedColor: Color? = nil
    let action: () -> Void
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Button(action: {
            let impact = UIImpactFeedbackGenerator(style: .light)
            impact.impactOccurred()
            action()
        }) {
            Group {
                if isSystemIcon {
                    Image(systemName: icon)
                        .font(.system(size: 26, weight: .medium))
                } else {
                    Image(icon)
                        .resizable()
                        .renderingMode(.template)
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 26, height: 26)
                }
            }
            .foregroundColor(isSelected ? Color(hex: "#E05A9C") : Color(hex: "#8A8A8A"))
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// Visual effect blur for background (kept for potential other uses)
struct VisualEffectBlur: UIViewRepresentable {
    var blurStyle: UIBlurEffect.Style

    func makeUIView(context: Context) -> UIVisualEffectView {
        UIVisualEffectView(effect: UIBlurEffect(style: blurStyle))
    }

    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {
        uiView.effect = UIBlurEffect(style: blurStyle)
    }
}
