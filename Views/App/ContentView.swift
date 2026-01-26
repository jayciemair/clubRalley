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
            VStack(spacing: 20) {
                Image(systemName: "figure.run.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(Color(hex: "#2C4F40"))
                
                Text("Welcome to Club Ralley!")
                    .font(.title.bold())
                    .foregroundColor(Color(hex: "#2C4F40"))
                
                Text("GFTO - Get the F*** Outside")
                    .font(.title3)
                    .foregroundColor(Color(hex: "#2C4F40"))
                
                Text("Your athletic network awaits.")
                    .font(.subheadline)
                    .foregroundColor(Color(hex: "#666666"))
            }
            .padding()
            .tabItem {
                Image(systemName: selectedTab == .home ? "house.fill" : "house")
                Text("Home")
            }
            .tag(MainTab.home)
            
            VStack(spacing: 20) {
                Image(systemName: "magnifyingglass.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(Color(hex: "#2C4F40"))
                
                Text("League Finder")
                    .font(.title.bold())
                    .foregroundColor(Color(hex: "#2C4F40"))
                
                Text("Find leagues and activities near you")
                    .font(.subheadline)
                    .foregroundColor(Color(hex: "#666666"))
                    .multilineTextAlignment(.center)
            }
            .padding()
            .tabItem {
                Image(systemName: "magnifyingglass")
                Text("League Finder")
            }
            .tag(MainTab.leagueFinder)
            
            VStack(spacing: 20) {
                Image(systemName: "camera.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(Color(hex: "#2C4F40"))
                
                Text("Post")
                    .font(.title.bold())
                    .foregroundColor(Color(hex: "#2C4F40"))
                
                Text("Share your athletic journey")
                    .font(.subheadline)
                    .foregroundColor(Color(hex: "#666666"))
                    .multilineTextAlignment(.center)
            }
            .padding()
            .tabItem {
                Image(systemName: selectedTab == .post ? "camera.fill" : "camera")
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
            
            // Temporary: Simple Profile placeholder until ProfileView is added to target
            NavigationStack {
                ScrollView {
                    VStack(spacing: 20) {
                        // Profile Photo
                        AsyncImage(url: URL(string: "https://picsum.photos/120/120?random=1")) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } placeholder: {
                            Circle()
                                .fill(Color(hex: "#2C4F40"))
                        }
                        .frame(width: 120, height: 120)
                        .clipShape(Circle())
                        
                        // User Info
                        VStack(spacing: 8) {
                            Text("Your Name")
                                .font(.title.bold())
                                .foregroundColor(Color(hex: "#2C4F40"))
                            
                            Text("Tennis Player • Bucknell University")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                            
                            Text("Love staying active and making new friends!")
                                .font(.body)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                        
                        // Stats
                        HStack(spacing: 30) {
                            VStack {
                                Text("156")
                                    .font(.title2.bold())
                                Text("Followers")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                            VStack {
                                Text("89")
                                    .font(.title2.bold()) 
                                Text("Following")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                            VStack {
                                Text("23")
                                    .font(.title2.bold())
                                Text("Ralleys")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                        }
                        .padding()
                        
                        // Teams Section
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Teams")
                                .font(.headline)
                                .padding(.horizontal)
                            
                            VStack(spacing: 8) {
                                HStack {
                                    Image(systemName: "tennisball.fill")
                                        .foregroundColor(Color(hex: "#2C4F40"))
                                    Text("Varsity Tennis")
                                    Spacer()
                                    Text("D1")
                                        .font(.caption)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(Color(hex: "#2C4F40").opacity(0.1))
                                        .cornerRadius(8)
                                }
                                .padding(.horizontal)
                                
                                HStack {
                                    Image(systemName: "basketball.fill")
                                        .foregroundColor(Color(hex: "#2C4F40"))
                                    Text("Intramural Basketball")
                                    Spacer()
                                    Text("Intramural")
                                        .font(.caption)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(Color(hex: "#2C4F40").opacity(0.1))
                                        .cornerRadius(8)
                                }
                                .padding(.horizontal)
                            }
                        }
                        
                        Spacer(minLength: 100)
                    }
                    .padding()
                }
                .navigationTitle("Profile")
                .navigationBarTitleDisplayMode(.inline)
            }
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
        if ![.home, .leagueFinder, .teams, .profile].contains(selectedTab) {
            selectedTab = .home
        }
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
