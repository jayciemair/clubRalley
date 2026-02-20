//
//  ContentView.swift
//  Club Ralley
//
//  Main app root view for Club Ralley social platform
//  Manages app state transitions and navigation
//

import SwiftUI
import CoreData

// Note: RosterUserData and UserService are defined in Services/UserService.swift

// MARK: - Content View

struct ContentView: View {
    // MARK: - Environment and Storage Properties
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject var onboardingFlowController: OnboardingFlowController

    // MARK: - App Storage for Persistent State
    @AppStorage("selectedTab") var selectedTab: MainTab = .home

    // MARK: - Coordinator (ViewModel)
    @StateObject private var coordinator = AppCoordinator()
    @StateObject private var postManager = PostManager()
    @StateObject private var ralleyManager = RalleyManager()

    // MARK: - Welcome Celebration State
    @State private var showWelcomeConfetti = false

    // MARK: - Bindings for External Navigation
    @Binding var selectedTabOverride: MainTab

    init(selectedTab: Binding<MainTab> = .constant(.home)) {
        self._selectedTabOverride = selectedTab
    }

    var body: some View {
        mainTabView
            .navigationViewStyle(.stack)
            .withErrorHandling()
            .overlay(welcomeOverlay)
            .onAppear { coordinator.onAppAppear() }
            .onChange(of: coordinator.appState) { _, newState in handleAppStateChange(newState) }
            .onChange(of: selectedTabOverride) { _, newValue in handleTabOverrideChange(newValue) }
    }

    // MARK: - Main Tab View

    private var mainTabView: some View {
        ZStack(alignment: .bottom) {
            Group {
                switch selectedTab {
                case .home:
                    NavigationStack {
                        HomeFeedView()
                            .environmentObject(postManager)
                            .environmentObject(ralleyManager)
                    }
                case .ralleys:
                    NavigationStack {
                        FindRalleysView()
                            .environmentObject(ralleyManager)
                            .environmentObject(postManager)
                    }
                case .post:
                    PostCreationInterfaceView()
                        .environmentObject(postManager)
                case .teams:
                    NavigationStack {
                        RosterView()
                    }
                case .profile:
                    NavigationStack {
                        ProfileTabView()
                    }
                }
            }
            .transition(.opacity.animation(.easeInOut(duration: 0.15)))
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            if selectedTab != .post {
                ClubRalleyTabBar(selectedTab: $selectedTab)
            }
        }
        .ignoresSafeArea(.keyboard)
    }

    // MARK: - Welcome Overlay

    @ViewBuilder
    private var welcomeOverlay: some View {
        if showWelcomeConfetti {
            WelcomeCelebrationView(isShowing: $showWelcomeConfetti)
                .ignoresSafeArea(.all)
        }
    }

    // MARK: - State Handlers

    private func handleAppStateChange(_ newState: AppState) {
        print("[Club Ralley] App state changed to: \(newState)")
        if case .ready(_, showSuccessHUD: true) = newState {
            showWelcomeConfetti = true
            coordinator.clearSuccessHUD()
        }
        if case .ready(let tab, _) = newState {
            selectedTab = tab
        }
    }

    private func handleTabOverrideChange(_ newValue: MainTab) {
        selectedTab = newValue
        coordinator.updateSelectedTab(newValue)
    }
}

// MARK: - Roster Tab Selector

enum RosterTab: String, CaseIterable {
    case people = "People"
    case chats = "Chats"
}

// MARK: - Roster View

