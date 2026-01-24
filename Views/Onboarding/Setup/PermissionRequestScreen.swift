//
//  PermissionRequestScreen.swift
//  Checkpoint
//
//  A reusable, themed screen for requesting a permission during onboarding.
//  It centralizes layout, haptics, alerts, and flow navigation.
//

import SwiftUI

struct PermissionRequestScreen<Content: View>: View {
    // MARK: - Configuration
    let title: String
    let subtitle: String?
    let iconSystemName: String
    let buttonLabel: String
    let permissionKey: String
    let benefits: [PermissionBenefit]
    let alertTitle: String
    let alertMessage: String
    let showsSettingsLink: Bool
    let alignment: HorizontalAlignment
    let gradientStyle: OnboardingGradientStyle
    let preflight: (() -> Bool)?
    let requestAction: () async throws -> Bool
    let contentBuilder: () -> Content

    // MARK: - State
    @EnvironmentObject private var flowController: OnboardingFlowController
    @State private var isRequesting = false
    @State private var permissionGranted = false
    @State private var showError = false

    // MARK: - Computed Colors (based on gradient style)
    private var titleColor: Color {
        gradientStyle == .roseGlow ? Color(hex: "#4A2040") : .white
    }

    private var subtitleColor: Color {
        gradientStyle == .roseGlow ? Color(hex: "#6A3060").opacity(0.85) : .white.opacity(0.8)
    }

    private var iconBackgroundColor: Color {
        gradientStyle == .roseGlow ? Color(hex: "#4A2040").opacity(0.1) : .white.opacity(0.1)
    }

    private var iconColor: Color {
        gradientStyle == .roseGlow ? Color(hex: "#4A2040") : .white
    }

    private var buttonBackgroundColor: Color {
        gradientStyle == .roseGlow ? Color(hex: "#4A2040") : AppTheme.Colors.primary
    }

    private var buttonTextColor: Color {
        .white
    }

    // MARK: - Init
    init(
        title: String,
        subtitle: String? = nil,
        iconSystemName: String,
        buttonLabel: String,
        permissionKey: String,
        benefits: [PermissionBenefit] = [],
        alertTitle: String,
        alertMessage: String,
        showsSettingsLink: Bool = false,
        alignment: HorizontalAlignment = .leading,
        gradientStyle: OnboardingGradientStyle = .enableShield,
        preflight: (() -> Bool)? = nil,
        requestAction: @escaping () async throws -> Bool,
        @ViewBuilder content: @escaping () -> Content = { EmptyView() }
    ) {
        self.title = title
        self.subtitle = subtitle
        self.iconSystemName = iconSystemName
        self.buttonLabel = buttonLabel
        self.permissionKey = permissionKey
        self.benefits = benefits
        self.alertTitle = alertTitle
        self.alertMessage = alertMessage
        self.showsSettingsLink = showsSettingsLink
        self.alignment = alignment
        self.gradientStyle = gradientStyle
        self.preflight = preflight
        self.requestAction = requestAction
        self.contentBuilder = content
    }

    // MARK: - Body
    var body: some View {
        ZStack {
            // Background gradient
            OnboardingGradientBackground(style: gradientStyle)

            // Main scrollable content
            OnboardingScrollableLayout(
                showBackButton: false,
                showContinueButton: false,
                backgroundColor: .clear
            ) {
                // Question and subtitle
                VStack(alignment: alignment == .center ? .center : .leading, spacing: AppTheme.Spacing.md) {
                    Text(title)
                        .font(.custom("Satoshi-Bold", size: 36))
                        .foregroundColor(titleColor)
                        .multilineTextAlignment(alignment == .center ? .center : .leading)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, alignment: alignment == .center ? .center : .leading)

                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(.custom("Satoshi-Medium", size: 18))
                            .foregroundColor(subtitleColor)
                            .multilineTextAlignment(alignment == .center ? .center : .leading)
                            .fixedSize(horizontal: false, vertical: true)
                            .frame(maxWidth: .infinity, alignment: alignment == .center ? .center : .leading)
                    }
                }
                .padding(.top, AppTheme.Spacing.lg)
                .padding(.horizontal, AppTheme.Spacing.lg)

                // Icon positioned in middle area
                ZStack {
                    Circle()
                        .fill(iconBackgroundColor)
                        .frame(width: 140, height: 140)

                    Image(systemName: iconSystemName)
                        .font(.system(size: 70))
                        .foregroundColor(iconColor)
                }
                .padding(.top, AppTheme.Spacing.xxl)

                // Benefits or custom content - NOW IN SCROLL VIEW
                Group {
                    if !benefits.isEmpty {
                        VStack(alignment: .leading, spacing: AppTheme.Spacing.lg) {
                            ForEach(benefits) { benefit in
                                PermissionBenefitRow(
                                    icon: benefit.iconSystemName,
                                    title: benefit.title,
                                    description: benefit.description,
                                    useDarkText: gradientStyle == .roseGlow
                                )
                            }
                        }
                        .padding(.horizontal, AppTheme.Spacing.lg + AppTheme.Spacing.md)
                        .padding(.top, AppTheme.Spacing.xxl)
                    } else {
                        contentBuilder()
                            .padding(.horizontal, AppTheme.Spacing.lg)
                            .padding(.top, AppTheme.Spacing.xxl)
                    }
                }

                // Bottom padding to ensure content doesn't get hidden by fixed button
                Spacer()
                    .frame(height: 140)
            } continueAction: {
                // Not used - screen has its own permission button
            }

