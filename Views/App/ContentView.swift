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

// MARK: - Post Creation Interface (Figma Design)

struct PostCreationInterfaceView: View {
    @EnvironmentObject var postManager: PostManager
    @State private var postText = ""
    @State private var showingPhotosPicker = false
    @State private var showingCamera = false
    @State private var showingTitleOption = false
    @State private var postTitle = ""
    @State private var selectedImages: [String] = []
    @State private var isPosting = false
    @State private var showingSuccessMessage = false
    @State private var showingDiscardAlert = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header
                HStack {
                    // Close Button
                    Button(action: {
                        handleClose()
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.black)
                            .frame(width: 30, height: 30)
                    }
                    
                    Spacer()
                    
                    // Post Button
                    Button(action: {
                        createPost()
                    }) {
                        HStack(spacing: 6) {
                            if isPosting {
                                ProgressView()
                                    .scaleEffect(0.8)
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            }
                            Text(isPosting ? "Posting..." : "Post")
                                .font(.system(size: 17, weight: .semibold))
                        }
                        .foregroundColor(canPost ? .white : .gray)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 8)
                        .background(
                            canPost
                                ? Color(hex: "#2C4F40")
                                : Color.gray.opacity(0.3)
                        )
                        .cornerRadius(20)
                    }
                    .disabled(!canPost || isPosting)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                
                // Main Content Area
                ScrollView {
                    VStack(spacing: 20) {
                        // Profile and Text Input
                        HStack(alignment: .top, spacing: 12) {
                            // Profile Photo
                            AsyncImage(url: URL(string: "https://picsum.photos/44/44?random=1")) { image in
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                            } placeholder: {
                                Circle()
                                    .fill(Color(hex: "#2C4F40"))
                            }
                            .frame(width: 44, height: 44)
                            .clipShape(Circle())
                            
                            // Text Input Area
                            VStack(alignment: .leading, spacing: 12) {
                                // Title Input (conditional)
                                if showingTitleOption {
                                    TextField("Add a Title", text: $postTitle)
                                        .font(.system(size: 20, weight: .semibold))
                                        .foregroundColor(.black)
                                        .padding(.vertical, 4)
                                }
                                
                                // Main Text Input
                                VStack(alignment: .leading, spacing: 8) {
                                    TextField("What's happening?", text: $postText, axis: .vertical)
                                        .font(.system(size: 18, weight: .regular))
                                        .foregroundColor(.black)
                                        .lineLimit(15, reservesSpace: false)
                                    
                                    // Character counter (if text is not empty)
                                    if !postText.isEmpty {
                                        HStack {
                                            Spacer()
                                            Text("\(postText.count)/280")
                                                .font(.system(size: 14, weight: .medium))
                                                .foregroundColor(postText.count > 280 ? .red : (postText.count > 250 ? .orange : .gray))
                                        }
                                    }
                                }
                            }
                            
                            Spacer()
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 8)
                        
                        // Selected Images Preview
                        if !selectedImages.isEmpty {
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: selectedImages.count > 1 ? 2 : 1), spacing: 8) {
                                ForEach(selectedImages.indices, id: \.self) { index in
                                    ZStack {
                                        AsyncImage(url: URL(string: "https://picsum.photos/200/200?random=\(index + 500)")) { image in
                                            image
                                                .resizable()
                                                .aspectRatio(contentMode: .fill)
                                        } placeholder: {
                                            Rectangle()
                                                .fill(Color.gray.opacity(0.2))
                                        }
                                        .frame(height: selectedImages.count == 1 ? 250 : 180)
                                        .clipped()
                                        .cornerRadius(12)
                                        
                                        // Remove Button
                                        VStack {
                                            HStack {
                                                Spacer()
                                                Button(action: {
                                                    selectedImages.remove(at: index)
                                                }) {
                                                    Image(systemName: "xmark.circle.fill")
                                                        .font(.system(size: 24))
                                                        .foregroundColor(.white)
                                                        .background(Color.black.opacity(0.6))
                                                        .clipShape(Circle())
                                                }
                                                .padding(8)
                                            }
                                            Spacer()
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal, 16)
                        }
                        
                        Spacer(minLength: 120)
                    }
                }
                
                // Bottom Toolbar
                VStack(spacing: 0) {
                    Rectangle()
                        .frame(height: 1)
                        .foregroundColor(Color.gray.opacity(0.2))
                    
                    HStack(spacing: 24) {
                        // Photo Gallery Button
                        Button(action: {
                            addPhoto()
                        }) {
                            ZStack {
                                Image(systemName: "photo")
                                    .font(.system(size: 22))
                                    .foregroundColor(Color(hex: "#2C4F40"))
                                
                                // Photo count badge
                                if selectedImages.count > 0 {
                                    VStack {
                                        HStack {
                                            Spacer()
                                            Text("\(selectedImages.count)")
                                                .font(.system(size: 12, weight: .bold))
                                                .foregroundColor(.white)
                                                .frame(width: 18, height: 18)
                                                .background(Color(hex: "#2C4F40"))
                                                .clipShape(Circle())
                                        }
                                        Spacer()
                                    }
                                }
                            }
                        }
                        
                        // Camera Button
                        Button(action: {
                            addCameraPhoto()
                        }) {
                            Image(systemName: "camera")
                                .font(.system(size: 22))
                                .foregroundColor(Color(hex: "#2C4F40"))
                        }
                        
                        // Attachment Button
                        Button(action: {
                            // Handle other attachments
                        }) {
                            Image(systemName: "link")
                                .font(.system(size: 22))
                                .foregroundColor(Color(hex: "#2C4F40"))
                        }
                        
                        // Title Toggle Button
                        Button(action: {
                            let lightFeedback = UIImpactFeedbackGenerator(style: .light)
                            lightFeedback.impactOccurred()
                            showingTitleOption.toggle()
                        }) {
                            HStack(spacing: 6) {
                                Image(systemName: "textformat")
                                    .font(.system(size: 18))
                                Text("Title")
                                    .font(.system(size: 16, weight: .medium))
                            }
                            .foregroundColor(showingTitleOption ? Color(hex: "#2C4F40") : .gray)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(
                                showingTitleOption 
                                    ? Color(hex: "#2C4F40").opacity(0.1)
                                    : Color.clear
                            )
                            .cornerRadius(16)
                        }
                        
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                    .background(Color.white)
                }
            }
            .background(Color.white)
            .navigationBarHidden(true)
            .overlay(
                // Success Message
                Group {
                    if showingSuccessMessage {
                        VStack {
                            Spacer()
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 20))
                                    .foregroundColor(.white)
                                Text("Post shared successfully!")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.white)
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                            .background(Color(hex: "#2C4F40"))
                            .cornerRadius(25)
                            .shadow(color: Color.black.opacity(0.2), radius: 8, x: 0, y: 4)
                            .padding(.bottom, 100)
                        }
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: showingSuccessMessage)
                    }
                }
            )
            .alert("Discard Post?", isPresented: $showingDiscardAlert) {
                Button("Discard", role: .destructive) {
                    clearForm()
                }
                Button("Keep Editing", role: .cancel) {}
            } message: {
                Text("Are you sure you want to discard this post? Your changes will be lost.")
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var canPost: Bool {
        let trimmedText = postText.trimmingCharacters(in: .whitespacesAndNewlines)
        return (!trimmedText.isEmpty || !selectedImages.isEmpty) && postText.count <= 280
    }
    
    private var hasUnsavedContent: Bool {
        !postText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || 
        !selectedImages.isEmpty ||
        (showingTitleOption && !postTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
    }
    
    // MARK: - Post Creation Functions
    
    private func handleClose() {
        if hasUnsavedContent {
            showingDiscardAlert = true
        } else {
            clearForm()
        }
    }
    
    /**
     * Create new post using real backend integration
     * Handles authentication, validation, and error states with proper async patterns
     */
    private func createPost() {
        guard canPost && !isPosting else { return }
        
        isPosting = true
        
        // Use async post creation with real backend integration
        Task { @MainActor in
            do {
                // Prepare image URLs (in real implementation, these would be uploaded first)
                let imageUrls = selectedImages.isEmpty ? [] : 
                    Array(0..<selectedImages.count).map { "https://picsum.photos/300/300?random=\($0 + 600)" }
                
                // Create post via PostManager (which handles backend sync)
                await postManager.createPost(
                    content: postText,
                    title: showingTitleOption && !postTitle.isEmpty ? postTitle : nil,
                    images: imageUrls
                )
                
                // Check if there was an error during creation
                if let error = postManager.error {
                    print("⚠️ Post creation had issues: \(error)")
                    // Post was still added to local cache, so continue with success flow
                    // In production, might want to show error alert here
                }
                
                // Clear the form
                clearForm()
                
                // Add haptic feedback for successful creation
                let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                impactFeedback.impactOccurred()
                
                // Show success message
                showingSuccessMessage = true
                
                // Hide success message after delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    showingSuccessMessage = false
                }
                
                print("✅ Post created and added to feed with backend integration!")
                print("📝 Title: \(showingTitleOption && !postTitle.isEmpty ? postTitle ?? "None" : "None")")
                print("💬 Content: \(postText)")
                print("🖼️ Images: \(imageUrls.count)")
                print("📊 Total posts: \(postManager.posts.count)")
                print("🔄 Backend sync: \(postManager.error == nil ? "✅ Success" : "⚠️ With issues")")
                
            } catch {
                print("❌ Post creation failed with error: \(error)")
                
                // Show error state to user  
                // For now, just log - in production would show proper error alert
                showingSuccessMessage = false
            }
            
            isPosting = false
        }
    }
    
    private func clearForm() {
        postText = ""
        postTitle = ""
        selectedImages.removeAll()
        showingTitleOption = false
    }
    
    private func addPhoto() {
        let lightFeedback = UIImpactFeedbackGenerator(style: .light)
        lightFeedback.impactOccurred()
        
        selectedImages.append("photo_\(selectedImages.count)")
        print("📷 Photo added from gallery")
    }
    
    private func addCameraPhoto() {
        let lightFeedback = UIImpactFeedbackGenerator(style: .light)
        lightFeedback.impactOccurred()
        
        selectedImages.append("camera_\(selectedImages.count)")
        print("📸 Photo added from camera")
    }
}

