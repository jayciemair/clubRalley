//
//  ContentView.swift
//  Club Ralley
//
//  Main app root view for Club Ralley social platform
//  Manages app state transitions and navigation
//

import SwiftUI
import CoreData

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
        stateView
            .navigationViewStyle(.stack)
            .withErrorHandling()
            .overlay(
                Group {
                    if showWelcomeConfetti {
                        WelcomeCelebrationView(isShowing: $showWelcomeConfetti)
                    }
                }
                .ignoresSafeArea(.all)
            )
            .onAppear {
                coordinator.onAppAppear()
            }
            .onChange(of: coordinator.appState) { newState in
                print("[Club Ralley] 🔄 ContentView appState CHANGED to: \(newState)")

                // Trigger welcome confetti when coming from onboarding
                if case .ready(_, showSuccessHUD: true) = newState {
                    showWelcomeConfetti = true
                    coordinator.clearSuccessHUD()
                }
                
                // Update selected tab from app state
                if case .ready(let tab, _) = newState {
                    selectedTab = tab
                }
            }
            .onChange(of: selectedTabOverride) { newValue in
                selectedTab = newValue
                // Update coordinator app state
                coordinator.updateSelectedTab(newValue)
            }
    }

    // MARK: - State View Switcher

    @ViewBuilder
    private var stateView: some View {
        // Temporary: Skip complex state management and go straight to main app
        TabView(selection: $selectedTab) {
            // Home Feed
            HomeFeedView()
                .environmentObject(postManager)
                .environmentObject(ralleyManager)
            .tabItem {
                Image(systemName: selectedTab == .home ? "house.fill" : "house")
                Text("Home")
            }
            .tag(MainTab.home)
            
            // Find Ralleys Tab - Social Media for Pickup Games
            FindRalleysView()
                .environmentObject(ralleyManager)
            .tabItem {
                Image(systemName: selectedTab == .findRalleys ? "sportscourt.fill" : "sportscourt")
                Text("Find Ralleys")
            }
            .tag(MainTab.findRalleys)
            
            // Post Creation Interface (matching Figma design)
            PostCreationInterfaceView()
                .environmentObject(postManager)
            .tabItem {
                Image(systemName: selectedTab == .post ? "plus.circle.fill" : "plus.circle")
                Text("Post")
            }
            .tag(MainTab.post)
            
            VStack(spacing: 20) {
                Image(systemName: "person.2.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(Color(hex: "#2C4F40"))
                
                Text("Teams")
                    .font(.title.bold())
                    .foregroundColor(Color(hex: "#2C4F40"))
                
                Text("Connect with your teams")
                    .font(.subheadline)
                    .foregroundColor(Color(hex: "#666666"))
                    .multilineTextAlignment(.center)
            }
            .padding()
            .tabItem {
                Image(systemName: selectedTab == .teams ? "person.2.fill" : "person.2")
                Text("Teams")
            }
            .tag(MainTab.teams)

            // Figma Profile Design (embedded to avoid import issues)
            NavigationStack {
                ScrollView {
                    VStack(spacing: 0) {
                        // Header Section (improved layout)
                        VStack(spacing: 20) {
                            // Top bar with back button and location
                            HStack {
                                Button(action: {}) {
                                    Image(systemName: "chevron.left")
                                        .font(.system(size: 22, weight: .medium))
                                        .foregroundColor(.black)
                                }
                                
                                Spacer()
                                
                                HStack(spacing: 6) {
                                    Image(systemName: "location.fill")
                                        .font(.system(size: 14))
                                        .foregroundColor(.gray)
                                    Text("Chicago, IL")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(.gray)
                                }
                            }
                            .padding(.horizontal, 24)
                            
                            // Centered Profile Photo (larger and more prominent)
                            AsyncImage(url: URL(string: "https://picsum.photos/100/100?random=50")) { image in
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                            } placeholder: {
                                Circle()
                                    .fill(Color(hex: "#2C4F40"))
                            }
                            .frame(width: 100, height: 100)
                            .clipShape(Circle())
                            .overlay(
                                Circle()
                                    .stroke(Color.white, lineWidth: 4)
                                    .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 2)
                            )
                        }
                        .padding(.top, 16)
                        .padding(.bottom, 24)
                        
                        // Profile Info Section (better centered layout)
                        VStack(spacing: 20) {
                            // Name (larger and more prominent)
                            Text("Gracie King")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(.black)
                            
                            // Social Handles (better spacing)
                            HStack(spacing: 24) {
                                HStack(spacing: 8) {
                                    Image(systemName: "camera.fill")
                                        .font(.system(size: 14))
                                        .foregroundColor(Color(hex: "#2C4F40"))
                                    Text("@Gking")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(.gray)
                                }
                                
                                HStack(spacing: 8) {
                                    Image(systemName: "link.circle.fill")
                                        .font(.system(size: 14))
                                        .foregroundColor(Color(hex: "#2C4F40"))
                                    Text("@gracieking24")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(.gray)
                                }
                            }
                            
                            // Stats Row (cleaner layout)
                            HStack(spacing: 8) {
                                VStack(spacing: 4) {
                                    Text("130")
                                        .font(.system(size: 24, weight: .bold))
                                        .foregroundColor(.black)
                                    Text("followers")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(.gray)
                                }
                                
                                Rectangle()
                                    .fill(Color.gray.opacity(0.3))
                                    .frame(width: 1, height: 40)
                                    .padding(.horizontal, 16)
                                
                                VStack(spacing: 4) {
                                    Text("20")
                                        .font(.system(size: 24, weight: .bold))
                                        .foregroundColor(.black)
                                    Text("games played")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(.gray)
                                }
                                
                                Rectangle()
                                    .fill(Color.gray.opacity(0.3))
                                    .frame(width: 1, height: 40)
                                    .padding(.horizontal, 16)
                                
                                VStack(spacing: 4) {
                                    Text("10")
                                        .font(.system(size: 24, weight: .bold))
                                        .foregroundColor(.black)
                                    Text("wins")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(.gray)
                                }
                            }
                            .padding(.vertical, 16)
                            
                            // Bio (better spacing)
                            Text("Former D1 tennis player at Bucknell University\nClass of 2025")
                                .font(.system(size: 17, weight: .regular))
                                .foregroundColor(.black.opacity(0.8))
                                .multilineTextAlignment(.center)
                                .lineSpacing(6)
                            
                            // Mutual Friends (improved design)
                            VStack(spacing: 16) {
                                Text("Also friends with")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.gray)
                                
                                HStack(spacing: -12) {
                                    ForEach(0..<3, id: \.self) { index in
                                        AsyncImage(url: URL(string: "https://picsum.photos/40/40?random=\(index + 100)")) { image in
                                            image
                                                .resizable()
                                                .aspectRatio(contentMode: .fill)
                                        } placeholder: {
                                            Circle()
                                                .fill(Color(hex: "#2C4F40").opacity(0.3))
                                        }
                                        .frame(width: 40, height: 40)
                                        .clipShape(Circle())
                                        .overlay(
                                            Circle()
                                                .stroke(Color.white, lineWidth: 3)
                                        )
                                        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.bottom, 32)
                        
                        // Action Buttons (improved design)
                        HStack(spacing: 20) {
                            // Follow Button
                            Button(action: {}) {
                                HStack(spacing: 8) {
                                    Image(systemName: "person.badge.plus")
                                        .font(.system(size: 16, weight: .medium))
                                    Text("Follow")
                                        .font(.system(size: 17, weight: .semibold))
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(
                                    LinearGradient(
                                        colors: [Color(hex: "#2C4F40"), Color(hex: "#3A6B4F")],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .cornerRadius(12)
                                .shadow(color: Color(hex: "#2C4F40").opacity(0.3), radius: 8, x: 0, y: 4)
                            }
                            
                            // Message Button
                            Button(action: {}) {
                                HStack(spacing: 8) {
                                    Image(systemName: "message")
                                        .font(.system(size: 16, weight: .medium))
                                    Text("Message")
                                        .font(.system(size: 17, weight: .semibold))
                                }
                                .foregroundColor(Color(hex: "#2C4F40"))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(Color.white)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color(hex: "#2C4F40"), lineWidth: 2)
                                )
                                .cornerRadius(12)
                                .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.bottom, 40)
                        
                        // My Teams Section (improved cards)
                        VStack(alignment: .leading, spacing: 20) {
                            HStack {
                                Text("My Teams")
                                    .font(.system(size: 22, weight: .bold))
                                    .foregroundColor(.black)
                                Spacer()
                                Button(action: {}) {
                                    Text("View All")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(Color(hex: "#2C4F40"))
                                }
                            }
                            
                            HStack(spacing: 16) {
                                // AVS Club Card (enhanced)
                                VStack(spacing: 0) {
                                    ZStack {
                                        AsyncImage(url: URL(string: "https://picsum.photos/180/140?random=201")) { image in
                                            image
                                                .resizable()
                                                .aspectRatio(contentMode: .fill)
                                        } placeholder: {
                                            Rectangle()
                                                .fill(
                                                    LinearGradient(
                                                        colors: [Color(hex: "#2C4F40").opacity(0.2), Color(hex: "#2C4F40").opacity(0.1)],
                                                        startPoint: .topLeading,
                                                        endPoint: .bottomTrailing
                                                    )
                                                )
                                        }
                                        .frame(height: 140)
                                        .clipped()
                                        
                                        // Overlay with sport icon
                                        VStack {
                                            Spacer()
                                            HStack {
                                                Spacer()
                                                Image(systemName: "figure.volleyball")
                                                    .font(.system(size: 24, weight: .bold))
                                                    .foregroundColor(.white)
                                                    .padding(12)
                                                    .background(Color(hex: "#2C4F40").opacity(0.8))
                                                    .clipShape(Circle())
                                            }
                                            .padding(12)
                                        }
                                    }
                                    
                                    VStack(spacing: 8) {
                                        Text("AVS Club")
                                            .font(.system(size: 17, weight: .bold))
                                            .foregroundColor(.black)
                                        Text("Volleyball Team")
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(.gray)
                                    }
                                    .padding(.vertical, 16)
                                    .frame(maxWidth: .infinity)
                                    .background(Color.white)
                                }
                                .background(Color.white)
                                .cornerRadius(16)
                                .shadow(color: Color.black.opacity(0.08), radius: 12, x: 0, y: 4)
                                .frame(maxWidth: .infinity)
                                
                                // Basketball Club Card (enhanced)
                                VStack(spacing: 0) {
                                    ZStack {
                                        AsyncImage(url: URL(string: "https://picsum.photos/180/140?random=202")) { image in
                                            image
                                                .resizable()
                                                .aspectRatio(contentMode: .fill)
                                        } placeholder: {
                                            Rectangle()
                                                .fill(
                                                    LinearGradient(
                                                        colors: [Color(hex: "#2C4F40").opacity(0.2), Color(hex: "#2C4F40").opacity(0.1)],
                                                        startPoint: .topLeading,
                                                        endPoint: .bottomTrailing
                                                    )
                                                )
                                        }
                                        .frame(height: 140)
                                        .clipped()
                                        
                                        // Overlay with sport icon
                                        VStack {
                                            Spacer()
                                            HStack {
                                                Spacer()
                                                Image(systemName: "basketball.fill")
                                                    .font(.system(size: 24, weight: .bold))
                                                    .foregroundColor(.white)
                                                    .padding(12)
                                                    .background(Color(hex: "#2C4F40").opacity(0.8))
                                                    .clipShape(Circle())
                                            }
                                            .padding(12)
                                        }
                                    }
                                    
                                    VStack(spacing: 8) {
                                        Text("Basketball Club")
                                            .font(.system(size: 17, weight: .bold))
                                            .foregroundColor(.black)
                                        Text("Intramural Team")
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(.gray)
                                    }
                                    .padding(.vertical, 16)
                                    .frame(maxWidth: .infinity)
                                    .background(Color.white)
                                }
                                .background(Color.white)
                                .cornerRadius(16)
                                .shadow(color: Color.black.opacity(0.08), radius: 12, x: 0, y: 4)
                                .frame(maxWidth: .infinity)
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.bottom, 40)
                        
                        // My Pics Section (improved gallery)
                        VStack(alignment: .leading, spacing: 20) {
                            HStack {
                                Text("My Pics")
                                    .font(.system(size: 22, weight: .bold))
                                    .foregroundColor(.black)
                                Spacer()
                                Button(action: {}) {
                                    HStack(spacing: 6) {
                                        Image(systemName: "plus.circle.fill")
                                            .font(.system(size: 16))
                                        Text("Add")
                                            .font(.system(size: 16, weight: .medium))
                                    }
                                    .foregroundColor(Color(hex: "#2C4F40"))
                                }
                            }
                            
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 2), spacing: 12) {
                                ForEach(1...4, id: \.self) { index in
                                    AsyncImage(url: URL(string: "https://picsum.photos/190/190?random=\(index + 300)")) { image in
                                        image
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                    } placeholder: {
                                        Rectangle()
                                            .fill(
                                                LinearGradient(
                                                    colors: [Color(hex: "#2C4F40").opacity(0.15), Color(hex: "#2C4F40").opacity(0.05)],
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                )
                                            )
                                    }
                                    .frame(height: 190)
                                    .clipped()
                                    .cornerRadius(16)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16)
                                            .stroke(Color.white, lineWidth: 2)
                                    )
                                    .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4)
                                }
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.bottom, 32)
                        
                        // My Posts Section
                        UserPostsSection()
                            .environmentObject(postManager)
                            .padding(.horizontal, 24)
                            .padding(.bottom, 120) // Extra space for tab bar
                    }
                }
                .navigationBarHidden(true)
            }
            .environmentObject(postManager)
            .environmentObject(ralleyManager)
            .tabItem {
                Image(systemName: selectedTab == .profile ? "person.fill" : "person")
                Text("Profile")
            }
            .tag(MainTab.profile)
        }
        .accentColor(Color(hex: "#2C4F40"))
        .onAppear {
            print("[Club Ralley] 📺 ContentView rendering: Direct TabView (bypassing state machine)")
        }
    }

    // MARK: - Helper Methods

    /// Called when authenticated views appear (analytics setup, etc.)
    private func handleAuthenticatedAppear() {
        // Set default tab if needed
        if ![.home, .findRalleys, .teams, .profile].contains(selectedTab) {
            selectedTab = .home
        }
    }
}

// Note: PostCreationInterfaceView is defined in Views/Post/PostCreationView.swift

// Note: FindRalleysView, RalleyCardView, EmptyRalleysView are in Views/Ralley/FindRalleysView.swift
// Note: RalleyCreationView, CustomTextFieldStyle are in Views/Ralley/RalleyCreationView.swift

// MARK: - Models
// Note: ClubRalley, ClubRalleyOrganizer, ClubRalleyLocation, ClubRalleyPost
// are defined in Models/ClubRalley/ClubRalleyModels.swift

// Note: HomeFeedView, PostCardView, CompactRalleyCard, EmptyFeedView are in Views/Home/HomeFeedView.swift

// Note: UserPostsSection, UserRalleyPreview, UserPostPreview are in Views/Profile/UserContentViews.swift

// MARK: - Preview

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
            .environmentObject(OnboardingFlowController())
    }
}
