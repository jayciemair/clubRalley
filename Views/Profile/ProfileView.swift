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
                        ProfileCenteredHeader(profile: profile)
                            .padding(.top, 16)
                        ProfileStatsRow(profile: profile)
                            .padding(.top, 20)
                        ProfileBioSection(profile: profile)
                            .padding(.top, 16)
                        SportCarouselSection(viewModel: viewModel)
                            .padding(.top, 24)
                        RalleyHistorySection(viewModel: viewModel)
                        if !profile.photos.isEmpty {
                            ProfilePhotosSection(photos: profile.photos)
                                .padding(.horizontal, 24)
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
            .background(Color(hex: "#F5F2EB"))
            .refreshable {
                await viewModel.loadCurrentUserProfile()
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingSettings = true }) {
                        Image(systemName: "gearshape.fill")
                            .foregroundColor(Color(hex: "#2D4A3E"))
                    }
                }
            }
            .sheet(isPresented: $showingSettings) {
                ProfileSettingsView()
            }
        }
        .task {
            await viewModel.loadCurrentUserProfile()
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
