//
//  ClubRalleyMainView.swift
//  Club Ralley
//
//  Main authenticated app view with tab navigation
//

import SwiftUI

// Note: ProfileView is imported from Views/Profile/ProfileView.swift

struct ClubRalleyMainView: View {
    @State private var selectedTab: MainTab = .home
    @StateObject private var appLifecycleManager = AppLifecycleManager.shared
    
    var body: some View {
        ZStack {
            // Tab content
            Group {
                switch selectedTab {
                case .home:
                    NavigationStack {
                        HomeView()
                    }
                case .findRalleys:
                    NavigationStack {
                        LeagueFinderView()
                    }
                case .post:
                    NavigationStack {
                        PostView()
                    }
                case .teams:
                    NavigationStack {
                        TeamsView()
                    }
                case .profile:
                    NavigationStack {
                        ProfileView()
                    }
                }
            }
            
            // Tab bar overlay
            VStack {
                Spacer()
                ClubRalleyTabBar(selectedTab: $selectedTab)
            }
        }
        .ignoresSafeArea(.keyboard)
        .onAppear {
            // Initialize app data on first launch
            Task {
                await appLifecycleManager.initializeOnLaunch()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("ClubRalleyDeepLink"))) { notification in
            if let deepLink = notification.object as? DeepLink {
                selectedTab = deepLink.type.targetTab
                // Handle specific navigation to the deep linked content
                // This would be handled by the specific tab's navigation stack
            }
        }
    }
}

// MARK: - Placeholder Views

struct HomeView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: ClubRalleyTheme.Spacing.lg) {
                // Welcome header
                VStack(spacing: ClubRalleyTheme.Spacing.md) {
                    Text("Welcome to Club Ralley")
                        .font(ClubRalleyTheme.Typography.largeTitle)
                        .foregroundColor(ClubRalleyTheme.Colors.text)
                    
                    Text("GFTO - Get the F*** Outside")
                        .font(ClubRalleyTheme.Typography.title3)
                        .foregroundColor(ClubRalleyTheme.Colors.accent)
                }
                .multilineTextAlignment(.center)
                
                // Activity feed preview
                VStack(alignment: .leading, spacing: ClubRalleyTheme.Spacing.md) {
                    Text("Your Feed")
                        .font(ClubRalleyTheme.Typography.headline)
                        .foregroundColor(ClubRalleyTheme.Colors.text)
                    
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Coming soon:")
                            .font(ClubRalleyTheme.Typography.bodyBold)
                            .foregroundColor(ClubRalleyTheme.Colors.text)
                        
                        Text("• See what your friends are up to")
                        Text("• Discover trending activities in your area")
                        Text("• Get personalized activity recommendations")
                        Text("• Quick access to create your own events")
                    }
                    .font(ClubRalleyTheme.Typography.body)
                    .foregroundColor(ClubRalleyTheme.Colors.secondaryText)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding()
                .background(ClubRalleyTheme.Colors.sageGreen)
                .cornerRadius(ClubRalleyTheme.CornerRadius.medium)
                
                // Network section
                VStack(alignment: .leading, spacing: ClubRalleyTheme.Spacing.md) {
                    Text("Your Athletic Network")
                        .font(ClubRalleyTheme.Typography.headline)
                        .foregroundColor(ClubRalleyTheme.Colors.text)
                    
                    Text("Club Ralley is designed for former athletes navigating post-grad life. Connect with people who understand your athletic identity and love staying active.")
                        .font(ClubRalleyTheme.Typography.body)
                        .foregroundColor(ClubRalleyTheme.Colors.secondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: ClubRalleyTheme.CornerRadius.medium)
                        .fill(ClubRalleyTheme.Colors.background)
                        .clubRalleyShadow(ClubRalleyTheme.Shadows.light)
                )
            }
            .padding(ClubRalleyTheme.Spacing.md)
        }
        .navigationTitle("Home")
        .navigationBarTitleDisplayMode(.large)
    }
}

