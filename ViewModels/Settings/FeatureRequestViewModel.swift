//
//  FeatureRequestViewModel.swift
//  Checkpoint
//
//  ViewModel for feature request form
//

import SwiftUI
import Combine

@MainActor
class FeatureRequestViewModel: ObservableObject {

    // MARK: - Published Properties

    /// Feature description text input
    @Published var featureDescription: String = ""

    /// Success message visibility
    @Published var showSuccessMessage = false

    /// Error alert visibility
    @Published var showErrorAlert = false

    /// Error message text
    @Published var errorMessage = ""

    /// User's previous feature requests
    @Published var userRequests: [FeatureRequest] = []

    /// Loading state from service
    @Published var isLoading = false

    // MARK: - Private Properties

    private let featureService = FeatureRequestService.shared
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization

    init() {
        observeServiceState()
    }

    // MARK: - Public Methods

    /// Fetch user's previous requests
    func fetchUserRequests() async {
        await featureService.fetchUserRequests()
    }

    /// Submit feature request
    func submitRequest() async throws {
        try await featureService.submitFeatureRequest(description: featureDescription)

        // Show success
        showSuccessMessage = true

        // Clear form
        featureDescription = ""
    }

    /// Check if submit button should be enabled
    var canSubmit: Bool {
        !featureDescription.isEmpty && !isLoading
    }

    /// Get button background color
    var submitButtonColor: Color {
        canSubmit ? AppTheme.Colors.primary : Color.gray.opacity(0.3)
    }

    // MARK: - Private Methods

    private func observeServiceState() {
        // Observe loading state
        featureService.$isLoading
            .receive(on: DispatchQueue.main)
            .assign(to: &$isLoading)

        // Observe user requests
        featureService.$userRequests
            .receive(on: DispatchQueue.main)
            .assign(to: &$userRequests)
    }
}
