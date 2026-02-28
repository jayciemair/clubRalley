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
    @State private var needsReAuth = false

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
                        .environmentObject(ServiceContainer.shared)
                        .preferredColorScheme(appearanceManager.colorScheme)
                        .onAppear {
                            UIView.appearance(whenContainedInInstancesOf: [UIAlertController.self]).tintColor = UIColor.systemBlue
                        }
                        .onOpenURL { url in
                            handleDeepLink(from: url)
                        }
                } else {
                    // Not logged in - show onboarding (or re-auth sign-in only)
                    ClubRalleyOnboardingCoordinator(reAuthOnly: needsReAuth) {
                        // Called when onboarding completes
                        withAnimation(.easeInOut(duration: 0.5)) {
                            UserDefaults.standard.set(true, forKey: "hasCompletedClubRalleyOnboarding")
                            needsReAuth = false
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
                    // No Supabase session — user must re-authenticate
                    // Without a real session, auth.uid() is NULL server-side
                    // and all writes (create ralley, post, etc.) fail with RLS errors
                    print("🟡 App Launch - No Supabase session, redirecting to sign-in")
                    await MainActor.run {
                        needsReAuth = true
                        hasCompletedOnboarding = false
                    }
                }

                // Register for push notifications and start listening for in-app notifications
                if supabaseManager.isAuthenticated {
                    PushNotificationService.shared.requestPermissionAndRegister()
                    await InAppNotificationService.shared.startListening()
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
                    await PushNotificationService.shared.refreshPermissionStatus()
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("UserDidLogout"))) { _ in
                // Deactivate push token and stop listening before clearing session
                Task {
                    await PushNotificationService.shared.deactivateCurrentToken()
                    await InAppNotificationService.shared.stopListening()
                }
                // User logged out - show onboarding
                withAnimation(.easeInOut(duration: 0.3)) {
                    hasCompletedOnboarding = false
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("ClubRalleyPushTap"))) { notification in
                // Handle push notification tap — navigate to the right content
                guard let userInfo = notification.userInfo,
                      let type = userInfo["type"] as? String else { return }

                switch type {
                case "ralley_join", "ralley_invite", "ralley_reminder":
                    if let ralleyIdStr = userInfo["ralley_id"] as? String,
                       let _ = UUID(uuidString: ralleyIdStr) {
                        selectedTab = .ralleys
                        // Post deep link for the ralley detail view to handle
                        NotificationCenter.default.post(
                            name: NSNotification.Name("ClubRalleyDeepLink"),
                            object: nil,
                            userInfo: userInfo
                        )
                    }
                case "new_follower":
                    selectedTab = .profile
                case "like", "comment":
                    if let postIdStr = userInfo["post_id"] as? String,
                       let _ = UUID(uuidString: postIdStr) {
                        selectedTab = .home
                        NotificationCenter.default.post(
                            name: NSNotification.Name("ClubRalleyDeepLink"),
                            object: nil,
                            userInfo: userInfo
                        )
                    }
                default:
                    selectedTab = .home
                }
            }
        }
    }

    private var splashView: some View {
        ZStack {
            Color(red: 58/255, green: 84/255, blue: 65/255)
                .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 2) {
                Text("Ralley")
                    .font(.custom("Chillax-Bold", size: 52))
                    .foregroundColor(.white)
                    .kerning(-0.5)

                Text("the athletes' network.")
                    .font(.custom("Chillax-Medium", size: 13))
                    .foregroundColor(.white)
                    .padding(.leading, 2)
            }
            .offset(y: 40)
        }
        .preferredColorScheme(.dark)
        .statusBarHidden(true)
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
        case "find-ralleys", "ralleys", "discover", "map":
            selectedTab = .ralleys
        case "post", "create":
            selectedTab = .post
        case "teams":
            selectedTab = .teams
        case "profile":
            selectedTab = .profile
        default:
            // Default to home for unknown deep links
            selectedTab = .home
        }
    }
}
