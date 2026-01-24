//
//  AppVersionService.swift
//  Checkpoint
//
//  Service for checking app version and enforcing force updates
//

import Foundation
import SwiftUI
import Supabase

/// Configuration model from Supabase
struct AppVersionConfig: Codable {
    let id: UUID
    let minimumVersion: String
    let latestVersion: String
    let forceUpdateEnabled: Bool
    let notes: String?
    let createdAt: Date
    let updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case minimumVersion = "minimum_version"
        case latestVersion = "latest_version"
        case forceUpdateEnabled = "force_update_enabled"
        case notes
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

/// Result of version check
struct VersionCheckResult {
    let shouldForceUpdate: Bool
    let latestVersion: String
    let currentVersion: String
}

/// Service for managing app version checks and force updates
@MainActor
class AppVersionService: ObservableObject {

    static let shared = AppVersionService()

    @Published var shouldShowForceUpdate = false
    @Published var latestVersion: String?

    private let supabaseClient: SupabaseClient

    private init() {
        self.supabaseClient = SupabaseClient(
            supabaseURL: URL(string: AppConfig.Supabase.projectURL)!,
            supabaseKey: AppConfig.Supabase.anonKey
        )
    }

    // MARK: - Public Methods

    /// Check if force update is required
    /// Call this on app launch or when app becomes active
    func checkForForceUpdate() async throws -> VersionCheckResult {
        let config = try await fetchVersionConfig()
        let currentVersion = getCurrentAppVersion()

        let shouldForce = config.forceUpdateEnabled &&
                         isVersion(currentVersion, lessThan: config.minimumVersion)

        self.shouldShowForceUpdate = shouldForce
        self.latestVersion = config.latestVersion

        return VersionCheckResult(
            shouldForceUpdate: shouldForce,
            latestVersion: config.latestVersion,
            currentVersion: currentVersion
        )
    }

    /// Open the App Store page for Checkpoint
    func openAppStore() {
        let appStoreURL = "https://apps.apple.com/app/checkpoint/id6754121521"

        if let url = URL(string: appStoreURL) {
            UIApplication.shared.open(url)
        }
    }

    // MARK: - Private Methods

    private func fetchVersionConfig() async throws -> AppVersionConfig {
        let response: [AppVersionConfig] = try await supabaseClient
            .from("app_version_config")
            .select()
            .limit(1)
            .execute()
            .value

        guard let config = response.first else {
            throw AppVersionError.configNotFound
        }

        return config
    }

    private func getCurrentAppVersion() -> String {
        return Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    }

    /// Compare two semantic versions (e.g., "1.2.3")
    /// Returns true if version1 < version2
    private func isVersion(_ version1: String, lessThan version2: String) -> Bool {
        let v1Components = version1.split(separator: ".").compactMap { Int($0) }
        let v2Components = version2.split(separator: ".").compactMap { Int($0) }

        let maxLength = max(v1Components.count, v2Components.count)

        for i in 0..<maxLength {
            let v1 = i < v1Components.count ? v1Components[i] : 0
            let v2 = i < v2Components.count ? v2Components[i] : 0

            if v1 < v2 {
                return true
            } else if v1 > v2 {
                return false
            }
        }

        return false // Versions are equal
    }
}

// MARK: - Errors

enum AppVersionError: LocalizedError {
    case configNotFound
    case invalidVersion

    var errorDescription: String? {
        switch self {
        case .configNotFound:
            return "Version configuration not found"
        case .invalidVersion:
            return "Invalid version format"
        }
    }
}