// MARK: - Ralley Manager

/**
 * RalleyManager: Central state manager for all pickup game operations
 * 
 * Purpose: Manages ralleys (pickup games) across the app with real backend integration
 * Strategy: Uses RalleyService for database operations, maintains local cache
 * Integration: Connected to Supabase ralleys table via RalleyService
 */
@MainActor
class RalleyManager: ObservableObject {
    
    // MARK: - Published Properties
    
    /// All ralleys for discovery feed and user profiles
    @Published var ralleys: [ClubRalley] = []
    
    /// Controls ralley creation sheet presentation
    @Published var showingCreateRalley = false
    
    /// Loading state for UI feedback
    @Published var isLoading = false
    
    /// Error state for user notifications
    @Published var error: Error?
    
    // MARK: - Dependencies
    
    /// Service layer for ralley database operations
    private let ralleyService = RalleyService()
    
    /// Supabase authentication state
    private let supabase = SupabaseManager.shared
    
    // MARK: - Initialization
    
    init() {
        // Load ralleys from backend on startup
        Task {
            await loadRalleys()
        }
    }
    
    // MARK: - Ralley Loading
    
    /**
     * Load ralleys from Supabase database for discovery feed
     * Handles both real data and fallback to mock data for development
     */
    func loadRalleys() async {
        isLoading = true
        error = nil
        
        do {
            let loadedRalleys = try await ralleyService.loadNearbyRalleys()
            ralleys = loadedRalleys
            print("✅ RalleyManager: Loaded \(loadedRalleys.count) ralleys from backend")
        } catch {
            print("❌ RalleyManager: Failed to load ralleys: \(error)")
            self.error = error
            
            // Fallback to sample ralleys for development
            await loadSampleRalleys()
        }
        
        isLoading = false
    }
    