struct LeagueFinderView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("🔍 League Finder")
                    .font(ClubRalleyTheme.Typography.largeTitle)
                    .foregroundColor(ClubRalleyTheme.Colors.text)
                
                Text("Discover leagues and activities near you")
                    .font(ClubRalleyTheme.Typography.title3)
                    .foregroundColor(ClubRalleyTheme.Colors.secondaryText)
                
                VStack(alignment: .leading, spacing: 10) {
                    Text("Coming soon:")
                        .font(ClubRalleyTheme.Typography.headline)
                        .foregroundColor(ClubRalleyTheme.Colors.text)
                    
                    Text("• Search for leagues by sport and location")
                    Text("• Filter by skill level and availability")
                    Text("• Join existing leagues or create new ones")
                    Text("• Map view of nearby activities")
                    Text("• League recommendations based on your profile")
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(ClubRalleyTheme.Colors.sageGreen)
                .cornerRadius(ClubRalleyTheme.CornerRadius.medium)
            }
            .padding()
        }
        .navigationTitle("League Finder")
        .navigationBarTitleDisplayMode(.large)
    }
}

struct PostView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("📸 Post")
                    .font(ClubRalleyTheme.Typography.largeTitle)
                    .foregroundColor(ClubRalleyTheme.Colors.text)
                
                Text("Share your athletic journey")
                    .font(ClubRalleyTheme.Typography.title3)
                    .foregroundColor(ClubRalleyTheme.Colors.secondaryText)
                
                VStack(alignment: .leading, spacing: 10) {
                    Text("Coming soon:")
                        .font(ClubRalleyTheme.Typography.headline)
                        .foregroundColor(ClubRalleyTheme.Colors.text)
                    
                    Text("• Share photos and videos from your activities")
                    Text("• Create posts about your athletic achievements")
                    Text("• Tag friends and teammates")
                    Text("• Add location and sport tags")
                    Text("• Story-style posts for daily updates")
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(ClubRalleyTheme.Colors.sageGreen)
                .cornerRadius(ClubRalleyTheme.CornerRadius.medium)
            }
            .padding()
        }
        .navigationTitle("Post")
        .navigationBarTitleDisplayMode(.large)
    }
}

struct TeamsView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("👥 Teams")
                    .font(ClubRalleyTheme.Typography.largeTitle)
                    .foregroundColor(ClubRalleyTheme.Colors.text)
                
                Text("Connect with your teams and teammates")
                    .font(ClubRalleyTheme.Typography.title3)
                    .foregroundColor(ClubRalleyTheme.Colors.secondaryText)
                
                VStack(alignment: .leading, spacing: 10) {
                    Text("Coming soon:")
                        .font(ClubRalleyTheme.Typography.headline)
                        .foregroundColor(ClubRalleyTheme.Colors.text)
                    
                    Text("• View and manage your team memberships")
                    Text("• Connect with current and former teammates")
                    Text("• Team chat and communication")
                    Text("• Schedule team activities and practices")
                    Text("• Team achievements and stats tracking")
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(ClubRalleyTheme.Colors.sageGreen)
                .cornerRadius(ClubRalleyTheme.CornerRadius.medium)
            }
            .padding()
        }
        .navigationTitle("Teams")
        .navigationBarTitleDisplayMode(.large)
    }
}

// ProfileView is now implemented in Views/Profile/ProfileView.swift
// This placeholder has been removed to prevent shadowing

struct CreateRalleyView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("➕ Create Ralley")
                    .font(.largeTitle.bold())
                
                Text("Organize your next activity")
                    .font(.title2)
                    .foregroundColor(.secondary)
                
                VStack(alignment: .leading, spacing: 10) {
                    Text("Coming soon:")
                        .font(.headline)
                    
                    Text("• Title and description")
                    Text("• Location picker with map")
                    Text("• Date and time selection")
                    Text("• Sport/activity category")
                    Text("• Participant limits")
                    Text("• Invite friends")
                    Text("• Privacy settings")
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(Color.mint.opacity(0.1))
                .cornerRadius(12)
                
                Button("Close") {
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
        }
        .navigationTitle("Create Ralley")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Cancel") {
                    dismiss()
                }
            }
        }
    }
}

// MARK: - Preview
struct ClubRalleyMainView_Previews: PreviewProvider {
    static var previews: some View {
        ClubRalleyMainView()
    }
}