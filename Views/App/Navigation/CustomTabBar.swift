//
//  CustomTabBar.swift
//  Checkpoint
//
//  Custom floating pill tab bar
//

import SwiftUI

struct CustomTabBar: View {
    @Binding var selectedTab: MainTab
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack(spacing: 40) {
            // Home Tab
            TabBarButton(
                icon: "house.fill",
                isSystemIcon: true,
                isSelected: selectedTab == .home,
                action: {
                    selectedTab = .home
                }
            )

            // League Finder Tab
            TabBarButton(
                icon: "magnifyingglass",
                isSystemIcon: true,
                isSelected: selectedTab == .leagueFinder,
                action: {
                    selectedTab = .leagueFinder
                }
            )

            // Post Tab
            TabBarButton(
                icon: "camera.fill",
                isSystemIcon: true,
                isSelected: selectedTab == .post,
                action: {
                    selectedTab = .post
                }
            )

            // Teams Tab
            TabBarButton(
                icon: "person.2.fill",
                isSystemIcon: true,
                isSelected: selectedTab == .teams,
                action: {
                    selectedTab = .teams
                }
            )

            // Profile Tab
            TabBarButton(
                icon: "person.fill",
                isSystemIcon: true,
                isSelected: selectedTab == .profile,
                action: {
                    selectedTab = .profile
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
            .foregroundColor(isSelected ? Color(hex: "#2C4F40") : Color(hex: "#8A8A8A"))
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