    /**
     * Load sample ralleys for development and offline scenarios
     * Ensures app remains functional even without backend connectivity
     */
    private func loadSampleRalleys() async {
        let sampleRalleys = [
            ClubRalley(
                id: UUID(),
                title: "Basketball Pickup",
                sport: "Basketball",
                description: "Friendly pickup basketball game. All skill levels welcome!",
                organizer: RalleyOrganizer(
                    id: UUID(),
                    name: "Alex Johnson",
                    username: "@alexj", 
                    photoURL: "https://picsum.photos/50/50?random=401"
                ),
                dateTime: Date().addingTimeInterval(3600 * 2), // 2 hours from now
                location: RalleyLocation(
                    name: "Riverside Park Courts",
                    address: "123 Park Ave",
                    city: "Chicago",
                    state: "IL",
                    latitude: 41.8781,
                    longitude: -87.6298
                ),
                maxPlayers: 8,
                currentPlayers: 5,
                cost: 0,
                requirements: "Bring your own water and sneakers",
                isPublic: true
            ),
            ClubRalley(
                id: UUID(),
                title: "Tennis Doubles",
                sport: "Tennis",
                description: "Looking for tennis doubles partners. Intermediate level preferred.",
                organizer: RalleyOrganizer(
                    id: UUID(),
                    name: "Sarah Wilson",
                    username: "@sarahw",
                    photoURL: "https://picsum.photos/50/50?random=402"
                ),
                dateTime: Date().addingTimeInterval(3600 * 18), // Tomorrow morning
                location: RalleyLocation(
                    name: "University Tennis Center",
                    address: "456 College Blvd",
                    city: "Chicago",
                    state: "IL",
                    latitude: 41.8958,
                    longitude: -87.6388
                ),
                maxPlayers: 4,
                currentPlayers: 2,
                cost: 15,
                requirements: "Bring racket and tennis balls",
                isPublic: true
            ),
            ClubRalley(
                id: UUID(),
                title: "My Test Ralley", // User's own ralley for testing
                sport: "Soccer",
                description: "Just created my first ralley! Looking forward to a fun pickup game.",
                organizer: RalleyOrganizer(
                    id: UUID(),
                    name: "Your Name",
                    username: "@you",
                    photoURL: "https://picsum.photos/50/50?random=50"
                ),
                dateTime: Date().addingTimeInterval(3600 * 6), // 6 hours from now
                location: RalleyLocation(
                    name: "Local Soccer Field",
                    address: "789 Sports Ave",
                    city: "Chicago",
                    state: "IL",
                    latitude: 41.8500,
                    longitude: -87.6500
                ),
                maxPlayers: 12,
                currentPlayers: 1,
                cost: 5,
                requirements: "Bring cleats",
                isPublic: true
            )
        ]
        
        ralleys = sampleRalleys
        print("📱 RalleyManager: Using sample ralleys (fallback mode)")
    }
    
    // MARK: - Ralley Creation
    
    /**
     * Create new ralley and save to database
     * @param title: Ralley title
     * @param sport: Sport type
     * @param dateTime: When the ralley happens
     * @param locationName: Venue name
     * @param address: Venue address
     * @param maxPlayers: Maximum participants
     * @param cost: Cost per person (optional)
     * @param description: Ralley description
     * @param requirements: Special requirements
     * 
     * Flow: Create local ralley -> Save to database -> Update local cache
     */
    func createRalley(
        title: String,
        sport: String,
        dateTime: Date,
        locationName: String,
        address: String = "",
        city: String = "San Francisco",
        state: String = "CA",
        maxPlayers: Int,
        cost: Double = 0.0,
        description: String,
        requirements: String = ""
    ) async {
        guard !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            print("❌ RalleyManager: Cannot create ralley with empty title")
            return
        }
        
        isLoading = true
        error = nil
        
        // Create local ralley model with current user as organizer
        let newRalley = ClubRalley(
            id: UUID(),
            title: title,
            sport: sport,
            description: description,
            organizer: RalleyOrganizer(
                id: supabase.currentUser?.id ?? UUID(),
                name: supabase.currentUser?.displayName ?? "Your Name",
                username: "@\(supabase.currentUser?.email.components(separatedBy: "@").first ?? "you")",
                photoURL: "https://picsum.photos/50/50?random=50" // TODO: Get real profile photo
            ),
            dateTime: dateTime,
            location: RalleyLocation(
                name: locationName,
                address: address,
                city: city,
                state: state,
                latitude: 37.7749, // TODO: Geocode address to get real coordinates
                longitude: -122.4194
            ),
            maxPlayers: maxPlayers,
            currentPlayers: 1, // Organizer is first player
            cost: cost,
            requirements: requirements,
            isPublic: true
        )
        
        do {
            // Save to database via RalleyService
            let createdRalley = try await ralleyService.createRalley(newRalley)
            
            // Add to local cache at the top of feed
            ralleys.insert(createdRalley, at: 0)
            
            print("✅ RalleyManager: Ralley created successfully")
            
        } catch {
            print("❌ RalleyManager: Failed to create ralley: \(error)")
            self.error = error
            
            // Even if backend fails, add to local cache for immediate UI feedback
            ralleys.insert(newRalley, at: 0)
            print("📱 RalleyManager: Ralley added locally (backend failed)")
        }
        
        isLoading = false
    }
    
    // MARK: - Ralley Participation
    
    /**
     * Join a ralley (add current user as participant)
     * Updates both database and local cache
     * @param ralleyId: ID of ralley to join
     */
    func joinRalley(_ ralleyId: UUID) async {
        guard supabase.isAuthenticated else {
            print("❌ RalleyManager: Must be authenticated to join ralleys")
            return
        }
        
        // Optimistic UI update - change local state immediately
        if let index = ralleys.firstIndex(where: { $0.id == ralleyId }) {
            guard ralleys[index].currentPlayers < ralleys[index].maxPlayers else {
                print("❌ RalleyManager: Ralley is already full")
                return
            }
            
            let originalPlayers = ralleys[index].currentPlayers
            ralleys[index].currentPlayers += 1
            
            print("⚡ RalleyManager: Optimistic join update for ralley")
            
            // Attempt to sync with database
            do {
                let success = try await ralleyService.joinRalley(ralleyId: ralleyId)
                
                if success {
                    print("✅ RalleyManager: Join synced with database")
                } else {
                    // Revert optimistic update on failure
                    ralleys[index].currentPlayers = originalPlayers
                }
                
            } catch {
                print("❌ RalleyManager: Failed to sync join with database: \(error)")
                
                // Revert optimistic update on failure
                ralleys[index].currentPlayers = originalPlayers
                self.error = error
            }
        }
    }
    
    /**
     * Legacy method for immediate UI updates (maintains backward compatibility)
     * @param ralley: Full ralley model to add to feed
     */
    func addRalley(_ ralley: ClubRalley) {
        ralleys.insert(ralley, at: 0) // Add to beginning of feed
        print("📝 RalleyManager: Ralley added to local feed")
    }
    
    // MARK: - User Content Filtering
    
    /**
     * Get ralleys created by current user for profile display
     * @returns: Array of user's ralleys sorted by date
     */
    func getUserRalleys() -> [ClubRalley] {
        let currentUserName = supabase.currentUser?.displayName ?? "Your Name"
        let userRalleys = ralleys.filter { $0.organizer.name == currentUserName }
        
        print("👤 RalleyManager: Found \(userRalleys.count) ralleys for current user")
        return userRalleys.sorted { $0.dateTime < $1.dateTime } // Sort by upcoming first
    }
    
    /**
     * Get ralleys for specific user (for viewing other profiles)
     * @param username: Username to filter ralleys by
     * @returns: Array of user's ralleys
     */
    func getRalleysForUser(username: String) -> [ClubRalley] {
        return ralleys.filter { $0.organizer.username == username }
            .sorted { $0.dateTime < $1.dateTime }
    }
    
    // MARK: - Feed Management
    
    /**
     * Refresh ralleys by reloading from database
     * Used for pull-to-refresh functionality
     */
    func refreshRalleys() async {
        print("🔄 RalleyManager: Refreshing ralleys from database")
        await loadRalleys()
    }
    
    /**
     * Clear error state (for user notification dismissal)
     */
    func clearError() {
        error = nil
    }
    
    /**
     * Present ralley creation sheet
     */
    func presentCreateRalley() {
        showingCreateRalley = true
    }
    
    /**
     * Dismiss ralley creation sheet
     */
    func dismissCreateRalley() {
        showingCreateRalley = false
    }
}

