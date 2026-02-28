//
//  ClubRalleyTabBar.swift
//  Club Ralley
//
//  Custom tab bar for Club Ralley social platform
//

import SwiftUI

struct ClubRalleyTabBar: View {
    @Binding var selectedTab: MainTab
    var unreadChatCount: Int = 0

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
                    badgeCount: item.tab == .teams ? unreadChatCount : 0,
                    action: { selectedTab = item.tab }
                )
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
        .padding(.bottom, 2)
        .background(
            VStack(spacing: 0) {
                Rectangle()
                    .fill(ClubRalleyTheme.Colors.tabDivider)
                    .frame(height: 1)
                Rectangle()
                    .fill(ClubRalleyTheme.Colors.white)
            }
            .ignoresSafeArea(.container, edges: .bottom)
        )
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: selectedTab)
    }

}

struct TabBarButton: View {
    let tab: MainTab
    let icon: String
    let title: String
    let isSelected: Bool
    var badgeCount: Int = 0
    let action: () -> Void

    var body: some View {
        Button(action: {
            let impact = UIImpactFeedbackGenerator(style: .light)
            impact.impactOccurred()
            action()
        }) {
            VStack(spacing: 4) {
                ZStack(alignment: .topTrailing) {
                    Image(systemName: icon)
                        .font(.system(size: 20, weight: isSelected ? .semibold : .regular))
                        .scaleEffect(isSelected ? 1.15 : 1.0)
                        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isSelected)
                        .frame(height: 24)

                    if badgeCount > 0 {
                        Text(badgeCount > 9 ? "9+" : "\(badgeCount)")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(.white)
                            .frame(minWidth: 16, minHeight: 16)
                            .background(ClubRalleyTheme.Colors.badgeRed)
                            .clipShape(Capsule())
                            .offset(x: 8, y: -6)
                    }
                }

                Text(title)
                    .font(.system(size: 9.5, weight: .bold, design: .rounded))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .foregroundColor(isSelected ? ClubRalleyTheme.Colors.darkGreen : ClubRalleyTheme.Colors.unselectedTab)
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
        ClubRalleyTabBar(selectedTab: .constant(.home), unreadChatCount: 3)
    }
    .background(ClubRalleyTheme.Colors.sageGreen.opacity(0.1))
}
