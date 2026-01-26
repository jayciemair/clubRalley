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
    @StateObject var storeManager = StoreManager.shared  // Initialize StoreManager
    @StateObject var versionService = AppVersionService.shared  // Version check service
    @StateObject var appearanceManager = AppearanceManager.shared  // Appearance mode manager
    @State var selectedTab: MainTab = .home  // Default to home tab



    var body: some Scene {
        WindowGroup {
            ZStack {
                ContentView(selectedTab: $selectedTab)
                    .environment(\.managedObjectContext, persistenceController.container.viewContext)
                    .environmentObject(onboardingFlowController)
                    .environmentObject(storeManager)
                    .preferredColorScheme(appearanceManager.colorScheme)  // Apply user's appearance preference
                    .onAppear {
                        // Fix alert button colors for system alerts
                        UIView.appearance(whenContainedInInstancesOf: [UIAlertController.self]).tintColor = UIColor.systemBlue
                    }
                    .onOpenURL { url in
                        handleDeepLink(from: url)
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
                // PHASED INITIALIZATION: Fire and forget - don't block UI
                // SDKs initialize in background after first frame renders
                AppInitializer.shared.initialize()

                // Check for force updates (also non-blocking)
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
        case "league-finder", "discover":
            selectedTab = .leagueFinder
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