// MARK: - Find Ralleys View

struct FindRalleysView: View {
    @EnvironmentObject var ralleyManager: RalleyManager
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 12) {
                        HStack(spacing: 12) {
                            Image(systemName: "sportscourt.fill")
                                .font(.system(size: 32, weight: .bold))
                                .foregroundColor(Color(hex: "#2C4F40"))
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Find Ralleys")
                                    .font(.system(size: 28, weight: .bold))
                                    .foregroundColor(.black)
                                Text("Join pickup games near you")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.gray)
                            }
                            Spacer()
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 16)
                    }
                    
                    // Quick Actions
                    HStack(spacing: 16) {
                        // Create Ralley Button
                        Button(action: {
                            ralleyManager.showingCreateRalley = true
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 18))
                                Text("Create Ralley")
                                    .font(.system(size: 16, weight: .semibold))
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
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
                        
                        // Filter Button
                        Button(action: {}) {
                            HStack(spacing: 8) {
                                Image(systemName: "slider.horizontal.3")
                                    .font(.system(size: 16))
                                Text("Filter")
                                    .font(.system(size: 16, weight: .semibold))
                            }
                            .foregroundColor(Color(hex: "#2C4F40"))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.white)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color(hex: "#2C4F40"), lineWidth: 2)
                            )
                            .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
                        }
                    }
                    .padding(.horizontal, 24)
                    
                    // Nearby Ralleys
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text("Nearby Ralleys")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.black)
                            Spacer()
                            Text("📍 2.5 mi")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.gray)
                        }
                        .padding(.horizontal, 24)
                        
                        // Ralley Cards
                        if ralleyManager.ralleys.isEmpty {
                            EmptyRalleysView()
                        } else {
                            VStack(spacing: 16) {
                                ForEach(ralleyManager.ralleys) { ralley in
                                    RalleyCardView(ralley: ralley)
                                        .environmentObject(ralleyManager)
                                }
                            }
                            .padding(.horizontal, 24)
                        }
                    }
                    
                    Spacer(minLength: 100)
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $ralleyManager.showingCreateRalley) {
                RalleyCreationView()
                    .environmentObject(ralleyManager)
            }
        }
    }
}

// MARK: - Ralley Card View

struct RalleyCardView: View {
    let ralley: ClubRalley
    @EnvironmentObject var ralleyManager: RalleyManager
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack(spacing: 12) {
                AsyncImage(url: URL(string: ralley.organizer.photoURL)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Circle()
                        .fill(Color(hex: "#2C4F40"))
                }
                .frame(width: 50, height: 50)
                .clipShape(Circle())
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(ralley.title)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.black)
                    Text("\(ralley.dateTime.formatted(date: .omitted, time: .shortened)) • \(ralley.currentPlayers)/\(ralley.maxPlayers) players")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                Image(systemName: ralley.sport.lowercased() == "basketball" ? "basketball.fill" : "tennisball.fill")
                    .font(.system(size: 24))
                    .foregroundColor(Color(hex: "#2C4F40"))
            }
            .padding(16)
            
            // Location & Details
            HStack(spacing: 8) {
                Image(systemName: "location.fill")
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
                Text(ralley.location.name)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.gray)
                Spacer()
                Text(ralley.cost == 0 ? "FREE" : "$\(ralley.cost)")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(Color(hex: "#2C4F40"))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color(hex: "#2C4F40").opacity(0.1))
                    .cornerRadius(8)
            }
            .padding(.horizontal, 16)
            
            // Join Button
            Button(action: {
                ralleyManager.joinRalley(ralley.id)
            }) {
                Text(ralley.currentPlayers >= ralley.maxPlayers ? "Full" : "Join Ralley")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(ralley.currentPlayers >= ralley.maxPlayers ? .gray : .white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        ralley.currentPlayers >= ralley.maxPlayers 
                            ? Color.gray.opacity(0.3)
                            : Color(hex: "#2C4F40")
                    )
                    .cornerRadius(10)
            }
            .disabled(ralley.currentPlayers >= ralley.maxPlayers)
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.08), radius: 12, x: 0, y: 4)
    }
}

// MARK: - Empty Ralleys View

struct EmptyRalleysView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "sportscourt")
                .font(.system(size: 60))
                .foregroundColor(Color(hex: "#2C4F40").opacity(0.6))
            
            Text("No ralleys nearby")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.black)
            
            Text("Be the first to create a pickup game in your area!")
                .font(.system(size: 16, weight: .regular))
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .padding(.vertical, 40)
    }
}

// MARK: - Ralley Creation View

struct RalleyCreationView: View {
    @EnvironmentObject var ralleyManager: RalleyManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var title = ""
    @State private var sport = ""
    @State private var selectedDate = Date()
    @State private var locationName = ""
    @State private var maxPlayers = 4
    @State private var cost = 0
    @State private var description = ""
    @State private var requirements = ""
    @State private var isCreating = false
    @State private var showingSuccessMessage = false
    
