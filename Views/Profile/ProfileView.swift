//
//  ProfileView.swift
//  Club Ralley
//
//  Standalone profile view (used in navigation contexts outside the tab bar)
//

import SwiftUI

struct ProfileView: View {
    @StateObject private var viewModel = ProfileViewModel()
    @State private var showingSettings = false

    var body: some View {
        NavigationStack {
            ScrollView {
                if let profile = viewModel.currentUserProfile {
                    VStack(spacing: 0) {
                        // Custom top bar
                        ProfileCustomTopBar(
                            location: profile.user.locationDisplay,
                            showingSettings: $showingSettings
                        )

                        // Centered header
                        ProfileHeaderRow(profile: profile)

                        // Bio
                        ProfileBioSection(profile: profile)
                            .padding(.bottom, 14)

                        // Mutual friends
                        if !profile.mutualFriends.isEmpty {
                            ProfileFriendsRow(mutualFriends: profile.mutualFriends)
                                .padding(.bottom, 16)
                        }

                        ProfileDivider()
                            .padding(.top, 16)

                        SportCarouselSection(viewModel: viewModel)
                            .padding(.top, 16)
                        RalleyHistorySection(viewModel: viewModel)
                        if !profile.photos.isEmpty {
                            ProfilePhotosSection(photos: profile.photos)
                                .padding(.horizontal, 22)
                                .padding(.bottom, 24)
                        }
                        Spacer(minLength: 100)
                    }
                } else if viewModel.isLoading {
                    ProfileTabLoadingView()
                } else {
                    ProfileErrorView {
                        Task { await viewModel.loadCurrentUserProfile() }
                    }
                }
            }
            .background(Color(hex: "#f6f5f1"))
            .refreshable {
                await viewModel.loadCurrentUserProfile()
            }
            .navigationBarHidden(true)
        }
        .task {
            await viewModel.loadCurrentUserProfile()
        }
        .sheet(isPresented: $showingSettings) {
            ProfileSettingsView()
        }
    }
}

// MARK: - Shimmer Effect

struct ShimmerEffect: ViewModifier {
    @State private var phase: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .overlay(
                LinearGradient(
                    colors: [
                        Color.white.opacity(0),
                        Color.white.opacity(0.3),
                        Color.white.opacity(0)
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .offset(x: phase)
                .mask(content)
            )
            .onAppear {
                withAnimation(
                    Animation.linear(duration: 1.5)
                        .repeatForever(autoreverses: false)
                ) {
                    phase = 300
                }
            }
    }
}

extension View {
    func shimmer() -> some View {
        modifier(ShimmerEffect())
    }
}

// MARK: - Preview

struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileView()
    }
}
