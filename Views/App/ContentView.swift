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
        TabView(selection: $selectedTab) {
            HomeFeedView()
                .environmentObject(postManager)
                .environmentObject(ralleyManager)
                .tabItem {
                    Image(systemName: selectedTab == .home ? "house.fill" : "house")
                    Text("Home")
                }
                .tag(MainTab.home)

            FindRalleysView()
                .environmentObject(ralleyManager)
                .tabItem {
                    Image(systemName: selectedTab == .findRalleys ? "sportscourt.fill" : "sportscourt")
                    Text("Find Ralleys")
                }
                .tag(MainTab.findRalleys)

            PostCreationInterfaceView()
                .environmentObject(postManager)
                .tabItem {
                    Image(systemName: selectedTab == .post ? "plus.circle.fill" : "plus.circle")
                    Text("Post")
                }
                .tag(MainTab.post)

            RosterView()
                .tabItem {
                    Image(systemName: selectedTab == .teams ? "person.2.fill" : "person.2")
                    Text("Roster")
                }
                .tag(MainTab.teams)

            ProfileTabView()
                .tabItem {
                    Image(systemName: selectedTab == .profile ? "person.fill" : "person")
                    Text("Profile")
                }
                .tag(MainTab.profile)
        }
        .accentColor(Color(hex: "#2C4F40"))
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
    @State private var searchText = ""
    @State private var selectedTab: RosterTab = .people
    private let columns = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]

    var body: some View {
        NavigationStack {
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
                            Button(action: { withAnimation(.easeInOut(duration: 0.2)) { selectedTab = tab } }) {
                                VStack(spacing: 8) {
                                    Text(tab.rawValue)
                                        .font(.system(size: 16, weight: selectedTab == tab ? .semibold : .medium))
                                        .foregroundColor(selectedTab == tab ? Color(hex: "#2C4F40") : .gray)

                                    Rectangle()
                                        .fill(selectedTab == tab ? Color(hex: "#2C4F40") : Color.clear)
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
                if selectedTab == .people {
                    peopleContent
                } else {
                    ChatsListView()
                }
            }
            .background(Color(hex: "#F5F5F5"))
            .navigationBarHidden(true)
        }
        .task { await userService.loadUsers(); await userService.loadFollowingStatus() }
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
                    HStack { Spacer(); ProgressView(); Spacer() }.padding(.top, 40)
                } else if userService.users.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "person.3").font(.system(size: 48)).foregroundColor(Color(hex: "#2C4F40").opacity(0.5))
                        Text("No athletes found").font(.system(size: 18, weight: .semibold))
                        Text("Try a different search").font(.system(size: 15)).foregroundColor(.gray)
                    }.frame(maxWidth: .infinity).padding(.top, 60)
                } else {
                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(userService.users) { user in
                            RosterUserCardView(user: user, userService: userService)
                        }
                    }.padding(.horizontal, 16)
                }
                Spacer(minLength: 100)
            }
        }
    }
}

// MARK: - Roster User Card View

struct RosterUserCardView: View {
    let user: RosterUserData
    @ObservedObject var userService: UserService
    @StateObject private var messagingService = MessagingService()
    @State private var showingDirectMessage = false
    @State private var conversation: DirectConversation?
    @State private var isLoadingMessage = false

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

                Button(action: { Task { await openDirectMessage() } }) {
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
        .sheet(isPresented: $showingDirectMessage) {
            if let conversation = conversation {
                NavigationStack {
                    DirectMessageView(conversation: conversation, messagingService: messagingService)
                }
            }
        }
    }

    private func openDirectMessage() async {
        isLoadingMessage = true
        do {
            conversation = try await messagingService.getOrCreateConversation(with: user.id)
            showingDirectMessage = true
        } catch {
            print("Failed to open conversation: \(error)")
        }
        isLoadingMessage = false
    }
}

// MARK: - Profile Tab View

struct ProfileTabView: View {
    @State private var showingSettings = false
    @State private var showingEditProfile = false
    @State private var isLoading = true
    private let supabase = SupabaseManager.shared

