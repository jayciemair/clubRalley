//
//  ClubRalleyTabBar.swift
//  Club Ralley
//
//  Custom tab bar for Club Ralley social platform
//

import SwiftUI

struct ClubRalleyTabBar: View {
    @Binding var selectedTab: MainTab
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        HStack(spacing: 0) {
            // Home Tab
            TabBarButton(
                tab: .home,
                icon: selectedTab == .home ? "house.fill" : "house",
                title: "Home",
                isSelected: selectedTab == .home,
                action: {
                    selectedTab = .home
                }
            )
            
            Spacer()
            
            // Find Ralleys Tab
            TabBarButton(
                tab: .findRalleys,
                icon: "sportscourt",
                title: "Find Ralleys",
                isSelected: selectedTab == .findRalleys,
                action: {
                    selectedTab = .findRalleys
                }
            )
            
            Spacer()
            
            // Post Tab
            TabBarButton(
                tab: .post,
                icon: selectedTab == .post ? "camera.fill" : "camera",
                title: "Post",
                isSelected: selectedTab == .post,
                action: {
                    selectedTab = .post
                }
            )
            
            Spacer()
            
            // Teams Tab
            TabBarButton(
                tab: .teams,
                icon: selectedTab == .teams ? "person.2.fill" : "person.2",
                title: "Teams",
                isSelected: selectedTab == .teams,
                action: {
                    selectedTab = .teams
                }
            )
            
            Spacer()
            
            // Profile Tab
            TabBarButton(
                tab: .profile,
                icon: selectedTab == .profile ? "person.fill" : "person",
                title: "Profile",
                isSelected: selectedTab == .profile,
                action: {
                    selectedTab = .profile
                }
            )
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(
            Rectangle()
                .fill(ClubRalleyTheme.Colors.background)
                .clubRalleyShadow(ClubRalleyTheme.Shadows.medium)
        )
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
                    .font(.system(size: 20, weight: .medium))
                    .frame(height: 24)
                
                Text(title)
                    .font(ClubRalleyTheme.Typography.caption2)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .foregroundColor(isSelected ? ClubRalleyTheme.Colors.accent : ClubRalleyTheme.Colors.secondaryText)
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Preview
struct ClubRalleyTabBar_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            Spacer()
            ClubRalleyTabBar(selectedTab: .constant(.home))
        }
        .background(ClubRalleyTheme.Colors.sageGreen.opacity(0.1))
    }
}