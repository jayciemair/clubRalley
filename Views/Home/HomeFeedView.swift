//
//  HomeFeedView.swift
//  Club Ralley
//
//  Home feed — top bar, upcoming ralleys, posts feed with sample data
//

import SwiftUI

// MARK: - Home Feed View

struct HomeFeedView: View {
    @EnvironmentObject var postManager: PostManager
    @EnvironmentObject var ralleyManager: RalleyManager
    @State private var showingNotifications = false
    @State private var showingMessages = false

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Top bar
                HomeTopBar(
                    showingNotifications: $showingNotifications,
                    showingMessages: $showingMessages
                )

                // Upcoming ralleys
                HomeUpcomingSection()

                // Feed separator
                FeedSeparator()

                // Posts feed
                LazyVStack(spacing: 0) {
                    ForEach(HomeSampleData.posts) { post in
                        HomeFeedPostCard(post: post)
                        FeedSeparator()
                    }
                }

                Spacer(minLength: 100)
            }
        }
        .background(Color(hex: "#F6F5F1"))
        .navigationBarHidden(true)
        .sheet(isPresented: $showingNotifications) {
            SimpleNotificationsView()
        }
        .sheet(isPresented: $showingMessages) {
            MessagesView()
        }
        .refreshable {
            await postManager.refreshPosts()
            await ralleyManager.refreshRalleys()
        }
    }
}

// MARK: - Sample Data Models

struct SampleFeedPost: Identifiable {
    let id = UUID()
    let authorName: String
    let initials: String
    let time: String
    let location: String
    let title: String?
    let body: String?
    let photoURLs: [String]
    let showMutuals: Bool
}

struct SampleUpcomingRalley: Identifiable {
    let id = UUID()
    let sport: String
    let title: String
    let dateString: String
    let location: String
    let currentPlayers: Int
    let maxPlayers: Int
    let timeUntil: String
}

// MARK: - Sample Data

enum HomeSampleData {
    static let upcomingRalleys: [SampleUpcomingRalley] = [
        SampleUpcomingRalley(
            sport: "Pickleball",
            title: "Pickleball at Bucknell Turf",
            dateString: "Thu Feb 19 at 6:45 PM",
            location: "Bucknell Turf Fields",
            currentPlayers: 1,
            maxPlayers: 4,
            timeUntil: "in 11m"
        ),
        SampleUpcomingRalley(
            sport: "Soccer",
            title: "Sunday Pickup Soccer",
            dateString: "Sun Feb 22 at 10:00 AM",
            location: "Millennium Park",
            currentPlayers: 3,
            maxPlayers: 10,
            timeUntil: "in 3d"
        )
    ]

    static let posts: [SampleFeedPost] = [
        SampleFeedPost(
            authorName: "Gracie King",
            initials: "GK",
            time: "Today",
            location: "Chicago, IL",
            title: "Tennis Club Event",
            body: "Just played my first game at Club Ralley sponsored rec-league Chicago sports!",
            photoURLs: [
                "https://picsum.photos/400/400?random=101",
                "https://picsum.photos/400/400?random=102",
                "https://picsum.photos/400/400?random=103",
                "https://picsum.photos/400/400?random=104",
                "https://picsum.photos/400/400?random=105"
            ],
            showMutuals: true
        ),
        SampleFeedPost(
            authorName: "Ryan Smith",
            initials: "RS",
            time: "Today",
            location: "Chicago, IL",
            title: "Tennis Match",
            body: "I need a hitting partner for tomorrow afternoon. Send help!",
            photoURLs: [],
            showMutuals: true
        )
    ]
}
