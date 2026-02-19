//
//  HomeFeedView.swift
//  Club Ralley
//
//  Home feed with personalized greeting, trending ralleys, and posts.
//

import SwiftUI

// MARK: - Home Feed View

struct HomeFeedView: View {
    @EnvironmentObject var postManager: PostManager
    @EnvironmentObject var ralleyManager: RalleyManager
    private var messagingService: MessagingService { ServiceContainer.shared.messagingService }
    @State private var showingNotifications = false
    @State private var showingMessages = false
    @State private var searchText = ""

    private var userFirstName: String {
        if let saved = SavedUserProfile.loadFromStorage() {
            return saved.firstName
        }
        return "there"
    }

    private var trendingRalleys: [ClubRalley] {
        ralleyManager.ralleys
            .filter { !$0.isPast && !$0.isFull }
            .sorted { $0.currentPlayers > $1.currentPlayers }
            .prefix(6)
            .map { $0 }
    }

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                FeedHeader(
                    userName: userFirstName,
                    searchText: $searchText,
                    showingNotifications: $showingNotifications,
                    showingMessages: $showingMessages,
                    unreadMessageCount: messagingService.totalUnreadCount
                )

                // Trending ralleys
                if !trendingRalleys.isEmpty {
                    TrendingRalleysSection(ralleys: trendingRalleys)
                        .environmentObject(ralleyManager)
                }

                // Upcoming joined ralleys
                let joinedRalleys = ralleyManager.getJoinedUpcomingRalleys()
                if !joinedRalleys.isEmpty {
                    UpcomingRalleysSection(ralleys: joinedRalleys)
                        .environmentObject(ralleyManager)
                }

                // Feed content
                if postManager.isLoading && postManager.posts.isEmpty {
                    FeedLoadingView()
                } else if let error = postManager.error, postManager.posts.isEmpty {
                    FeedErrorView(error: error) {
                        Task { await postManager.refreshPosts() }
                    }
                } else {
                    ForEach(Array(postManager.posts.enumerated()), id: \.element.id) { index, post in
                        FigmaPostCard(post: post)
                            .environmentObject(postManager)
                            .onAppear {
                                if index == postManager.posts.count - 3 {
                                    Task { await postManager.loadMorePosts() }
                                }
                            }
                    }

                    if postManager.isLoadingMore {
                        HStack {
                            Spacer()
                            ProgressView().padding()
                            Spacer()
                        }
                    }

                    if postManager.posts.isEmpty {
                        EmptyFeedView()
                    }
                }

                Spacer(minLength: 100)
            }
        }
        .refreshable {
            await postManager.refreshPosts()
            await ralleyManager.refreshRalleys()
            await messagingService.loadConversations()
        }
        .background(ClubRalleyTheme.Colors.sageBackground)
        .navigationBarHidden(true)
        .sheet(isPresented: $showingNotifications) {
            SimpleNotificationsView()
        }
        .sheet(isPresented: $showingMessages) {
            MessagesView()
        }
        .task {
            await messagingService.loadConversations()
        }
    }
}
