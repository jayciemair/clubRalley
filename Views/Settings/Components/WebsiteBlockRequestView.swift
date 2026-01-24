//
//  WebsiteBlockRequestView.swift
//  Checkpoint
//
//  Full-screen view for requesting website blocks
//

import SwiftUI

struct WebsiteBlockRequestView: View {
    @Binding var isPresented: Bool
    @StateObject private var viewModel = WebsiteBlockRequestViewModel()
    @FocusState private var isDomainFieldFocused: Bool

    var body: some View {
        ZStack {
            // Background
            AppTheme.Colors.background
                .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.xl) {
                    // Header with close button and title on same line
                    HStack {
                        Button(action: {
                            isPresented = false
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 28))
                                .foregroundColor(AppTheme.Colors.textSecondary.opacity(0.6))
                        }

                        Text("Request Website Block")
                            .font(.custom("Satoshi-Bold", size: 28))
                            .foregroundColor(AppTheme.Colors.textPrimary)

                        Spacer()
                    }

                    // Info card
                    VStack(alignment: .leading, spacing: 4) {
                        Text("How it works")
                            .font(.custom("Satoshi-Medium", size: 16))
                            .foregroundColor(AppTheme.Colors.textPrimary)

                        Text("Submit a website you'd like blocked. We'll review it and add it to our blocklist if approved.")
                            .font(.system(size: 14))
                            .foregroundColor(AppTheme.Colors.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(AppTheme.Spacing.lg)
                    .background(AppTheme.Colors.darkSurface)
                    .cornerRadius(AppTheme.Radius.medium)

                    // Domain input
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                        Text("Website Domain")
                            .font(.custom("Satoshi-Medium", size: 16))
                            .foregroundColor(AppTheme.Colors.textPrimary)

                        TextField("example.com", text: $viewModel.domain)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled(true)
                            .keyboardType(.URL)
                            .font(.custom("Satoshi-Regular", size: 16))
                            .padding(AppTheme.Spacing.md)
                            .background(AppTheme.Colors.darkSurface)
                            .cornerRadius(AppTheme.Radius.small)
                            .foregroundColor(AppTheme.Colors.textPrimary)
                            .focused($isDomainFieldFocused)
                    }

                    // Your Previous Requests
                    if !viewModel.userRequests.isEmpty {
                        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                            Text("Your Previous Requests")
                                .font(.custom("Satoshi-Medium", size: 16))
                                .foregroundColor(AppTheme.Colors.textPrimary)

                            ForEach(viewModel.userRequests.prefix(3), id: \.id) { request in
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(request.domain)
                                            .font(.custom("Satoshi-Regular", size: 15))
                                            .foregroundColor(AppTheme.Colors.textPrimary)

                                        Text(viewModel.statusText(for: request.status))
                                            .font(.system(size: 13))
                                            .foregroundColor(viewModel.statusColor(for: request.status))
                                    }

                                    Spacer()

                                    Image(systemName: viewModel.statusIcon(for: request.status))
                                        .font(.system(size: 16))
                                        .foregroundColor(viewModel.statusColor(for: request.status))
                                }
                                .padding(AppTheme.Spacing.md)
                                .background(AppTheme.Colors.darkSurface)
                                .cornerRadius(AppTheme.Radius.small)
                            }
                        }
                    }

                    // Submit button
                    Button(action: {
                        Task {
                            await submitRequest()
                        }
                    }) {
                        HStack {
                            if viewModel.isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.8)
                            } else {
                                Text("Submit Request")
                                    .font(.custom("Satoshi-Medium", size: 17))
                            }
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, AppTheme.Spacing.md)
                        .background(viewModel.submitButtonColor)
                        .cornerRadius(AppTheme.Radius.medium)
                    }
                    .disabled(!viewModel.canSubmit)

                    Spacer(minLength: 50)
                }
                .padding(.horizontal, AppTheme.Spacing.lg)
                .padding(.top, AppTheme.Spacing.xl)
                .background(
                    Color.clear
                        .contentShape(Rectangle())
                        .onTapGesture {
                            isDomainFieldFocused = false
                        }
                )
            }
            .scrollIndicators(.hidden)

            // Success overlay
            if viewModel.showSuccessMessage {
                // Dimmed background
                Color.black.opacity(0.6)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation {
                            viewModel.showSuccessMessage = false
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            isPresented = false
                        }
                    }

                VStack(spacing: 20) {
                    // Success icon
                    ZStack {
                        Circle()
                            .fill(Color.green.opacity(0.15))
                            .frame(width: 80, height: 80)

                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.green)
                    }

                    // Title
                    Text("Thanks for Submitting!")
                        .font(.custom("Satoshi-Bold", size: 22))
                        .foregroundColor(AppTheme.Colors.textPrimary)

                    // Info items
                    VStack(alignment: .leading, spacing: 16) {
                        HStack(alignment: .top, spacing: 12) {
                            Image(systemName: "clock.fill")
                                .font(.system(size: 16))
                                .foregroundColor(AppTheme.Colors.primary)
                                .frame(width: 24)

                            Text("We'll review your request and update within 24 hours.")
                                .font(.custom("Satoshi-Regular", size: 15))
                                .foregroundColor(AppTheme.Colors.textSecondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }

                        HStack(alignment: .top, spacing: 12) {
                            Image(systemName: "arrow.triangle.2.circlepath")
                                .font(.system(size: 16))
                                .foregroundColor(AppTheme.Colors.primary)
                                .frame(width: 24)

                            Text("Check back here to see the status of your request.")
                                .font(.custom("Satoshi-Regular", size: 15))
                                .foregroundColor(AppTheme.Colors.textSecondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }

                        HStack(alignment: .top, spacing: 12) {
                            Image(systemName: "iphone.gen3")
                                .font(.system(size: 16))
                                .foregroundColor(AppTheme.Colors.primary)
                                .frame(width: 24)

                            Text("If approved, it may take up to 4 hours for your device to pick up the new block.")
                                .font(.custom("Satoshi-Regular", size: 15))
                                .foregroundColor(AppTheme.Colors.textSecondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    .padding(.top, 8)

                    // Dismiss button
                    Button(action: {
                        withAnimation {
                            viewModel.showSuccessMessage = false
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            isPresented = false
                        }
                    }) {
                        Text("Got it")
                            .font(.custom("Satoshi-Bold", size: 16))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(AppTheme.Colors.primary)
                            .cornerRadius(AppTheme.Radius.medium)
                    }
                    .padding(.top, 8)
                }
                .padding(24)
                .background(AppTheme.Colors.darkSurface)
                .cornerRadius(AppTheme.Radius.large)
                .shadow(color: .black.opacity(0.4), radius: 30)
                .padding(.horizontal, 32)
                .transition(.scale.combined(with: .opacity))
            }
        }
        .onAppear {
            Task {
                await viewModel.fetchUserRequests()
            }
        }
        .alert("Error", isPresented: $viewModel.showErrorAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage)
        }
    }

    // MARK: - Helper Methods

    private func submitRequest() async {
        isDomainFieldFocused = false

        do {
            try await viewModel.submitRequest()

            // Show success message - user dismisses manually
            withAnimation(.spring()) {
                viewModel.showSuccessMessage = true
            }

        } catch {
            viewModel.errorMessage = error.localizedDescription
            viewModel.showErrorAlert = true
        }
    }
}

struct WebsiteBlockRequestView_Previews: PreviewProvider {
    static var previews: some View {
        WebsiteBlockRequestView(isPresented: .constant(true))
    }
}