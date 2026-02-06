//
//  RosterView.swift
//  Club Ralley
//
//  Roster view displaying users with search and follow functionality
//

import SwiftUI

struct RosterView: View {
    @StateObject private var userService = UserService()
    @StateObject private var messagingService = MessagingService()
    @State private var searchText = ""
    @State private var showingMessages = false
    @State private var selectedUser: RosterUserData?

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Header
                    Text("Discover Athletes")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(Color(hex: "#2C4F40"))
                        .padding(.horizontal, 20)
                        .padding(.top, 16)

                    // Search bar
                    HStack(spacing: 12) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 16))
                            .foregroundColor(.gray)

                        TextField("Search by name or username...", text: $searchText)
                            .font(.system(size: 16))
                            .onSubmit {
                                Task {
                                    await userService.searchUsers(query: searchText)
                                }
                            }

                        if !searchText.isEmpty {
                            Button(action: {
                                searchText = ""
                                Task {
                                    await userService.loadUsers()
                                }
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 16))
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                    .padding(12)
                    .background(Color.white)
                    .cornerRadius(12)
                    .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
                    .padding(.horizontal, 20)

                    // Content
                    if userService.isLoading && userService.users.isEmpty {
                        loadingView
                    } else if userService.users.isEmpty {
                        emptyView
                    } else {
                        LazyVGrid(columns: columns, spacing: 12) {
                            ForEach(userService.users) { user in
                                RosterUserCardReal(
                                    user: user,
                                    onFollow: {
                                        Task {
                                            _ = await userService.toggleFollow(userId: user.id)
                                        }
                                    },
                                    onMessage: {
                                        selectedUser = user
                                        showingMessages = true
                                    }
                                )
                            }
                        }
                        .padding(.horizontal, 16)
                    }

                    Spacer(minLength: 100)
                }
            }
            .background(Color(hex: "#F5F5F5"))
            .navigationBarHidden(true)
            .refreshable {
                if searchText.isEmpty {
                    await userService.loadUsers()
                } else {
                    await userService.searchUsers(query: searchText)
                }
                await userService.loadFollowingStatus()
            }
            .sheet(isPresented: $showingMessages) {
                if let user = selectedUser {
                    NavigationStack {
                        DirectMessageView(
                            conversation: createConversation(from: user),
                            messagingService: messagingService
                        )
                        .toolbar {
                            ToolbarItem(placement: .navigationBarLeading) {
                                Button("Close") {
                                    showingMessages = false
                                }
                                .foregroundColor(Color(hex: "#2C4F40"))
                            }
                        }
                    }
                }
            }
        }
        .task {
            await userService.loadUsers()
            await userService.loadFollowingStatus()
        }
        .onChange(of: searchText) { _, newValue in
            // Debounced search
            Task {
                try? await Task.sleep(nanoseconds: 300_000_000) // 300ms delay
                if searchText == newValue { // Only search if text hasn't changed
                    await userService.searchUsers(query: newValue)
                }
            }
        }
    }

    private var loadingView: some View {
        VStack(spacing: 16) {
            Spacer(minLength: 60)
            ProgressView()
                .scaleEffect(1.5)
            Text("Loading athletes...")
                .font(.system(size: 16))
                .foregroundColor(.gray)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    private var emptyView: some View {
        VStack(spacing: 16) {
            Spacer(minLength: 60)

            Image(systemName: "person.3")
                .font(.system(size: 50))
                .foregroundColor(Color(hex: "#2C4F40").opacity(0.5))

            Text(searchText.isEmpty ? "No athletes found" : "No results for \"\(searchText)\"")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.black)

            Text(searchText.isEmpty ? "Be the first to invite your friends!" : "Try a different search term")
                .font(.system(size: 14))
                .foregroundColor(.gray)

            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    private func createConversation(from user: RosterUserData) -> DirectConversation {
        DirectConversation(
            id: user.id,
            otherUserId: user.id,
            otherUserName: user.name,
            otherUserUsername: user.username,
            otherUserPhotoURL: user.photoURL,
            isVerified: user.isVerified,
            lastMessage: nil,
            lastMessageAt: nil,
            unreadCount: 0,
            createdAt: Date()
        )
    }
}

// MARK: - Roster User Card (Real Data)

struct RosterUserCardReal: View {
    let user: RosterUserData
    let onFollow: () -> Void
    let onMessage: () -> Void

    var body: some View {
        NavigationLink(destination: UserProfileView(userId: user.id)) {
            VStack(spacing: 8) {
                // Profile Photo
                ZStack(alignment: .bottomTrailing) {
                    AsyncImage(url: URL(string: user.photoURL)) { image in
                        image.resizable().aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Circle().fill(Color(hex: "#2C4F40").opacity(0.2))
                    }
                    .frame(width: 56, height: 56)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color.white, lineWidth: 2))
                    .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)

                    if user.isVerified {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 14))
                            .foregroundColor(Color(hex: "#2C4F40"))
                            .background(Circle().fill(.white).frame(width: 16, height: 16))
                    }
                }

                Text(user.name)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.black)
                    .lineLimit(1)

                Text("@\(user.username)")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.gray)
                    .lineLimit(1)

                if user.mutuals > 0 {
                    Text("\(user.mutuals) mutual\(user.mutuals == 1 ? "" : "s")")
                        .font(.system(size: 11, weight: .regular))
                        .foregroundColor(.gray)
                }

                Spacer(minLength: 4)

                HStack(spacing: 8) {
                    Button(action: onFollow) {
                        Text(user.isFollowing ? "Following" : "Follow")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(user.isFollowing ? .white : Color(hex: "#2C4F40"))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(user.isFollowing ? Color(hex: "#2C4F40") : Color.white)
                            .cornerRadius(6)
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(Color(hex: "#2C4F40"), lineWidth: 1)
                            )
                    }

                    Button(action: onMessage) {
                        Image(systemName: "message")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(Color(hex: "#2C4F40"))
                            .frame(width: 32, height: 32)
                            .background(Color.white)
                            .cornerRadius(6)
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(Color(hex: "#2C4F40"), lineWidth: 1)
                            )
                    }
                }
            }
            .padding(12)
            .background(Color.white)
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    RosterView()
}
