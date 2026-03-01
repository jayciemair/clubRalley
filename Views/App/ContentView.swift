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
    @StateObject private var chatsListViewModel = ChatsListViewModel()

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
            .onAppear {
                coordinator.onAppAppear()
                ralleyManager.postManager = postManager
            }
            .onChange(of: coordinator.appState) { _, newState in handleAppStateChange(newState) }
            .onChange(of: selectedTabOverride) { _, newValue in handleTabOverrideChange(newValue) }
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("ProfileDidSwitch"))) { _ in
                handleUserSwitch()
            }
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("UserDidLogout"))) { _ in
                handleUserLogout()
            }
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("RecapPostCreated"))) { _ in
                selectedTab = .home
            }
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
                            .environmentObject(chatsListViewModel)
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
                ClubRalleyTabBar(selectedTab: $selectedTab, unreadChatCount: chatsListViewModel.unreadCount)
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

    /// Reset all ViewModels and reload for the new user after a profile switch
    private func handleUserSwitch() {
        postManager.reset()
        ralleyManager.reset()
        chatsListViewModel.reset()
        selectedTab = .home

        // Reload data for the new user
        Task {
            await postManager.loadPosts()
            await ralleyManager.loadRalleys()
            chatsListViewModel.reinitialize()
        }
    }

    /// Clear all state on logout
    private func handleUserLogout() {
        postManager.reset()
        ralleyManager.reset()
        chatsListViewModel.reset()
        selectedTab = .home
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
    @StateObject private var contactsManager = ContactsManager()
    private var messagingService: MessagingService { ServiceContainer.shared.messagingService }
    @State private var searchText = ""
    @State private var selectedRosterTab: RosterTab = .people
    @State private var messageTargetUser: RosterUserData?
    @State private var activeConversation: DirectConversation?
    @State private var isLoadingMessage = false
    @State private var selectedSportFilter: String?
    private let columns = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]
    private let sportFilterOptions: [String] = Array(DefaultSports.all.prefix(8).map { $0.name })

    var body: some View {
        VStack(spacing: 0) {
                // Header with tab picker
                VStack(spacing: 16) {
                    HStack {
                        Text("Roster")
                            .font(.custom("Chillax-Bold", size: 26))
                            .foregroundColor(ClubRalleyTheme.Colors.darkGreen)
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
                                        .foregroundColor(selectedRosterTab == tab ? ClubRalleyTheme.Colors.darkGreen : .gray)

                                    Rectangle()
                                        .fill(selectedRosterTab == tab ? ClubRalleyTheme.Colors.darkGreen : Color.clear)
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
            .background(ClubRalleyTheme.Colors.warmBackground)
        .task {
            await userService.loadUsers()
            await userService.loadFollowingStatus()
            await contactsManager.fetchContactMatches()
            await userService.loadSchoolSuggestions()

            // Load discovery data if user has college athlete info
            if let athleteInfo = SavedUserProfile.loadFromStorage()?.collegeAthleteInfo {
                if !athleteInfo.school.isEmpty {
                    await userService.loadSchoolUsers()
                }
                if !athleteInfo.sport.isEmpty {
                    await userService.loadSportSuggestions()
                }
                if !athleteInfo.division.isEmpty {
                    await userService.loadDivisionUsers()
                }
            }
        }
        .sheet(item: $activeConversation) { conversation in
            NavigationStack {
                DirectMessageView(conversation: conversation, messagingService: messagingService)
            }
        }
    }

    // MARK: - People Content

    /// Combined and deduplicated suggestions from contacts and school
    private var allSuggestions: [RosterUserData] {
        var seen: Set<UUID> = []
        var result: [RosterUserData] = []
        for user in contactsManager.contactSuggestions {
            if seen.insert(user.id).inserted { result.append(user) }
        }
        for user in userService.schoolSuggestions {
            if seen.insert(user.id).inserted { result.append(user) }
        }
        return result
    }

    /// Returns the reason string for a suggestion
    private func suggestionReason(for user: RosterUserData) -> String {
        if contactsManager.contactSuggestions.contains(where: { $0.id == user.id }) {
            return "In your contacts"
        }
        let school = SavedUserProfile.loadFromStorage()?.collegeAthleteInfo?.school ?? ""
        let sport = SavedUserProfile.loadFromStorage()?.collegeAthleteInfo?.sport ?? ""
        if !school.isEmpty && !sport.isEmpty {
            return "\(school) · \(sport)"
        } else if !school.isEmpty {
            return school
        }
        return "Suggested"
    }

    /// The grid data source — either sport-filtered or all users
    private var displayedUsers: [RosterUserData] {
        if selectedSportFilter != nil {
            return userService.sportUsers
        }
        return userService.users
    }

    private var peopleContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Suggested friends section
                if !allSuggestions.isEmpty && searchText.isEmpty && selectedSportFilter == nil {
                    VStack(alignment: .leading, spacing: 8) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Suggested Friends")
                                .font(.system(size: 17, weight: .bold))
                                .foregroundColor(ClubRalleyTheme.Colors.darkGreen)
                            Text("From your contacts & school")
                                .font(.system(size: 13))
                                .foregroundColor(.gray)
                        }
                        .padding(.horizontal, 16)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(allSuggestions) { user in
                                    SuggestionCard(
                                        user: user,
                                        reason: suggestionReason(for: user),
                                        userService: userService
                                    )
                                }
                            }
                            .padding(.horizontal, 16)
                        }
                    }
                    .padding(.top, 16)
                }

                // Discovery sections (only when not searching and no sport filter)
                if searchText.isEmpty && selectedSportFilter == nil {
                    discoverySection(
                        title: "People from Your School",
                        subtitle: SavedUserProfile.loadFromStorage()?.collegeAthleteInfo?.school,
                        users: userService.schoolUsers
                    )
                    discoverySection(
                        title: "Athletes in Your Sport",
                        subtitle: SavedUserProfile.loadFromStorage()?.collegeAthleteInfo?.sport,
                        users: userService.sportSuggestions
                    )
                    discoverySection(
                        title: "Your Division",
                        subtitle: SavedUserProfile.loadFromStorage()?.collegeAthleteInfo?.division,
                        users: userService.divisionUsers
                    )
                }

                // Search bar
                HStack {
                    Image(systemName: "magnifyingglass").foregroundColor(.gray)
                    TextField("Search athletes...", text: $searchText)
                        .textFieldStyle(PlainTextFieldStyle())
                        .onChange(of: searchText) { _, query in
                            if !query.isEmpty { selectedSportFilter = nil }
                            Task { await userService.searchUsers(query: query) }
                        }
                    if !searchText.isEmpty {
                        Button(action: {
                            searchText = ""
                            selectedSportFilter = nil
                            Task { await userService.loadUsers() }
                        }) {
                            Image(systemName: "xmark.circle.fill").foregroundColor(.gray)
                        }
                    }
                }
                .padding(12).background(Color.white).cornerRadius(12)
                .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
                .padding(.horizontal, 16)
                .padding(.top, 16)

                // Sport filter chips
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        sportChip(label: "All", isSelected: selectedSportFilter == nil) {
                            selectedSportFilter = nil
                            Task { await userService.loadUsers() }
                        }
                        ForEach(sportFilterOptions, id: \.self) { sport in
                            sportChip(label: sport, isSelected: selectedSportFilter == sport) {
                                selectedSportFilter = sport
                                Task { await userService.loadSportUsers(sport: sport) }
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                }

                if userService.isLoading {
                    RosterSkeletonView()
                } else if displayedUsers.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "person.3").font(.system(size: 48)).foregroundColor(ClubRalleyTheme.Colors.darkGreen.opacity(0.5))
                        Text("No athletes found").font(.system(size: 18, weight: .semibold)).foregroundColor(ClubRalleyTheme.Colors.darkGreen)
                        Text(selectedSportFilter != nil ? "No athletes found for this sport" : "Try a different search")
                            .font(.system(size: 15)).foregroundColor(.gray)
                    }.frame(maxWidth: .infinity).padding(.top, 60)
                } else {
                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(displayedUsers) { user in
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

    // MARK: - Sport Filter Chip

    private func sportChip(label: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 13, weight: isSelected ? .bold : .medium))
                .foregroundColor(isSelected ? .white : ClubRalleyTheme.Colors.darkGreen)
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(isSelected ? ClubRalleyTheme.Colors.darkGreen : Color.white)
                .cornerRadius(20)
                .overlay(RoundedRectangle(cornerRadius: 20).stroke(ClubRalleyTheme.Colors.darkGreen.opacity(0.3), lineWidth: 1))
        }
    }

    // MARK: - Discovery Section

    @ViewBuilder
    private func discoverySection(title: String, subtitle: String?, users: [RosterUserData]) -> some View {
        if !users.isEmpty, let subtitle, !subtitle.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(ClubRalleyTheme.Colors.darkGreen)
                    Text(subtitle)
                        .font(.system(size: 13))
                        .foregroundColor(.gray)
                }
                .padding(.horizontal, 16)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(users) { user in
                            SuggestionCard(
                                user: user,
                                reason: user.sport ?? user.school ?? subtitle,
                                userService: userService
                            )
                        }
                    }
                    .padding(.horizontal, 16)
                }
            }
            .padding(.top, 8)
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
                } placeholder: { Circle().fill(ClubRalleyTheme.Colors.darkGreen.opacity(0.2)) }
                .frame(width: 56, height: 56).clipShape(Circle())
                .overlay(Circle().stroke(Color.white, lineWidth: 2))
                .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)

                if user.isVerified {
                    Image(systemName: "checkmark.seal.fill").font(.system(size: 14))
                        .foregroundColor(ClubRalleyTheme.Colors.darkGreen).background(Circle().fill(.white).frame(width: 16, height: 16))
                }
            }

            // Name
            Text(user.name).font(.system(size: 13, weight: .bold)).foregroundColor(ClubRalleyTheme.Colors.darkGreen).lineLimit(1)

            Text(user.location).font(.system(size: 11, weight: .medium)).foregroundColor(.gray).lineLimit(1)

            if let sport = user.sport {
                Text(sport)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(ClubRalleyTheme.Colors.darkGreen)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(ClubRalleyTheme.Colors.darkGreen.opacity(0.1))
                    .cornerRadius(6)
                    .lineLimit(1)
            }

            Text("\(user.mutuals) mutuals").font(.system(size: 11)).foregroundColor(.gray)
            Spacer(minLength: 4)

            HStack(spacing: 8) {
                Button(action: {
                    let impact = UIImpactFeedbackGenerator(style: .light)
                    impact.impactOccurred()
                    Task { await userService.toggleFollow(userId: user.id) }
                }) {
                    Text(user.isFollowing ? "Following" : "Follow")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(user.isFollowing ? .white : ClubRalleyTheme.Colors.darkGreen)
                        .frame(maxWidth: .infinity).padding(.vertical, 8)
                        .background(user.isFollowing ? ClubRalleyTheme.Colors.darkGreen : Color.white)
                        .cornerRadius(6).overlay(RoundedRectangle(cornerRadius: 6).stroke(ClubRalleyTheme.Colors.darkGreen, lineWidth: 1))
                        .animation(.easeInOut(duration: ClubRalleyTheme.Animation.quick), value: user.isFollowing)
                }
                .pressableButton()

                Button(action: onMessageTapped) {
                    ZStack {
                        if isLoadingMessage {
                            ProgressView()
                                .scaleEffect(0.6)
                        } else {
                            Image(systemName: "message").font(.system(size: 12, weight: .medium))
                        }
                    }
                    .foregroundColor(ClubRalleyTheme.Colors.darkGreen).frame(width: 32, height: 32)
                    .background(Color.white).cornerRadius(6)
                    .overlay(RoundedRectangle(cornerRadius: 6).stroke(ClubRalleyTheme.Colors.darkGreen, lineWidth: 1))
                }
                .disabled(isLoadingMessage)
            }
        }
        .padding(12).background(Color.white).cornerRadius(12)
        .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 2)
    }
}