    // Current user data from Supabase
    private var currentUser: (name: String, username: String, location: String, photoURL: String, followers: Int, following: Int, ralleys: Int, bio: String?, isVerified: Bool) {
        if let user = supabase.currentUser {
            let username = user.email.components(separatedBy: "@").first ?? "user"
            return (user.displayName, username, "Chicago, IL", "https://picsum.photos/100/100?random=\(user.id.hashValue % 100)", 130, 95, 15, "Love staying active and meeting new people through sports!", false)
        }
        return ("Your Name", "yourname", "Chicago, IL", "https://picsum.photos/100/100?random=50", 130, 95, 15, "Love staying active!", false)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    currentUserHeader
                    currentUserInfo
                    editProfileButton
                    profileTeamsSection
                    profilePhotosSection
                    Spacer(minLength: 100)
                }
            }
            .background(Color(hex: "#F5F5F5")).navigationBarHidden(true)
            .sheet(isPresented: $showingSettings) {
                ProfileSettingsView()
            }
            .sheet(isPresented: $showingEditProfile) {
                EditProfileView()
            }
        }
    }

    private var currentUserHeader: some View {
        VStack(spacing: 20) {
            HStack {
                Button(action: { showingSettings = true }) {
                    Image(systemName: "gearshape").font(.system(size: 22, weight: .medium)).foregroundColor(Color(hex: "#2C4F40"))
                }
                Spacer()
                HStack(spacing: 6) {
                    Image(systemName: "location.fill").font(.system(size: 14)).foregroundColor(.gray)
                    Text(currentUser.location).font(.system(size: 16, weight: .medium)).foregroundColor(.gray)
                }
            }.padding(.horizontal, 24)

            AsyncImage(url: URL(string: currentUser.photoURL)) { image in
                image.resizable().aspectRatio(contentMode: .fill)
            } placeholder: { Circle().fill(Color(hex: "#2C4F40")) }
            .frame(width: 110, height: 110).clipShape(Circle())
            .overlay(Circle().stroke(Color.white, lineWidth: 4))
            .shadow(color: Color.black.opacity(0.15), radius: 12, x: 0, y: 4)

            VStack(spacing: 8) {
                HStack(spacing: 8) {
                    Text(currentUser.name).font(.system(size: 26, weight: .bold)).foregroundColor(.black)
                    if currentUser.isVerified {
                        Image(systemName: "checkmark.seal.fill").foregroundColor(Color(hex: "#2C4F40")).font(.system(size: 18))
                    }
                }
                Text("@\(currentUser.username)").font(.system(size: 16, weight: .medium)).foregroundColor(.gray)
            }
        }.padding(.top, 16).padding(.bottom, 24)
    }

    private var currentUserInfo: some View {
        VStack(spacing: 24) {
            HStack(spacing: 32) {
                VStack(spacing: 4) { Text("\(currentUser.followers)").font(.system(size: 22, weight: .bold)); Text("Followers").font(.system(size: 14, weight: .medium)).foregroundColor(.gray) }
                VStack(spacing: 4) { Text("\(currentUser.following)").font(.system(size: 22, weight: .bold)); Text("Following").font(.system(size: 14, weight: .medium)).foregroundColor(.gray) }
                VStack(spacing: 4) { Text("\(currentUser.ralleys)").font(.system(size: 22, weight: .bold)); Text("Ralleys").font(.system(size: 14, weight: .medium)).foregroundColor(.gray) }
            }
            if let bio = currentUser.bio, !bio.isEmpty {
                Text(bio).font(.system(size: 15)).foregroundColor(.gray).multilineTextAlignment(.center).padding(.horizontal, 40)
            }
        }.padding(.horizontal, 24).padding(.bottom, 24)
    }

    private var editProfileButton: some View {
        Button(action: { showingEditProfile = true }) {
            HStack(spacing: 8) {
                Image(systemName: "pencil").font(.system(size: 16, weight: .medium))
                Text("Edit Profile").font(.system(size: 17, weight: .semibold))
            }
            .foregroundColor(Color(hex: "#2C4F40")).frame(maxWidth: .infinity).padding(.vertical, 16)
            .background(Color.white).overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(hex: "#2C4F40"), lineWidth: 2)).cornerRadius(12)
            .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
        }.padding(.horizontal, 24).padding(.bottom, 32)
    }

    private var profileTeamsSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack { Text("My Teams").font(.system(size: 22, weight: .bold)); Spacer(); Button(action: {}) { Text("View All").font(.system(size: 16, weight: .medium)).foregroundColor(Color(hex: "#2C4F40")) } }
            Text("No teams yet. Join a ralley to connect with teams!").font(.system(size: 15)).foregroundColor(.gray)
        }.padding(.horizontal, 24).padding(.bottom, 32)
    }

    private var profilePhotosSection: some View {
        let columns = [GridItem(.flexible(), spacing: 4), GridItem(.flexible(), spacing: 4), GridItem(.flexible(), spacing: 4)]
        return VStack(alignment: .leading, spacing: 20) {
            HStack { Text("Photos").font(.system(size: 22, weight: .bold)); Spacer(); Button(action: {}) { Text("View All").font(.system(size: 16, weight: .medium)).foregroundColor(Color(hex: "#2C4F40")) } }
            LazyVGrid(columns: columns, spacing: 4) {
                ForEach(1...9, id: \.self) { i in
                    AsyncImage(url: URL(string: "https://picsum.photos/150/150?random=\(i + 400)")) { img in img.resizable().aspectRatio(contentMode: .fill) } placeholder: { Rectangle().fill(Color.gray.opacity(0.2)) }
                        .frame(height: 110).clipped().cornerRadius(8)
                }
            }
        }.padding(.horizontal, 24)
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
