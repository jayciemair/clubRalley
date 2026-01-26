//
//  MainTabView.swift
//  Checkpoint
//
//  Main tab bar component for the authenticated app experience
//

import SwiftUI

struct MainTabView: View {
    // MARK: - Properties
    @AppStorage("selectedTab") var selectedTab: MainTab = .home
    @StateObject private var appLifecycleManager = AppLifecycleManager.shared

    // MARK: - Body
    var body: some View {
        TabView(selection: $selectedTab) {
            Text("Home - Welcome to Club Ralley!")
                .tabItem {
                    Image(systemName: selectedTab == .home ? "house.fill" : "house")
                    Text("Home")
                }
                .tag(MainTab.home)
            
            Text("League Finder - Coming Soon!")
                .tabItem {
                    Image(systemName: "magnifyingglass")
                    Text("League Finder")
                }
                .tag(MainTab.findRalleys)
            
            Text("Post - Coming Soon!")
                .tabItem {
                    Image(systemName: selectedTab == .post ? "camera.fill" : "camera")
                    Text("Post")
                }
                .tag(MainTab.post)
            
            Text("Teams - Coming Soon!")
                .tabItem {
                    Image(systemName: selectedTab == .teams ? "person.2.fill" : "person.2")
                    Text("Teams")
                }
                .tag(MainTab.teams)
            
            Text("Profile - Coming Soon!")
                .tabItem {
                    Image(systemName: selectedTab == .profile ? "person.fill" : "person")
                    Text("Profile")
                }
                .tag(MainTab.profile)
        }
        .onAppear {
            // Initialize app data on first launch
            Task {
                await appLifecycleManager.initializeOnLaunch()
            }
        }
    }
}

// MARK: - Preview
struct MainTabView_Previews: PreviewProvider {
    static var previews: some View {
        MainTabView()
    }
}