struct RosterView: View {
    @StateObject private var userService = UserService()
    private var messagingService: MessagingService { ServiceContainer.shared.messagingService }
    @State private var searchText = ""
    @State private var selectedRosterTab: RosterTab = .people
    @State private var messageTargetUser: RosterUserData?
    @State private var activeConversation: DirectConversation?
    @State private var isLoadingMessage = false
    private let columns = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]

    var body: some View {
        VStack(spacing: 0) {
                // Header with tab picker
                VStack(spacing: 16) {
                    HStack {
                        Text("Roster")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(Color(hex: "#2C4F40"))
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)

                    // Tab picker
                    HStack(spacing: 0) {
                        ForEach(RosterTab.allCases, id: \.self) { tab in
                            Button(action: { withAnimation(.easeInOut(duration: 0.2)) { selectedRosterTab = tab } }) {
                                VStack(spacing: 8) {
                                    Text(tab.rawValue)
                                        .font(.system(size: 16, weight: selectedRosterTab == tab ? .semibold : .medium))
                                        .foregroundColor(selectedRosterTab == tab ? Color(hex: "#2C4F40") : .gray)

                                    Rectangle()
                                        .fill(selectedRosterTab == tab ? Color(hex: "#2C4F40") : Color.clear)
                                        .frame(height: 3)
                                        .cornerRadius(1.5)
                                }
                            }
                            .frame(maxWidth: .infinity)
                        }
                    }
                    .padding(.horizontal, 16)
                }
                .background(Color.white)

                // Content based on selected tab
                if selectedRosterTab == .people {
                    peopleContent
                } else {
                    ChatsListView()
                }
            }
            .background(Color(hex: "#F5F5F5"))
        .task { await userService.loadUsers(); await userService.loadFollowingStatus() }
        .sheet(item: $activeConversation) { conversation in
            NavigationStack {
                DirectMessageView(conversation: conversation, messagingService: messagingService)
            }
        }
    }

    // MARK: - People Content

    private var peopleContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Search bar
                HStack {
                    Image(systemName: "magnifyingglass").foregroundColor(.gray)
                    TextField("Search athletes...", text: $searchText)
                        .textFieldStyle(PlainTextFieldStyle())
                        .onChange(of: searchText) { _, query in
                            Task { await userService.searchUsers(query: query) }
                        }
                    if !searchText.isEmpty {
                        Button(action: { searchText = ""; Task { await userService.loadUsers() } }) {
                            Image(systemName: "xmark.circle.fill").foregroundColor(.gray)
                        }
                    }
                }
                .padding(12).background(Color.white).cornerRadius(12)
                .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
                .padding(.horizontal, 16)
                .padding(.top, 16)

                if userService.isLoading {
                    RosterSkeletonView()
                } else if userService.users.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "person.3").font(.system(size: 48)).foregroundColor(Color(hex: "#2C4F40").opacity(0.5))
                        Text("No athletes found").font(.system(size: 18, weight: .semibold))
                        Text("Try a different search").font(.system(size: 15)).foregroundColor(.gray)
                    }.frame(maxWidth: .infinity).padding(.top, 60)
                } else {
                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(userService.users) { user in
                            RosterUserCardView(
                                user: user,
                                userService: userService,
                                isLoadingMessage: isLoadingMessage && messageTargetUser?.id == user.id,
                                onMessageTapped: { openDirectMessage(for: user) }
                            )
                        }
                    }.padding(.horizontal, 16)
                }
                Spacer(minLength: 100)
            }
        }
    }

    // MARK: - Messaging

    private func openDirectMessage(for user: RosterUserData) {
        guard !isLoadingMessage else { return }
        messageTargetUser = user
        isLoadingMessage = true
        Task {
            do {
                let conversation = try await messagingService.getOrCreateConversation(with: user.id)
                activeConversation = conversation
            } catch {
                print("Failed to open conversation: \(error)")
            }
            isLoadingMessage = false
            messageTargetUser = nil
        }
    }
}

// MARK: - Roster User Card View

struct RosterUserCardView: View {
    let user: RosterUserData
    @ObservedObject var userService: UserService
    let isLoadingMessage: Bool
    let onMessageTapped: () -> Void

    var body: some View {
        VStack(spacing: 8) {
            // Profile photo
            ZStack(alignment: .bottomTrailing) {
                AsyncImage(url: URL(string: user.photoURL)) { image in
                    image.resizable().aspectRatio(contentMode: .fill)
                } placeholder: { Circle().fill(Color(hex: "#2C4F40").opacity(0.2)) }
                .frame(width: 56, height: 56).clipShape(Circle())
                .overlay(Circle().stroke(Color.white, lineWidth: 2))
                .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)

                if user.isVerified {
                    Image(systemName: "checkmark.seal.fill").font(.system(size: 14))
                        .foregroundColor(Color(hex: "#2C4F40")).background(Circle().fill(.white).frame(width: 16, height: 16))
                }
            }

            // Name
            Text(user.name).font(.system(size: 13, weight: .bold)).foregroundColor(.black).lineLimit(1)

            Text(user.location).font(.system(size: 11, weight: .medium)).foregroundColor(.gray).lineLimit(1)
            Text("\(user.mutuals) mutuals").font(.system(size: 11)).foregroundColor(.gray)
            Spacer(minLength: 4)

            HStack(spacing: 8) {
                Button(action: { Task { await userService.toggleFollow(userId: user.id) } }) {
                    Text(user.isFollowing ? "Following" : "Follow")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(user.isFollowing ? .white : Color(hex: "#2C4F40"))
                        .frame(maxWidth: .infinity).padding(.vertical, 8)
                        .background(user.isFollowing ? Color(hex: "#2C4F40") : Color.white)
                        .cornerRadius(6).overlay(RoundedRectangle(cornerRadius: 6).stroke(Color(hex: "#2C4F40"), lineWidth: 1))
                }

                Button(action: onMessageTapped) {
                    ZStack {
                        if isLoadingMessage {
                            ProgressView()
                                .scaleEffect(0.6)
                        } else {
                            Image(systemName: "message").font(.system(size: 12, weight: .medium))
                        }
                    }
                    .foregroundColor(Color(hex: "#2C4F40")).frame(width: 32, height: 32)
                    .background(Color.white).cornerRadius(6)
                    .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color(hex: "#2C4F40"), lineWidth: 1))
                }
                .disabled(isLoadingMessage)
            }
        }
        .padding(12).background(Color.white).cornerRadius(12)
        .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 2)
    }
}

// MARK: - Roster Skeleton View

private struct RosterSkeletonView: View {
    @State private var isAnimating = false
    private let columns = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 12) {
            ForEach(0..<6, id: \.self) { _ in
                VStack(spacing: 8) {
                    Circle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(width: 56, height: 56)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.2))
                        .frame(width: 60, height: 10)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.2))
                        .frame(width: 44, height: 8)

                    Spacer(minLength: 4)

                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 32)
                }
                .padding(12)
                .background(Color.white)
                .cornerRadius(12)
                .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 2)
            }
        }
        .padding(.horizontal, 16)
        .opacity(isAnimating ? 1.0 : 0.6)
        .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: isAnimating)
        .onAppear { isAnimating = true }
    }
}

// MARK: - Preview

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
            .environmentObject(OnboardingFlowController())
    }
}
