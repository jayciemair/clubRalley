//
//  EditRecoveryGoalsView.swift
//  Checkpoint
//
//  Sheet view for editing recovery goals
//

import SwiftUI

struct EditRecoveryGoalsView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = EditRecoveryGoalsViewModel()
    @FocusState private var isTextFieldFocused: Bool

    var body: some View {
        NavigationView {
            ZStack {
                AppTheme.Colors.background
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: AppTheme.Spacing.xl) {

                        // Header explanation
                        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                            Text("What are your goals?")
                                .font(.custom("Satoshi-Bold", size: 24))
                                .foregroundColor(AppTheme.Colors.textPrimary)

                            Text("Select all that apply. We'll remind you of these when times get tough.")
                                .font(.custom("Satoshi-Regular", size: 15))
                                .foregroundColor(AppTheme.Colors.textSecondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, AppTheme.Spacing.lg)
                        .padding(.top, AppTheme.Spacing.md)

                        // Goal options list
                        VStack(spacing: 12) {
                            // Custom goals appear at the top with delete button
                            ForEach(viewModel.customGoals, id: \.self) { goal in
                                HStack {
                                    Text(goal)
                                        .font(.custom("Satoshi-Medium", size: 16))
                                        .foregroundColor(.white)
                                        .frame(maxWidth: .infinity, alignment: .leading)

                                    Button(action: {
                                        let generator = UIImpactFeedbackGenerator(style: .light)
                                        generator.impactOccurred()
                                        viewModel.removeCustomGoal(goal)
                                    }) {
                                        Image(systemName: "xmark.circle.fill")
                                            .font(.system(size: 20))
                                            .foregroundColor(.white.opacity(0.7))
                                    }
                                }
                                .padding(.horizontal, 20)
                                .padding(.vertical, 16)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(AppTheme.Colors.success)
                                )
                            }

                            // Predefined goals
                            ForEach(viewModel.availableGoals, id: \.self) { goal in
                                Button(action: {
                                    let generator = UIImpactFeedbackGenerator(style: .medium)
                                    generator.impactOccurred()
                                    viewModel.toggleGoal(goal)
                                }) {
                                    HStack {
                                        Text(goal)
                                            .font(.custom("Satoshi-Medium", size: 16))
                                            .foregroundColor(viewModel.selectedGoals.contains(goal) ? .white : AppTheme.Colors.textPrimary)
                                            .frame(maxWidth: .infinity, alignment: .leading)

                                        if viewModel.selectedGoals.contains(goal) {
                                            Image(systemName: "checkmark")
                                                .font(.system(size: 14, weight: .bold))
                                                .foregroundColor(.white)
                                        }
                                    }
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 16)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(viewModel.selectedGoals.contains(goal) ? AppTheme.Colors.success : AppTheme.Colors.darkSurface)
                                    )
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding(.horizontal, AppTheme.Spacing.lg)

                        // Add custom goal input
                        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                            Text("Add your own")
                                .font(.custom("Satoshi-Bold", size: 18))
                                .foregroundColor(AppTheme.Colors.textPrimary)

                            HStack(spacing: 12) {
                                TextField("e.g., Be there for my daughter's graduation", text: $viewModel.newCustomGoal)
                                    .font(.custom("Satoshi-Medium", size: 16))
                                    .foregroundColor(AppTheme.Colors.textPrimary)
                                    .focused($isTextFieldFocused)
                                    .submitLabel(.done)
                                    .onSubmit {
                                        if viewModel.canAddCustomGoal {
                                            let generator = UIImpactFeedbackGenerator(style: .medium)
                                            generator.impactOccurred()
                                            viewModel.addCustomGoal()
                                        }
                                    }

                                Button(action: {
                                    let generator = UIImpactFeedbackGenerator(style: .medium)
                                    generator.impactOccurred()
                                    viewModel.addCustomGoal()
                                }) {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.system(size: 24))
                                        .foregroundColor(viewModel.canAddCustomGoal ? AppTheme.Colors.success : AppTheme.Colors.textSecondary)
                                }
                                .disabled(!viewModel.canAddCustomGoal)
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 14)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(AppTheme.Colors.darkSurface)
                            )
                        }
                        .padding(.horizontal, AppTheme.Spacing.lg)
                        .padding(.top, AppTheme.Spacing.md)

                        // Counter
                        HStack {
                            Spacer()
                            Text("\(viewModel.allGoals.count) total goals")
                                .font(.custom("Satoshi-Medium", size: 14))
                                .foregroundColor(AppTheme.Colors.textSecondary)
                        }
                        .padding(.horizontal, AppTheme.Spacing.lg)

                        Spacer(minLength: 100)
                    }
                    .padding(.top, AppTheme.Spacing.lg)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        isTextFieldFocused = false
                    }
                }
                .scrollIndicators(.hidden)
                .scrollDismissesKeyboard(.interactively)
            }
            .navigationTitle("My Goals")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(AppTheme.Colors.textSecondary)
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        Task {
                            await viewModel.saveGoals()
                        }
                    }
                    .font(.custom("Satoshi-Medium", size: 17))
                    .foregroundColor(viewModel.canSave ? AppTheme.Colors.success : AppTheme.Colors.textSecondary)
                    .disabled(!viewModel.canSave)
                }
            }
        }
        .onAppear {
            viewModel.loadCurrentGoals()
        }
        .onChange(of: viewModel.saveSuccessful) { success in
            if success {
                dismiss()
            }
        }
        .alert("Error", isPresented: $viewModel.showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(viewModel.errorMessage)
        }
    }
}

// MARK: - Preview

struct EditRecoveryGoalsView_Previews: PreviewProvider {
    static var previews: some View {
        EditRecoveryGoalsView()
    }
}
