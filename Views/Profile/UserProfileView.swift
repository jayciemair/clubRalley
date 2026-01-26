//
//  UserProfileView.swift
//  Club Ralley
//
//  View for displaying other users' profiles
//

import SwiftUI

struct UserProfileView: View {
    let userId: UUID
    @StateObject private var viewModel = ProfileViewModel()
    @State private var userProfile: UserProfile?
    @State private var isLoading = true
    
    var body: some View {
        NavigationStack {
            ScrollView {
                if let profile = userProfile {
                    ProfileContentView(userProfile: profile)
                        .environmentObject(viewModel)
                } else if isLoading {
                    ProfileLoadingView()
                } else {
                    ProfileErrorView {
                        Task {
                            await loadProfile()
                        }
                    }
                }
            }
            .refreshable {
                await loadProfile()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button(action: {
                            // Share profile
                        }) {
                            Label("Share Profile", systemImage: "square.and.arrow.up")
                        }
                        
                        Button(role: .destructive, action: {
                            Task {
                                await viewModel.blockUser(userId)
                            }
                        }) {
                            Label("Block User", systemImage: "hand.raised")
                        }
                        
                        Button(role: .destructive, action: {
                            // Report user
                        }) {
                            Label("Report", systemImage: "exclamationmark.triangle")
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                            .foregroundColor(ClubRalleyTheme.Colors.accent)
                    }
                }
            }
        }
        .task {
            await loadProfile()
        }
    }
    
    private func loadProfile() async {
        isLoading = true
        userProfile = await viewModel.loadUserProfile(userId)
        isLoading = false
    }
}

struct ProfileErrorView: View {
    let onRetry: () -> Void
    
    var body: some View {
        VStack(spacing: ClubRalleyTheme.Spacing.lg) {
            Image(systemName: "person.crop.circle.badge.exclamationmark")
                .font(.system(size: 60))
                .foregroundColor(ClubRalleyTheme.Colors.secondaryText)
            
            Text("Unable to load profile")
                .font(ClubRalleyTheme.Typography.headline)
                .foregroundColor(ClubRalleyTheme.Colors.text)
            
            Text("Please check your connection and try again")
                .font(ClubRalleyTheme.Typography.body)
                .foregroundColor(ClubRalleyTheme.Colors.secondaryText)
                .multilineTextAlignment(.center)
            
            Button("Try Again") {
                onRetry()
            }
            .clubRalleyButtonStyle(.primary)
        }
        .padding(ClubRalleyTheme.Spacing.xl)
    }
}

// MARK: - Preview

struct UserProfileView_Previews: PreviewProvider {
    static var previews: some View {
        UserProfileView(userId: UUID())
    }
}