//
//  WebsiteBlockRequestViewModel.swift
//  Checkpoint
//
//  ViewModel for website block request form
//

import SwiftUI
import Combine

@MainActor
class WebsiteBlockRequestViewModel: ObservableObject {

    // MARK: - Published Properties

    /// Domain text input
    @Published var domain: String = ""

    /// Success message visibility
    @Published var showSuccessMessage = false

    /// Error alert visibility
    @Published var showErrorAlert = false

    /// Error message text
    @Published var errorMessage = ""

    /// User's previous block requests
    @Published var userRequests: [WebsiteBlockRequest] = []

    /// Loading state from service
    @Published var isLoading = false

    // MARK: - Private Properties

    private let blockService = WebsiteBlockService.shared
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization

    init() {
        observeServiceState()
    }

    // MARK: - Public Methods

    /// Fetch user's previous requests
    func fetchUserRequests() async {
        await blockService.fetchUserRequests()
    }

    /// Submit block request
    func submitRequest() async throws {
        try await blockService.submitBlockRequest(domain: domain)

        // Show success
        showSuccessMessage = true

        // Clear form
        domain = ""
    }

    /// Check if submit button should be enabled
    var canSubmit: Bool {
        domain.contains(".") && !isLoading
    }

    /// Get button background color
    var submitButtonColor: Color {
        canSubmit ? AppTheme.Colors.primary : Color.gray.opacity(0.3)
    }

    // MARK: - Status Helpers

    func statusText(for status: String) -> String {
        switch status {
        case "pending":
            return "Pending review"
        case "approved":
            return "Approved"
        case "rejected":
            return "Not approved"
        case "implemented":
            return "Active in blocklist"
        default:
            return status.capitalized
        }
    }

    func statusColor(for status: String) -> Color {
        switch status {
        case "pending":
            return .orange
        case "approved":
            return .green
        case "rejected":
            return .red
        case "implemented":
            return AppTheme.Colors.primary
        default:
            return AppTheme.Colors.textSecondary
        }
    }

    func statusIcon(for status: String) -> String {
        switch status {
        case "pending":
            return "clock.fill"
        case "approved":
            return "checkmark.circle.fill"
        case "rejected":
            return "xmark.circle.fill"
        case "implemented":
            return "checkmark.shield.fill"
        default:
            return "questionmark.circle.fill"
        }
    }

    // MARK: - Private Methods

    private func observeServiceState() {
        // Observe loading state
        blockService.$isLoading
            .receive(on: DispatchQueue.main)
            .assign(to: &$isLoading)

        // Observe user requests
        blockService.$userRequests
            .receive(on: DispatchQueue.main)
            .assign(to: &$userRequests)
    }
}