// MARK: - Suggestion Card View

struct SuggestionCard: View {
    let user: RosterUserData
    let reason: String
    @ObservedObject var userService: UserService

    var body: some View {
        VStack(spacing: 8) {
            // Avatar
            AsyncImage(url: URL(string: user.photoURL)) { image in
                image.resizable().aspectRatio(contentMode: .fill)
            } placeholder: {
                Circle().fill(ClubRalleyTheme.Colors.darkGreen.opacity(0.2))
            }
            .frame(width: 48, height: 48)
            .clipShape(Circle())
            .overlay(Circle().stroke(Color.white, lineWidth: 2))

            // Name
            Text(user.name)
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(ClubRalleyTheme.Colors.darkGreen)
                .lineLimit(1)

            // Reason pill
            Text(reason)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(ClubRalleyTheme.Colors.darkGreen)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(ClubRalleyTheme.Colors.darkGreen.opacity(0.1))
                .cornerRadius(8)
                .lineLimit(1)

            // Follow button
            Button(action: {
                let impact = UIImpactFeedbackGenerator(style: .light)
                impact.impactOccurred()
                Task { await userService.toggleFollow(userId: user.id) }
            }) {
                Text(user.isFollowing ? "Following" : "Follow")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(user.isFollowing ? .white : ClubRalleyTheme.Colors.darkGreen)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
                    .background(user.isFollowing ? ClubRalleyTheme.Colors.darkGreen : Color.white)
                    .cornerRadius(8)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(ClubRalleyTheme.Colors.darkGreen, lineWidth: 1))
                    .animation(.easeInOut(duration: ClubRalleyTheme.Animation.quick), value: user.isFollowing)
            }
            .pressableButton()
        }
        .padding(12)
        .frame(width: 140)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 2)
    }
}

// MARK: - Roster Skeleton View

private struct RosterSkeletonView: View {
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
        .shimmer()
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
