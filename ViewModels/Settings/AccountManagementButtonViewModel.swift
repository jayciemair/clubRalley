//
//  AccountManagementButtonViewModel.swift
//  Checkpoint
//
//  ViewModel for AccountManagementButton
//

import SwiftUI
import Combine

@MainActor
class AccountManagementButtonViewModel: ObservableObject {

    // MARK: - Published Properties

    @Published var showOptions = false
    @Published var showSignOutConfirmation = false
    @Published var signOutConfirmationText = ""
    @Published var showDeleteConfirmation = false
    @Published var deleteConfirmationText = ""
    @Published var isDeleting = false

    // MARK: - Private Properties

    private let authService = AuthenticationService.shared

    // MARK: - Computed Properties

    var canAccess: Bool { true }

    var iconOpacity: Double { 1.0 }

    var availabilityText: String { "Manage your account" }

    @Published var showUnavailableAlert = false

    var unavailableReason: String { "" }

    var canSignOut: Bool {
        signOutConfirmationText.lowercased().replacingOccurrences(of: " ", with: "") == "signout"
    }

    var canDelete: Bool {
        deleteConfirmationText.lowercased() == "delete"
    }

    // MARK: - Public Methods

    func handleButtonTap() {
        withAnimation(.easeInOut(duration: 0.2)) {
            showOptions.toggle()
        }
    }

    func signOut() async {
        print("[debugFlowTransition] 🔘 AccountManagementButtonViewModel.signOut() CALLED")
        let normalizedText = signOutConfirmationText.lowercased().replacingOccurrences(of: " ", with: "")
        print("[debugFlowTransition] 🔘 Confirmation text valid: \(normalizedText == "signout")")

        if normalizedText == "signout" {
            do {
                print("[debugFlowTransition] 🔘 Calling authService.signOut()...")
                try await authService.signOut()
                print("[debugFlowTransition] ✅ authService.signOut() completed successfully")
            } catch {
                print("[debugFlowTransition] ❌ authService.signOut() failed: \(error.localizedDescription)")
            }
        }
        signOutConfirmationText = ""
    }

    func cancelSignOut() {
        signOutConfirmationText = ""
    }

    func deleteAccount() async {
        guard canDelete else { return }

        isDeleting = true
        do {
            try await authService.deleteAccount()
        } catch {
            print("[AccountManagement] ❌ Delete account failed: \(error.localizedDescription)")
        }
        isDeleting = false
        deleteConfirmationText = ""
    }

    func cancelDelete() {
        deleteConfirmationText = ""
    }
}