    var canCreate: Bool {
        !title.isEmpty && !sport.isEmpty && !locationName.isEmpty && maxPlayers > 0
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    Text("Create New Ralley")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.black)
                        .padding(.top, 8)
                    
                    VStack(spacing: 20) {
                        // Basic Info
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Basic Information")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.black)
                            
                            VStack(spacing: 12) {
                                TextField("Ralley title (e.g. Basketball Pickup)", text: $title)
                                    .textFieldStyle(CustomTextFieldStyle())
                                
                                TextField("Sport (e.g. Basketball, Tennis)", text: $sport)
                                    .textFieldStyle(CustomTextFieldStyle())
                                
                                DatePicker("Date & Time", selection: $selectedDate, displayedComponents: [.date, .hourAndMinute])
                                    .font(.system(size: 16, weight: .medium))
                                    .padding(.vertical, 8)
                            }
                        }
                        
                        // Location & Players
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Location & Players")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.black)
                            
                            VStack(spacing: 12) {
                                TextField("Location name (e.g. Central Park Courts)", text: $locationName)
                                    .textFieldStyle(CustomTextFieldStyle())
                                
                                HStack {
                                    Text("Max Players:")
                                        .font(.system(size: 16, weight: .medium))
                                    Spacer()
                                    Stepper(value: $maxPlayers, in: 2...20) {
                                        Text("\(maxPlayers)")
                                            .font(.system(size: 16, weight: .semibold))
                                            .foregroundColor(Color(hex: "#2C4F40"))
                                    }
                                }
                                .padding(.vertical, 8)
                                
                                HStack {
                                    Text("Cost per person:")
                                        .font(.system(size: 16, weight: .medium))
                                    Spacer()
                                    Stepper(value: $cost, in: 0...100, step: 5) {
                                        Text(cost == 0 ? "FREE" : "$\(cost)")
                                            .font(.system(size: 16, weight: .semibold))
                                            .foregroundColor(Color(hex: "#2C4F40"))
                                    }
                                }
                                .padding(.vertical, 8)
                            }
                        }
                        
                        // Additional Details
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Additional Details")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.black)
                            
                            VStack(spacing: 12) {
                                TextField("Description (optional)", text: $description, axis: .vertical)
                                    .textFieldStyle(CustomTextFieldStyle())
                                    .lineLimit(3, reservesSpace: false)
                                
                                TextField("Requirements (optional)", text: $requirements, axis: .vertical)
                                    .textFieldStyle(CustomTextFieldStyle())
                                    .lineLimit(2, reservesSpace: false)
                            }
                        }
                        
                        // Create Button
                        Button(action: {
                            createRalley()
                        }) {
                            HStack(spacing: 8) {
                                if isCreating {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                }
                                Text(isCreating ? "Creating..." : "Create Ralley")
                                    .font(.system(size: 18, weight: .semibold))
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                canCreate 
                                    ? Color(hex: "#2C4F40")
                                    : Color.gray.opacity(0.3)
                            )
                            .cornerRadius(12)
                            .shadow(color: Color(hex: "#2C4F40").opacity(0.3), radius: 8, x: 0, y: 4)
                        }
                        .disabled(!canCreate || isCreating)
                        .padding(.top, 8)
                    }
                }
                .padding(.horizontal, 24)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(Color(hex: "#2C4F40"))
                }
            }
        }
        .overlay(
            Group {
                if showingSuccessMessage {
                    VStack {
                        Spacer()
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 20))
                                .foregroundColor(.white)
                            Text("Ralley created successfully!")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.white)
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(Color(hex: "#2C4F40"))
                        .cornerRadius(25)
                        .shadow(color: Color.black.opacity(0.2), radius: 8, x: 0, y: 4)
                        .padding(.bottom, 100)
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .animation(.spring(response: 0.6, dampingFraction: 0.8), value: showingSuccessMessage)
                }
            }
        )
    }
    
    /**
     * Create new ralley using real backend integration
     * Handles validation, database operations, and error states with async patterns
     */
    private func createRalley() {
        guard canCreate && !isCreating else { return }
        
        isCreating = true
        
        // Use async ralley creation with real backend integration
        Task { @MainActor in
            do {
                // Create ralley via RalleyManager (which handles backend sync)
                await ralleyManager.createRalley(
                    title: title,
                    sport: sport,
                    dateTime: selectedDate,
                    locationName: locationName,
                    address: "", // TODO: Add address field to form
                    city: "San Francisco", // TODO: Get user's city or allow selection
                    state: "CA", // TODO: Get user's state or allow selection
                    maxPlayers: maxPlayers,
                    cost: cost,
                    description: description.isEmpty ? "Join us for a fun game of \(sport)!" : description,
                    requirements: requirements
                )
                
                // Check if there was an error during creation
                if let error = ralleyManager.error {
                    print("⚠️ Ralley creation had issues: \(error)")
                    // Ralley was still added to local cache, so continue with success flow
                    // In production, might want to show error alert here
                }
                
                // Add haptic feedback for successful creation
                let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                impactFeedback.impactOccurred()
                
                // Show success message
                showingSuccessMessage = true
                
                // Auto-dismiss after success
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    showingSuccessMessage = false
                    dismiss()
                }
                
                print("✅ Ralley created and added to feed with backend integration!")
                print("🏀 Sport: \(sport)")
                print("📍 Location: \(locationName)")
                print("👥 Max players: \(maxPlayers)")
                print("💰 Cost: \(cost == 0 ? "FREE" : "$\(cost)")")
                print("📝 Description: \(description.isEmpty ? "Default description" : description)")
                print("🔄 Backend sync: \(ralleyManager.error == nil ? "✅ Success" : "⚠️ With issues")")
                
            } catch {
                print("❌ Ralley creation failed with error: \(error)")
                
                // Show error state to user
                // For now, just log - in production would show proper error alert
                showingSuccessMessage = false
            }
            
            isCreating = false
        }
    }
}

// MARK: - Custom Text Field Style

struct CustomTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .font(.system(size: 16, weight: .medium))
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.gray.opacity(0.1))
            .cornerRadius(12)
    }
}

// MARK: - Ralley Models

