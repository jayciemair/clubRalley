//
//  AccountManagementButton.swift
//  Checkpoint
//
//  Account management options with clarity window restrictions
//  Prevents account changes during vulnerable times
//

import SwiftUI

struct AccountManagementButton: View {
    @StateObject private var viewModel = AccountManagementButtonViewModel()

    var body: some View {
        VStack(spacing: 0) {
            // Main button
            Button(action: {
                viewModel.handleButtonTap()
            }) {
                HStack(spacing: 16) {
                    Image(systemName: "person.circle")
                        .font(.system(size: 26))
                        .foregroundColor(Color(hex: "#E080C0").opacity(viewModel.iconOpacity))
                        .frame(width: 32, height: 32)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("account management")
                            .font(.custom("Satoshi-Regular", size: 17))
                            .foregroundColor(Color(hex: "#4A2040").opacity(viewModel.canAccess ? 1.0 : 0.7))

                        Text(viewModel.availabilityText.lowercased())
                            .font(.system(size: 13))
                            .foregroundColor(Color(hex: "#6A3060").opacity(0.7))
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(Color(hex: "#6A3060").opacity(0.5 * viewModel.iconOpacity))
                        .rotationEffect(.degrees(viewModel.showOptions ? 90 : 0))
                }
                .padding(.vertical, 12)
                .padding(.horizontal, 20)
                .background(Color.white.opacity(0.6))
                .cornerRadius(20)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white.opacity(0.3), lineWidth: 1)
                )
                .opacity(viewModel.canAccess ? 1.0 : 0.8)
            }
            .buttonStyle(PlainButtonStyle())
            .disabled(!viewModel.canAccess)

            // Expandable options (shown when expanded and accessible)
            if viewModel.showOptions && viewModel.canAccess {
                VStack(spacing: 8) {
                    // Sign Out Button
                    Button(action: {
                        viewModel.showSignOutConfirmation = true
                    }) {
                        HStack {
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                                .font(.system(size: 20))
                                .foregroundColor(Color(hex: "#4A2040"))
                                .frame(width: 32, height: 32)

                            Text("sign out")
                                .font(.custom("Satoshi-Regular", size: 16))
                                .foregroundColor(Color(hex: "#4A2040"))

                            Spacer()
                        }
                        .padding(.vertical, 12)
                        .padding(.horizontal, 20)
                        .background(Color.white.opacity(0.4))
                        .cornerRadius(16)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.white.opacity(0.3), lineWidth: 1)
                        )
                    }
                    .buttonStyle(PlainButtonStyle())

                    // Delete Account Button
                    Button(action: {
                        viewModel.showDeleteConfirmation = true
                    }) {
                        HStack {
                            if viewModel.isDeleting {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .red))
                                    .frame(width: 20, height: 20)
                                    .padding(.leading, 6)
                            } else {
                                Image(systemName: "trash")
                                    .font(.system(size: 20))
                                    .foregroundColor(.red.opacity(0.8))
                                    .frame(width: 32, height: 32)
                            }

                            Text("delete account")
                                .font(.custom("Satoshi-Regular", size: 16))
                                .foregroundColor(.red.opacity(0.8))

                            Spacer()
                        }
                        .padding(.vertical, 12)
                        .padding(.horizontal, 20)
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(16)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.red.opacity(0.2), lineWidth: 1)
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                    .disabled(viewModel.isDeleting)
                }
                .padding(.top, 8)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(.horizontal, 20)
        .alert("not available", isPresented: $viewModel.showUnavailableAlert) {
            Button("ok") {}
        } message: {
            Text(viewModel.unavailableReason.lowercased())
        }
        .alert("sign out", isPresented: $viewModel.showSignOutConfirmation) {
            TextField("type SIGN OUT to confirm", text: $viewModel.signOutConfirmationText)
                .autocapitalization(.allCharacters)
                .disableAutocorrection(true)

            Button("cancel", role: .cancel) {
                viewModel.cancelSignOut()
            }

            Button("sign out", role: .destructive) {
                Task {
                    await viewModel.signOut()
                }
            }
            .disabled(!viewModel.canSignOut)
        } message: {
            Text("are you sure you want to sign out? this will end your current session.")
        }
        .alert("delete account", isPresented: $viewModel.showDeleteConfirmation) {
            TextField("type DELETE to confirm", text: $viewModel.deleteConfirmationText)
                .autocapitalization(.allCharacters)
                .disableAutocorrection(true)

            Button("cancel", role: .cancel) {
                viewModel.cancelDelete()
            }

            Button("delete", role: .destructive) {
                Task {
                    await viewModel.deleteAccount()
                }
            }
            .disabled(!viewModel.canDelete)
        } message: {
            Text("this will permanently delete your account and all associated data. this action cannot be undone.")
        }
    }
}

struct AccountManagementButton_Previews: PreviewProvider {
    static var previews: some View {
        AccountManagementButton()
            .background(AppTheme.Colors.background)
    }
}
