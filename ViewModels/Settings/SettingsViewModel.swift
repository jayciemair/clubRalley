//
//  SettingsViewModel.swift
//  Checkpoint
//
//  ViewModel for Settings screen following MVVM pattern
//

import SwiftUI
import Combine
import StoreKit

@MainActor
class SettingsViewModel: ObservableObject {

    // MARK: - Shared Instance
    static let shared = SettingsViewModel()

    // MARK: - Published Properties

    /// Controls feature request flow presentation
    @Published var showFeatureRequest = false

    /// Controls rating request sheet presentation
    @Published var showRatingRequestSheet = false

    /// Controls rating celebration HUD presentation
    @Published var showRatingCelebration = false

    /// Whether user is authenticated (computed from AuthenticationService)
    @Published var isAuthenticated = false

    // MARK: - Private Properties

    private let authService = AuthenticationService.shared
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization

    init() {
        observeAuthState()
    }

    // MARK: - Public Methods

    /// Requests App Store review after celebration
    func requestAppStoreReview() {
        if let scene = UIApplication.shared.connectedScenes.first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene {
            SKStoreReviewController.requestReview(in: scene)
        }
    }

    // MARK: - Private Methods

    private func observeAuthState() {
        // Observe authentication state changes
        authService.$authState
            .map { authState in
                if case .authenticated = authState {
                    return true
                }
                return false
            }
            .receive(on: DispatchQueue.main)
            .assign(to: &$isAuthenticated)
    }
}