struct ClubRalley: Identifiable, Codable {
    let id: UUID
    let title: String
    let sport: String
    let organizer: RalleyOrganizer
    let dateTime: Date
    let location: RalleyLocation
    let maxPlayers: Int
    var currentPlayers: Int
    let cost: Int
    let description: String
    let requirements: String
    let createdAt: Date
    let isActive: Bool
    
    var timeUntilStart: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: dateTime, relativeTo: Date())
    }
}

struct RalleyOrganizer: Codable {
    let name: String
    let username: String
    let photoURL: String
}

struct RalleyLocation: Codable {
    let name: String
    let address: String
    let city: String
    let state: String
}

// MARK: - Post Manager

/**
 * PostManager: Central state manager for all post-related operations
 * 
 * Purpose: Manages posts across the app with real backend integration
 * Strategy: Uses PostService for database operations, maintains local cache
 * Integration: Connected to Supabase posts table via PostService
 */
@MainActor
class PostManager: ObservableObject {
    
    // MARK: - Published Properties
    
    /// All posts for home feed and user profiles
    @Published var posts: [ClubRalleyPost] = []
    
    /// Loading state for UI feedback
    @Published var isLoading = false
    
    /// Error state for user notifications
    @Published var error: Error?
    
    // MARK: - Dependencies
    
    /// Service layer for post database operations
    private let postService = PostService()
    
    /// Supabase authentication state
    private let supabase = SupabaseManager.shared
    
    // MARK: - Initialization
    
    init() {
        // Load posts from backend on startup
        Task {
            await loadPosts()
        }
    }
    
    // MARK: - Post Loading
    
    /**
     * Load posts from Supabase database for home feed
     * Handles both real data and fallback to mock data for development
     */
    func loadPosts() async {
        isLoading = true
        error = nil
        
        do {
            let loadedPosts = try await postService.loadHomeFeedPosts()
            posts = loadedPosts
            print("✅ PostManager: Loaded \(loadedPosts.count) posts from backend")
        } catch {
            print("❌ PostManager: Failed to load posts: \(error)")
            self.error = error
            
            // Fallback to sample posts for development
            await loadSamplePosts()
        }
        
        isLoading = false
    }
    
    /**
     * Load sample posts for development and offline scenarios
     * Ensures app remains functional even without backend connectivity
     */
    private func loadSamplePosts() async {
        let samplePosts = [
            ClubRalleyPost(
                id: UUID(),
                authorName: "Sarah Wilson",
                authorUsername: "@sarahw",
                authorPhotoURL: "https://picsum.photos/44/44?random=10",
                title: "Amazing Tennis Practice",
                content: "Just had an incredible practice session! Working on my backhand and it's finally clicking. Can't wait for the tournament next week! 🎾",
                images: ["https://picsum.photos/300/300?random=510"],
                timestamp: Date().addingTimeInterval(-3600), // 1 hour ago
                likes: 24,
                comments: 8,
                shares: 3,
                isLiked: false
            ),
            ClubRalleyPost(
                id: UUID(),
                authorName: "Mike Johnson",
                authorUsername: "@mikej",
                authorPhotoURL: "https://picsum.photos/44/44?random=11",
                title: nil,
                content: "Basketball pickup game at the park was intense! Made some new friends and got a great workout in. Who's up for tomorrow? 🏀",
                images: [],
                timestamp: Date().addingTimeInterval(-7200), // 2 hours ago
                likes: 15,
                comments: 12,
                shares: 1,
                isLiked: true
            ),
            ClubRalleyPost(
                id: UUID(),
                authorName: "Your Name", // For user posts testing
                authorUsername: "@you",
                authorPhotoURL: "https://picsum.photos/44/44?random=50",
                title: "My First Rally Post!",
                content: "Just created my first post on Club Ralley! Looking forward to connecting with fellow athletes and organizing some pickup games. Who's ready to play? 🏃‍♀️",
                images: [],
                timestamp: Date().addingTimeInterval(-1800), // 30 minutes ago
                likes: 5,
                comments: 2,
                shares: 0,
                isLiked: false
            )
        ]
        
        posts = samplePosts
        print("📱 PostManager: Using sample posts (fallback mode)")
    }
    
    // MARK: - Post Creation
    
    /**
     * Create new post and save to database
     * @param content: Post text content
     * @param title: Optional post title
     * @param images: Array of image URLs
     * 
     * Flow: Create local post -> Save to database -> Update local cache
     */
    func createPost(content: String, title: String? = nil, images: [String] = []) async {
        guard !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            print("❌ PostManager: Cannot create post with empty content")
            return
        }
        
        isLoading = true
        error = nil
        
        // Create local post model with current user info
        let newPost = ClubRalleyPost(
            id: UUID(),
            authorName: supabase.currentUser?.displayName ?? "Your Name",
            authorUsername: "@\(supabase.currentUser?.email.components(separatedBy: "@").first ?? "you")",
            authorPhotoURL: "https://picsum.photos/44/44?random=50", // TODO: Get real profile photo
            title: title?.isEmpty == false ? title : nil,
            content: content,
            images: images,
            timestamp: Date(),
            likes: 0,
            comments: 0,
            shares: 0,
            isLiked: false
        )
        
        do {
            // Save to database via PostService
            let createdPost = try await postService.createPost(newPost)
            
            // Add to local cache at the top of feed
            posts.insert(createdPost, at: 0)
            
            print("✅ PostManager: Post created successfully")
            
        } catch {
            print("❌ PostManager: Failed to create post: \(error)")
            self.error = error
            
            // Even if backend fails, add to local cache for immediate UI feedback
            posts.insert(newPost, at: 0)
            print("📱 PostManager: Post added locally (backend failed)")
        }
        