            // Fixed button at bottom (only button is fixed now)
            VStack {
                Spacer()

                // Button
                Button(action: handleRequestTapped) {
                    HStack {
                        if isRequesting {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
                        } else {
                            Text(permissionGranted ? "enabled" : buttonLabel)
                                .font(.custom("Satoshi-Bold", size: 18))

                            if permissionGranted {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 20))
                            }
                        }
                    }
                    .foregroundColor(buttonTextColor)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(
                        RoundedRectangle(cornerRadius: AppTheme.Radius.medium)
                            .fill(permissionGranted ? Color.green : buttonBackgroundColor)
                    )
                }
                .disabled(isRequesting || permissionGranted)
                .padding(.horizontal, AppTheme.Spacing.lg)
                .padding(.bottom, AppTheme.Spacing.xl)
            }
        }
        .alert(alertTitle, isPresented: $showError) {
            if showsSettingsLink {
                Button("Open Settings") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
            }
            Button("OK", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
        .tint(.white)
    }

    // MARK: - Actions
    private func handleRequestTapped() {
        guard !isRequesting else { return }

        isRequesting = true

        // Haptic feedback
        let impact = UIImpactFeedbackGenerator(style: .light)
        impact.impactOccurred()

        if let preflight = preflight, preflight() == false {
            isRequesting = false
            showError = true
            let errorImpact = UIImpactFeedbackGenerator(style: .heavy)
            errorImpact.impactOccurred()
            return
        }

        Task {
            do {
                let granted = try await requestAction()

                await MainActor.run {
                    isRequesting = false
                    permissionGranted = granted

                    // Save the permission state
                    flowController.saveData(for: permissionKey, data: ["granted": granted])

                    if granted {
                        // Success haptic
                        let successImpact = UIImpactFeedbackGenerator(style: .medium)
                        successImpact.impactOccurred()
                    } else {
                        // Light haptic for denial
                        let lightImpact = UIImpactFeedbackGenerator(style: .light)
                        lightImpact.impactOccurred()
                    }

                    // Always navigate to next screen after a short delay
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        flowController.navigateNext()
                    }
                }
            } catch {
                await MainActor.run {
                    isRequesting = false
                    showError = true

                    // Error haptic
                    let errorImpact = UIImpactFeedbackGenerator(style: .heavy)
                    errorImpact.impactOccurred()
                }
            }
        }
    }
}

// MARK: - Subviews
private struct PermissionBenefitRow: View {
    let icon: String
    let title: String
    let description: String?
    var useDarkText: Bool = false

    private var iconColor: Color {
        useDarkText ? Color(hex: "#4A2040") : .white
    }

    private var titleColor: Color {
        useDarkText ? Color(hex: "#4A2040") : .white
    }

    private var descriptionColor: Color {
        useDarkText ? Color(hex: "#6A3060").opacity(0.7) : .white.opacity(0.7)
    }

    var body: some View {
        HStack(alignment: .center, spacing: AppTheme.Spacing.md) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(iconColor)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.custom("Satoshi-Bold", size: 18))
                    .foregroundColor(titleColor)

                if let description = description, !description.isEmpty {
                    Text(description)
                        .font(.custom("Satoshi-Regular", size: 14))
                        .foregroundColor(descriptionColor)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            Spacer()
        }
    }
} 