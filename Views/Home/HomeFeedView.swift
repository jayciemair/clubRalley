//
//  HomeFeedView.swift
//  Club Ralley
//
//  Home feed — top bar, upcoming ralleys, posts feed
//

import SwiftUI

// MARK: - Home Feed View

struct HomeFeedView: View {
    @EnvironmentObject var postManager: PostManager
    @EnvironmentObject var ralleyManager: RalleyManager
    @State private var showingNotifications = false

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Top bar
                HomeTopBar(
                    showingNotifications: $showingNotifications
                )

                // Upcoming ralleys
                HomeUpcomingSection()

                // Feed separator
                FeedSeparator()

                // Posts feed
                if postManager.isLoading && postManager.posts.isEmpty {
                    FeedLoadingView()
                } else if postManager.posts.isEmpty {
                    EmptyFeedView()
                } else {
                    LazyVStack(spacing: 0) {
                        ForEach(postManager.posts) { post in
                            NavigationLink(destination: PostDetailView(post: post).environmentObject(postManager)) {
                                HomeFeedPostCard(post: post)
                                    .contentShape(Rectangle())
                            }
                            .buttonStyle(PlainButtonStyle())
                            FeedSeparator()
                        }
                    }
                }

                Spacer(minLength: 100)
            }
        }
        .background(ClubRalleyTheme.Colors.warmBackground)
        .navigationBarHidden(true)
        .sheet(isPresented: $showingNotifications) {
            SimpleNotificationsView()
        }
        .refreshable {
            await postManager.refreshPosts()
            await ralleyManager.refreshRalleys()
        }
    }
}