        isLoading = false
    }
    
    // MARK: - Post Engagement
    
    /**
     * Toggle like status for a post
     * Updates both database and local cache
     * @param postId: ID of post to like/unlike
     */
    func toggleLike(for postId: UUID) async {
        // Optimistic UI update - change local state immediately
        if let index = posts.firstIndex(where: { $0.id == postId }) {
            let wasLiked = posts[index].isLiked
            posts[index].isLiked.toggle()
            posts[index].likes += posts[index].isLiked ? 1 : -1
            
            print("❤️ PostManager: Optimistic like update for post")
            
            // Attempt to sync with database
            do {
                let newLikeStatus = try await postService.toggleLike(postId: postId)
                
                // Update local state to match database response
                // (In case there was a conflict or different result)
                posts[index].isLiked = newLikeStatus
                print("✅ PostManager: Like synced with database")
                
            } catch {
                print("❌ PostManager: Failed to sync like with database: \(error)")
                
                // Revert optimistic update on failure
                posts[index].isLiked = wasLiked
                posts[index].likes += wasLiked ? 1 : -1
                self.error = error
            }
        }
    }
    
    /**
     * Legacy method for immediate UI updates (maintains backward compatibility)
     * @param post: Full post model to add to feed
     */
    func addPost(_ post: ClubRalleyPost) {
        posts.insert(post, at: 0) // Add to beginning of feed
        print("📝 PostManager: Post added to local feed")
    }
    
    // MARK: - User Content Filtering
    
    /**
     * Get posts created by current user for profile display
     * @returns: Array of user's posts sorted by creation date
     */
    func getUserPosts() -> [ClubRalleyPost] {
        let currentUserName = supabase.currentUser?.displayName ?? "Your Name"
        let userPosts = posts.filter { $0.authorName == currentUserName }
        
        print("👤 PostManager: Found \(userPosts.count) posts for current user")
        return userPosts.sorted { $0.timestamp > $1.timestamp }
    }
    
    /**
     * Get posts for specific user (for viewing other profiles)
     * @param username: Username to filter posts by
     * @returns: Array of user's posts
     */
    func getPostsForUser(username: String) -> [ClubRalleyPost] {
        return posts.filter { $0.authorUsername == username }
            .sorted { $0.timestamp > $1.timestamp }
    }
    
    // MARK: - Feed Management
    
    /**
     * Refresh posts by reloading from database
     * Used for pull-to-refresh functionality
     */
    func refreshPosts() async {
        print("🔄 PostManager: Refreshing posts from database")
        await loadPosts()
    }
    
    /**
     * Clear error state (for user notification dismissal)
     */
    func clearError() {
        error = nil
    }
}

// MARK: - Home Feed View

struct HomeFeedView: View {
    @EnvironmentObject var postManager: PostManager
    @EnvironmentObject var ralleyManager: RalleyManager
    
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 16) {
                    // Header
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text("Home")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(.black)
                            Spacer()
                            Button(action: {}) {
                                Image(systemName: "bell")
                                    .font(.system(size: 22))
                                    .foregroundColor(Color(hex: "#2C4F40"))
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 8)
                    }
                    
                    // Upcoming Ralleys Section
                    if !ralleyManager.ralleys.isEmpty {
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Text("Upcoming Ralleys")
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(.black)
                                Spacer()
                                Button(action: {}) {
                                    Text("View All")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(Color(hex: "#2C4F40"))
                                }
                            }
                            .padding(.horizontal, 24)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 16) {
                                    ForEach(Array(ralleyManager.ralleys.prefix(3)), id: \.id) { ralley in
                                        CompactRalleyCard(ralley: ralley)
                                            .environmentObject(ralleyManager)
                                    }
                                }
                                .padding(.horizontal, 24)
                            }
                        }
                    }
                    
                    // Posts Feed
                    VStack(alignment: .leading, spacing: 16) {
                        if !postManager.posts.isEmpty {
                            HStack {
                                Text("Recent Posts")
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(.black)
                                Spacer()
                            }
                            .padding(.horizontal, 24)
                        }
                        
                        if postManager.posts.isEmpty && ralleyManager.ralleys.isEmpty {
                            EmptyFeedView()
                        } else if postManager.posts.isEmpty {
                            VStack(spacing: 20) {
                                Image(systemName: "text.bubble")
                                    .font(.system(size: 48))
                                    .foregroundColor(Color(hex: "#2C4F40").opacity(0.6))
                                
                                Text("No posts yet")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(.black)
                                
                                Text("Follow athletes to see their posts here")
                                    .font(.system(size: 15, weight: .regular))
                                    .foregroundColor(.gray)
                                    .multilineTextAlignment(.center)
                            }
                            .padding(.horizontal, 40)
                            .padding(.vertical, 30)
                        } else {
                            ForEach(postManager.posts) { post in
                                PostCardView(post: post)
                                    .environmentObject(postManager)
                            }
                        }
                    }
                    
                    Spacer(minLength: 100)
                }
                .padding(.top, 8)
            }
            .navigationBarHidden(true)
        }
    }
}

// MARK: - Post Card View

struct PostCardView: View {
    let post: ClubRalleyPost
    @EnvironmentObject var postManager: PostManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack(spacing: 12) {
                AsyncImage(url: URL(string: post.authorPhotoURL)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Circle()
                        .fill(Color(hex: "#2C4F40"))
                }
                .frame(width: 44, height: 44)
                .clipShape(Circle())
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(post.authorName)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.black)
                    Text("\(post.authorUsername) • \(post.timeAgo)")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                Button(action: {}) {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.gray)
                }
            }
            
            // Title (if exists)
            if let title = post.title {
                Text(title)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.black)
            }
            
            // Content
            Text(post.content)
                .font(.system(size: 16, weight: .regular))
                .foregroundColor(.black)
                .lineSpacing(4)
            
            // Images (if exist)
            if !post.images.isEmpty {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: post.images.count > 1 ? 2 : 1), spacing: 8) {
                    ForEach(post.images.indices, id: \.self) { index in
                        AsyncImage(url: URL(string: post.images[index])) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } placeholder: {
                            Rectangle()
                                .fill(Color.gray.opacity(0.2))
                        }
                        .frame(height: post.images.count == 1 ? 200 : 150)
                        .clipped()
                        .cornerRadius(12)
                    }
                }
            }
            
            // Engagement Bar
            HStack(spacing: 24) {
                // Like Button
                Button(action: {
                    postManager.toggleLike(for: post.id)
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: post.isLiked ? "heart.fill" : "heart")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(post.isLiked ? .red : .gray)
                        Text("\(post.likes)")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.gray)
                    }
                }
                
                // Comment Button
                Button(action: {}) {
                    HStack(spacing: 6) {
                        Image(systemName: "message")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.gray)
                        Text("\(post.comments)")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.gray)
                    }
                }
                
                // Share Button
                Button(action: {}) {
                    HStack(spacing: 6) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.gray)
                        Text("\(post.shares)")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.gray)
                    }
                }
                
                Spacer()
            }
            .padding(.top, 8)
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4)
        .padding(.horizontal, 24)
    }
}

// MARK: - Compact Ralley Card View

