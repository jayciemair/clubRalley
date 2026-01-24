//
//  EditAccountabilityAnchorsView.swift
//  Checkpoint
//
//  Sheet view for editing accountability anchors
//

import SwiftUI

struct EditAccountabilityAnchorsView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = EditAccountabilityAnchorsViewModel()

    @FocusState private var focusedField: Int?

    var body: some View {
        NavigationView {
            ZStack {
                AppTheme.Colors.background
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: AppTheme.Spacing.xl) {

                        // Header explanation
                        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                            Text("Who are you doing this for?")
                                .font(.custom("Satoshi-Bold", size: 24))
                                .foregroundColor(AppTheme.Colors.textPrimary)

                            Text("We'll remind you of what matters most when times get tough.")
                                .font(.custom("Satoshi-Regular", size: 15))
                                .foregroundColor(AppTheme.Colors.textSecondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, AppTheme.Spacing.lg)
                        .padding(.top, AppTheme.Spacing.md)

                        // Anchor input fields
                        VStack(spacing: AppTheme.Spacing.md) {
                            ForEach(0..<viewModel.maxAnchors, id: \.self) { index in
                                AnchorInputField(
                                    index: index,
                                    text: $viewModel.anchors[index],
                                    focusedField: $focusedField,
                                    placeholder: placeholderForIndex(index)
                                )
                            }
                        }
                        .padding(.horizontal, AppTheme.Spacing.lg)

                        // Counter
                        HStack {
                            Spacer()
                            Text("\(viewModel.filledCount)/\(viewModel.maxAnchors) added")
                                .font(.custom("Satoshi-Medium", size: 14))
                                .foregroundColor(AppTheme.Colors.textSecondary)
                        }
                        .padding(.horizontal, AppTheme.Spacing.lg)

                        Spacer(minLength: 100)
                    }
                    .padding(.top, AppTheme.Spacing.lg)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        // Dismiss keyboard when tapping outside text fields
                        focusedField = nil
                    }
                }
                .scrollDismissesKeyboard(.interactively)
            }
            .navigationTitle("My Why")
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
                            await viewModel.saveAnchors()
                        }
                    }
                    .font(.custom("Satoshi-Medium", size: 17))
                    .foregroundColor(viewModel.canSave ? AppTheme.Colors.success : AppTheme.Colors.textSecondary)
                    .disabled(!viewModel.canSave)
                }
            }
        }
        .onAppear {
            viewModel.loadCurrentAnchors()
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

    // MARK: - Helper Methods

    private func placeholderForIndex(_ index: Int) -> String {
        let placeholders = [
            "e.g., My kids",
            "e.g., My partner",
            "e.g., My financial future",
            "e.g., My health",
            "e.g., Myself"
        ]
        return placeholders[index]
    }
}

// MARK: - Anchor Input Field

struct AnchorInputField: View {
    let index: Int
    @Binding var text: String
    var focusedField: FocusState<Int?>.Binding
    let placeholder: String

    var body: some View {
        HStack(spacing: AppTheme.Spacing.md) {
            // Number badge
            Text("\(index + 1)")
                .font(.custom("Satoshi-Bold", size: 14))
                .foregroundColor(text.isEmpty ? AppTheme.Colors.textSecondary : .white)
                .frame(width: 28, height: 28)
                .background(
                    Circle()
                        .fill(text.isEmpty ? Color.gray.opacity(0.2) : AppTheme.Colors.success)
                )

            // Text field
            TextField(placeholder, text: $text)
                .font(.custom("Satoshi-Medium", size: 17))
                .foregroundColor(AppTheme.Colors.textPrimary)
                .focused(focusedField, equals: index)
                .submitLabel(index < 4 ? .next : .done)
                .onSubmit {
                    if index < 4 {
                        focusedField.wrappedValue = index + 1
                    } else {
                        focusedField.wrappedValue = nil
                    }
                }

            // Clear button (only show if there's text)
            if !text.isEmpty {
                Button(action: {
                    text = ""
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 18))
                        .foregroundColor(AppTheme.Colors.textSecondary)
                }
            }
        }
        .padding(.horizontal, AppTheme.Spacing.md)
        .padding(.vertical, AppTheme.Spacing.md)
        .background(AppTheme.Colors.darkSurface)
        .cornerRadius(AppTheme.Radius.medium)
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.Radius.medium)
                .stroke(focusedField.wrappedValue == index ? AppTheme.Colors.success : Color.clear, lineWidth: 2)
        )
    }
}

// MARK: - Preview

struct EditAccountabilityAnchorsView_Previews: PreviewProvider {
    static var previews: some View {
        EditAccountabilityAnchorsView()
    }
}
