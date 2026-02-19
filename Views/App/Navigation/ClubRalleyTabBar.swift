//
//  ClubRalleyTabBar.swift
//  Club Ralley
//
//  Custom tab bar for Club Ralley social platform
//

import SwiftUI

struct ClubRalleyTabBar: View {
    @Binding var selectedTab: MainTab
    @Namespace private var tabIndicator

    private let tabs: [(tab: MainTab, icon: String, filledIcon: String, title: String)] = [
        (.home, "house", "house.fill", "Home"),
        (.ralleys, "magnifyingglass", "magnifyingglass", "Ralleys"),
        (.post, "camera", "camera.fill", "Post"),
        (.teams, "person.2", "person.2.fill", "Teams"),
        (.profile, "person", "person.fill", "Profile")
    ]

    var body: some View {
        HStack(spacing: 0) {
            ForEach(tabs, id: \.tab) { item in
                TabBarButton(
                    tab: item.tab,
                    icon: selectedTab == item.tab ? item.filledIcon : item.icon,
                    title: item.title,
                    isSelected: selectedTab == item.tab,
                    namespace: tabIndicator,
                    action: { selectedTab = item.tab }
                )
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 8)
        .padding(.bottom, safeAreaBottomInset)
        .background(
            Rectangle()
                .fill(ClubRalleyTheme.Colors.background)
                .clubRalleyShadow(ClubRalleyTheme.Shadows.medium)
                .ignoresSafeArea(.container, edges: .bottom)
        )
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: selectedTab)
    }

    private var safeAreaBottomInset: CGFloat {
        let scenes = UIApplication.shared.connectedScenes
        let windowScene = scenes.first as? UIWindowScene
        return windowScene?.windows.first?.safeAreaInsets.bottom ?? 0
    }
}

struct TabBarButton: View {
    let tab: MainTab
    let icon: String
    let title: String
    let isSelected: Bool
    var namespace: Namespace.ID
    let action: () -> Void

    var body: some View {
        Button(action: {
            let impact = UIImpactFeedbackGenerator(style: .light)
            impact.impactOccurred()
            action()
        }) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .medium))
                    .frame(height: 24)

                Text(title)
                    .font(ClubRalleyTheme.Typography.caption2)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)

                if isSelected {
                    Circle()
                        .fill(ClubRalleyTheme.Colors.accent)
                        .frame(width: 5, height: 5)
                        .matchedGeometryEffect(id: "tabIndicator", in: namespace)
                } else {
                    Circle()
                        .fill(Color.clear)
                        .frame(width: 5, height: 5)
                }
            }
            .foregroundColor(isSelected ? ClubRalleyTheme.Colors.accent : ClubRalleyTheme.Colors.secondaryText)
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Preview
#Preview {
    VStack {
        Spacer()
        ClubRalleyTabBar(selectedTab: .constant(.home))
    }
    .background(ClubRalleyTheme.Colors.sageGreen.opacity(0.1))
}