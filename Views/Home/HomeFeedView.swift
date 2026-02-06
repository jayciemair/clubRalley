//
//  HomeFeedView.swift
//  Club Ralley
//
//  Home feed view with posts, upcoming ralleys, and notifications.
//

import SwiftUI

// MARK: - Home Feed View

struct HomeFeedView: View {
    @EnvironmentObject var postManager: PostManager
    @EnvironmentObject var ralleyManager: RalleyManager
    @StateObject private var messagingService = MessagingService()
    @State private var showingNotifications = false
    @State private var showingMessages = false

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 0) {
                    // Header with notifications and messages
                    FeedHeader(
                        showingNotifications: $showingNotifications,
                        showingMessages: $showingMessages,
                        unreadMessageCount: messagingService.totalUnreadCount
                    )

                    // Upcoming joined ralleys section
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
                            Task {
                                await postManager.refreshPosts()
                            }
                        }
                    } else {
                        ForEach(postManager.posts) { post in
                            FigmaPostCard(post: post)
                                .environmentObject(postManager)
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
            .background(Color.white)
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
}