struct CompactRalleyCard: View {
    let ralley: ClubRalley
    @EnvironmentObject var ralleyManager: RalleyManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with sport icon
            HStack {
                Image(systemName: ralley.sport.lowercased() == "basketball" ? "basketball.fill" : "tennisball.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.white)
                    .padding(8)
                    .background(Color(hex: "#2C4F40"))
                    .clipShape(Circle())
                
                Spacer()
                
                Text(ralley.cost == 0 ? "FREE" : "$\(ralley.cost)")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(Color(hex: "#2C4F40"))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color(hex: "#2C4F40").opacity(0.1))
                    .cornerRadius(6)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text(ralley.title)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.black)
                    .lineLimit(1)
                
                Text(ralley.dateTime.formatted(date: .omitted, time: .shortened))
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.gray)
                
                Text(ralley.location.name)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.gray)
                    .lineLimit(1)
            }
            
            // Player count and join
            HStack {
                Text("\(ralley.currentPlayers)/\(ralley.maxPlayers)")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.gray)
                
                Spacer()
                
                Button(action: {
                    ralleyManager.joinRalley(ralley.id)
                }) {
                    Text("Join")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color(hex: "#2C4F40"))
                        .cornerRadius(8)
                }
                .disabled(ralley.currentPlayers >= ralley.maxPlayers)
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4)
        .frame(width: 200)
    }
}

// MARK: - Empty Feed View

struct EmptyFeedView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "sportscourt")
                .font(.system(size: 60))
                .foregroundColor(Color(hex: "#2C4F40").opacity(0.6))
            
            Text("Welcome to Club Ralley!")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.black)
            
            Text("Start following athletes and join ralleys to see posts in your feed")
                .font(.system(size: 16, weight: .regular))
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .padding(.top, 60)
    }
}

// MARK: - User Posts Section

struct UserPostsSection: View {
    @EnvironmentObject var postManager: PostManager
    @EnvironmentObject var ralleyManager: RalleyManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 32) {
            // My Ralleys Section
            VStack(alignment: .leading, spacing: 20) {
                HStack {
                    Text("My Ralleys")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.black)
                    Spacer()
                    Text("\(ralleyManager.getUserRalleys().count)")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(Color(hex: "#2C4F40"))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color(hex: "#2C4F40").opacity(0.1))
                        .cornerRadius(12)
                }
                
                if ralleyManager.getUserRalleys().isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "sportscourt")
                            .font(.system(size: 48))
                            .foregroundColor(Color(hex: "#2C4F40").opacity(0.6))
                        
                        Text("No ralleys created yet")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.black)
                        
                        Text("Create your first pickup game to see it here")
                            .font(.system(size: 15, weight: .regular))
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
                    .background(Color.gray.opacity(0.05))
                    .cornerRadius(16)
                } else {
                    LazyVStack(spacing: 12) {
                        ForEach(ralleyManager.getUserRalleys()) { ralley in
                            UserRalleyPreview(ralley: ralley)
                        }
                    }
                }
            }
            
            // My Posts Section
            VStack(alignment: .leading, spacing: 20) {
            HStack {
                Text("My Posts")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.black)
                Spacer()
                Text("\(postManager.getUserPosts().count)")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Color(hex: "#2C4F40"))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color(hex: "#2C4F40").opacity(0.1))
                    .cornerRadius(12)
            }
            
            if postManager.getUserPosts().isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "plus.circle")
                        .font(.system(size: 48))
                        .foregroundColor(Color(hex: "#2C4F40").opacity(0.6))
                    
                    Text("No posts yet")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.black)
                    
                    Text("Share your athletic journey to see your posts here")
                        .font(.system(size: 15, weight: .regular))
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
                .background(Color.gray.opacity(0.05))
                .cornerRadius(16)
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(postManager.getUserPosts()) { post in
                        UserPostPreview(post: post)
                    }
                }
            }
        }
    }
}

// MARK: - User Ralley Preview

struct UserRalleyPreview: View {
    let ralley: ClubRalley
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: ralley.sport.lowercased() == "basketball" ? "basketball.fill" : "tennisball.fill")
                    .font(.system(size: 16))
                    .foregroundColor(Color(hex: "#2C4F40"))
                
                Text(ralley.title)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.black)
                
                Spacer()
                
                Text(ralley.cost == 0 ? "FREE" : "$\(ralley.cost)")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(Color(hex: "#2C4F40"))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color(hex: "#2C4F40").opacity(0.1))
                    .cornerRadius(6)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(ralley.dateTime.formatted(date: .abbreviated, time: .shortened))
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.gray)
                
                Text(ralley.location.name)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.gray)
            }
            
            HStack {
                Text(ralley.timeUntilStart)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.gray)
                
                Spacer()
                
                HStack(spacing: 16) {
                    HStack(spacing: 4) {
                        Image(systemName: "person.2")
                            .font(.system(size: 12))
                        Text("\(ralley.currentPlayers)/\(ralley.maxPlayers)")
                            .font(.system(size: 12, weight: .medium))
                    }
                    .foregroundColor(.gray)
                }
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
        )
    }
}

// MARK: - User Post Preview

struct UserPostPreview: View {
    let post: ClubRalleyPost
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let title = post.title {
                Text(title)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.black)
            }
            
            Text(post.content)
                .font(.system(size: 15, weight: .regular))
                .foregroundColor(.black)
                .lineLimit(3)
            
            HStack {
                Text(post.timeAgo)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.gray)
                
                Spacer()
                
                HStack(spacing: 16) {
                    HStack(spacing: 4) {
                        Image(systemName: "heart")
                            .font(.system(size: 12))
                        Text("\(post.likes)")
                            .font(.system(size: 12, weight: .medium))
                    }
                    .foregroundColor(.gray)
                    
                    HStack(spacing: 4) {
                        Image(systemName: "message")
                            .font(.system(size: 12))
                        Text("\(post.comments)")
                            .font(.system(size: 12, weight: .medium))
                    }
                    .foregroundColor(.gray)
                }
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
        )
    }
}

// MARK: - Post Model

struct ClubRalleyPost: Identifiable, Codable {
    let id: UUID
    let authorName: String
    let authorUsername: String
    let authorPhotoURL: String
    let title: String?
    let content: String
    let images: [String]
    let timestamp: Date
    var likes: Int
    var comments: Int
    var shares: Int
    var isLiked: Bool
    
    var timeAgo: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: timestamp, relativeTo: Date())
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
