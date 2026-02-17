//
//  ClubRalleyApp.swift
//  Club Ralley
//

import SwiftUI

@main
struct ClubRalleyApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    let persistenceController = PersistenceController.shared
    @StateObject var onboardingFlowController = OnboardingFlowController()  // Shared across entire app
    @ObservedObject var storeManager = StoreManager.shared  // Initialize StoreManager
    @ObservedObject var versionService = AppVersionService.shared  // Version check service
    @ObservedObject var appearanceManager = AppearanceManager.shared  // Appearance mode manager
    @State var selectedTab: MainTab = .home  // Default to home tab

    // Track if Club Ralley onboarding has been completed
    // Using @State instead of @AppStorage so we can control when it's read
    @State private var hasCompletedOnboarding = false

    init() {
        print("🔵🔵🔵 DEBUG APP_INIT - THIS SHOULD APPEAR IN CONSOLE 🔵🔵🔵")
        // Read onboarding state from UserDefaults
        let completed = UserDefaults.standard.bool(forKey: "hasCompletedClubRalleyOnboarding")
        _hasCompletedOnboarding = State(initialValue: completed)
        print("🚀 App init - hasCompletedOnboarding: \(completed)")

        // Force initialize SupabaseManager to see debug prints
        print("🔵🔵🔵 DEBUG - About to access SupabaseManager.shared 🔵🔵🔵")
        let _ = SupabaseManager.shared
        print("🔵🔵🔵 DEBUG - SupabaseManager.shared accessed 🔵🔵🔵")
    }

    // SupabaseManager for session management
    @ObservedObject private var supabaseManager = SupabaseManager.shared

    // State for checking session on launch
    @State private var isCheckingSession = true

    var body: some Scene {
        WindowGroup {
            ZStack {
                if isCheckingSession {
                    // Show splash while checking auth session
                    splashView
                } else if hasCompletedOnboarding {
                    // User completed onboarding - show main app
                    ContentView(selectedTab: $selectedTab)
                        .environment(\.managedObjectContext, persistenceController.container.viewContext)
                        .environmentObject(onboardingFlowController)
                        .environmentObject(storeManager)
                        .preferredColorScheme(appearanceManager.colorScheme)
                        .onAppear {
                            UIView.appearance(whenContainedInInstancesOf: [UIAlertController.self]).tintColor = UIColor.systemBlue
                        }
                        .onOpenURL { url in
                            handleDeepLink(from: url)
                        }
                } else {
                    // Not logged in - show onboarding
                    ClubRalleyOnboardingCoordinator {
                        // Called when onboarding completes
                        withAnimation(.easeInOut(duration: 0.5)) {
                            UserDefaults.standard.set(true, forKey: "hasCompletedClubRalleyOnboarding")
                            hasCompletedOnboarding = true
                        }
                    }
                    .transition(.opacity)
                }

                // Force update overlay
                if versionService.shouldShowForceUpdate {
                    ForceUpdateView(
                        latestVersion: versionService.latestVersion ?? "Latest",
                        onUpdateTapped: {
                            versionService.openAppStore()
                        }
                    )
                    .transition(.opacity)
                }
            }
            .task {
                // DEBUG: Log onboarding state
                print("🚀 App Launch - hasCompletedOnboarding: \(hasCompletedOnboarding)")
                print("🚀 App Launch - UserDefaults value: \(UserDefaults.standard.bool(forKey: "hasCompletedClubRalleyOnboarding"))")

                // Try to restore existing session
                let hasSession = await supabaseManager.restoreSession()
                print("🚀 App Launch - hasSession: \(hasSession)")

                if hasSession && hasCompletedOnboarding {
                    // Session restored - enrich with profile data if available
                    if let userId = supabaseManager.currentUser?.id {
                        if let profile = try? await supabaseManager.fetchUserProfile(userId: userId) {
                            await MainActor.run {
                                supabaseManager.currentUser = SupabaseUser(
                                    id: profile.id,
                                    email: profile.email,
                                    firstName: profile.firstName,
                                    lastName: profile.lastName
                                )
                            }
                        }
                    }
                } else if !hasSession && hasCompletedOnboarding {
                    // No Supabase session but user completed onboarding
                    // Restore auth state from saved profile so the app works
                    if let savedProfile = SavedUserProfile.loadFromStorage() {
                        print("🟡 App Launch - Restoring auth from saved profile: \(savedProfile.firstName) \(savedProfile.lastName)")
                        await MainActor.run {
                            supabaseManager.isAuthenticated = true
                            supabaseManager.currentUser = SupabaseUser(
                                id: savedProfile.id,
                                email: savedProfile.email,
                                firstName: savedProfile.firstName,
                                lastName: savedProfile.lastName
                            )
                        }
                        print("🟢 App Launch - Auth restored from saved profile, userId: \(savedProfile.id)")
                    }
                }

                await MainActor.run {
                    isCheckingSession = false
                    print("🚀 App Launch - isCheckingSession set to false, will show: \(hasCompletedOnboarding ? "ContentView" : "Onboarding")")
                }

                // PHASED INITIALIZATION: Fire and forget - don't block UI
                AppInitializer.shared.initialize()

                // Check for force updates (non-blocking)
                Task.detached(priority: .utility) {
                    await self.checkForUpdates()
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
                // Re-check when app comes to foreground
                Task {
                    await checkForUpdates()
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("UserDidLogout"))) { _ in
                // User logged out - show onboarding
                withAnimation(.easeInOut(duration: 0.3)) {
                    hasCompletedOnboarding = false
                }
            }
        }
    }

    private var splashView: some View {
        ZStack {
            Color.white.ignoresSafeArea()

            VStack(spacing: 24) {
                ZStack {
                    Circle()
                        .fill(Color(hex: "#2C4F40"))
                        .frame(width: 100, height: 100)

                    Image(systemName: "figure.run")
                        .font(.system(size: 44, weight: .semibold))
                        .foregroundColor(.white)
                }

                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: Color(hex: "#2C4F40")))
            }
        }
    }

    private func checkForUpdates() async {
        do {
            _ = try await versionService.checkForForceUpdate()
        } catch {
            // Silently fail - don't block app if version check fails
        }
    }

    func handleDeepLink(from url: URL) {
        // Handle Club Ralley deep links
        if let deepLink = DeepLink(url: url) {
            selectedTab = deepLink.type.targetTab

            // Post notification for navigation handling
            NotificationCenter.default.post(
                name: NSNotification.Name("ClubRalleyDeepLink"),
                object: deepLink
            )
            return
        }

        // Handle custom URL schemes for Club Ralley
        guard url.scheme == "clubralley" else { return }

        switch url.host {
        case "home":
            selectedTab = .home
        case "find-ralleys", "ralleys", "discover":
            selectedTab = .findRalleys
        case "post", "create":
            selectedTab = .post
        case "teams", "ralleys":
            selectedTab = .teams
        case "profile":
            selectedTab = .profile
        default:
            // Default to home for unknown deep links
            selectedTab = .home
        }
    }
}
