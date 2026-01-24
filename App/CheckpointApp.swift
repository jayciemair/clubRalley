//
//  CheckpointApp.swift
//  Checkpoint
//

import SwiftUI

@main
struct CheckpointApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    let persistenceController = PersistenceController.shared
    @StateObject var onboardingFlowController = OnboardingFlowController()  // Shared across entire app
    @StateObject var storeManager = StoreManager.shared  // Initialize StoreManager
    @StateObject var versionService = AppVersionService.shared  // Version check service
    @StateObject var appearanceManager = AppearanceManager.shared  // Appearance mode manager
    @State var selectedTab: Int = -1  // -1 means no override, let ContentView use its default
    @State var showAnalytics = false



    var body: some Scene {
        WindowGroup {
            ZStack {
                ContentView(selectedTab: $selectedTab, showAnalytics: $showAnalytics)
                    .environment(\.managedObjectContext, persistenceController.container.viewContext)
                    .environmentObject(onboardingFlowController)
                    .environmentObject(storeManager)
                    .preferredColorScheme(appearanceManager.colorScheme)  // Apply user's appearance preference
                    .onAppear {
                        // Fix alert button colors for system alerts
                        UIView.appearance(whenContainedInInstancesOf: [UIAlertController.self]).tintColor = .systemBlue
                    }
                    .onOpenURL { url in
                        handleQuickAction(from: url)
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
    
    func handleQuickAction(from url: URL) {
        guard url.scheme == "getoverhim" else { return }

        switch url.host {
        case "endSession":
            // Post notification to end session
            NotificationCenter.default.post(
                name: NSNotification.Name("EndCheckpointSession"),
                object: nil
            )
        case "viewSession", "openMain":
            // Navigate to main tab (assuming it's tab index 2)
            selectedTab = 2
            showAnalytics = false
        case "moment", "easy", "problem":
            // All three messages navigate to home - showing the user what they'd be giving up
            selectedTab = 0
        default:
            break
        }
    }
}
