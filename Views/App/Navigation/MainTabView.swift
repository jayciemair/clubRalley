//
//  MainTabView.swift
//  Club Ralley
//
//  Main tab bar component for the authenticated app experience
//

import SwiftUI

struct MainTabView: View {
    // MARK: - Properties
    @AppStorage("selectedTab") var selectedTab: MainTab = .home
    @StateObject private var appLifecycleManager = AppLifecycleManager.shared
    @StateObject private var postManager = PostManager()
    @StateObject private var ralleyManager = RalleyManager()
    @StateObject private var messagingService = MessagingService()

    // MARK: - Body
    var body: some View {
        TabView(selection: $selectedTab) {
            // Home Tab - Social Feed
            HomeFeedView()
                .environmentObject(postManager)
                .environmentObject(ralleyManager)
                .tabItem {
                    Image(systemName: selectedTab == .home ? "house.fill" : "house")
                    Text("Home")
                }
                .tag(MainTab.home)

            // Find Ralleys Tab - Discover pickup games
            FindRalleysView()
                .environmentObject(ralleyManager)
                .tabItem {
                    Image(systemName: selectedTab == .findRalleys ? "sportscourt.fill" : "sportscourt")
                    Text("Find Ralleys")
                }
                .tag(MainTab.findRalleys)

            // Post Tab - Create new content
            PostCreationInterfaceView()
                .environmentObject(postManager)
                .tabItem {
                    Image(systemName: selectedTab == .post ? "plus.circle.fill" : "plus.circle")
                    Text("Post")
                }
                .tag(MainTab.post)

            // Messages Tab - Direct messaging
            MessagesView()
                .tabItem {
                    Image(systemName: selectedTab == .teams ? "message.fill" : "message")
                    Text("Messages")
                }
                .tag(MainTab.teams)

            // Profile Tab - User profile
            ProfileTabView()
                .tabItem {
                    Image(systemName: selectedTab == .profile ? "person.fill" : "person")
                    Text("Profile")
                }
                .tag(MainTab.profile)
        }
        .accentColor(Color(hex: "#2C4F40"))
        .onAppear {
            // Initialize app data on first launch
            Task {
                await appLifecycleManager.initializeOnLaunch()
                await messagingService.loadConversations()
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