//
//  ClubRalleyTabBar.swift
//  Club Ralley
//
//  Custom tab bar for Club Ralley social platform
//

import SwiftUI

struct ClubRalleyTabBar: View {
    @Binding var selectedTab: MainTab

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
                    action: { selectedTab = item.tab }
                )
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
        .padding(.bottom, safeAreaBottomInset)
        .background(
            VStack(spacing: 0) {
                Rectangle()
                    .fill(Color(hex: "#d5d7cb"))
                    .frame(height: 1)
                Rectangle()
                    .fill(Color.white)
            }
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
    let action: () -> Void

    var body: some View {
        Button(action: {
            let impact = UIImpactFeedbackGenerator(style: .light)
            impact.impactOccurred()
            action()
        }) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: isSelected ? .semibold : .regular))
                    .frame(height: 24)

                Text(title)
                    .font(.system(size: 9.5, weight: .bold, design: .rounded))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .foregroundColor(isSelected ? Color(hex: "#2C4F40") : Color(hex: "#bbbbbb"))
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