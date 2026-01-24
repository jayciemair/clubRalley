//
//  FeatureRequestView.swift
//  Checkpoint
//
//  Full-screen view for requesting features
//

import SwiftUI

struct FeatureRequestView: View {
    @Binding var isPresented: Bool
    @StateObject private var viewModel = FeatureRequestViewModel()
    @FocusState private var isTextFieldFocused: Bool

    var body: some View {
        ZStack {
            // Pink gradient background
            LinearGradient(
                colors: [
                    Color(hex: "#F8C8DC"),
                    Color(hex: "#F0A0C0"),
                    Color(hex: "#E890B8")
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header with close button
                HStack {
                    Text("request feature")
                        .font(.custom("Satoshi-Bold", size: 28))
                        .foregroundColor(.white)

                    Spacer()

                    Button(action: {
                        isPresented = false
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 28))
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)
                .padding(.bottom, 16)

                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // Info card
                        HStack(spacing: 16) {
                            ZStack {
                                Circle()
                                    .fill(Color(hex: "#E080C0").opacity(0.3))
                                    .frame(width: 50, height: 50)

                                Image(systemName: "lightbulb.fill")
                                    .font(.system(size: 22))
                                    .foregroundColor(Color(hex: "#D070B0"))
                            }

                            VStack(alignment: .leading, spacing: 4) {
                                Text("share your ideas")
                                    .font(.custom("Satoshi-Bold", size: 17))
                                    .foregroundColor(Color(hex: "#4A2040"))

                                Text("what features would help you heal?")
                                    .font(.custom("Satoshi-Regular", size: 14))
                                    .foregroundColor(Color(hex: "#6A3060").opacity(0.7))
                            }

                            Spacer()
                        }
                        .padding(20)
                        .background(Color.white.opacity(0.6))
                        .cornerRadius(20)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color.white.opacity(0.3), lineWidth: 1)
                        )

                        // Feature description input
                        VStack(alignment: .leading, spacing: 12) {
                            Text("describe your idea")
                                .font(.custom("Satoshi-Bold", size: 16))
                                .foregroundColor(.white)

                            TextField("what would you like us to add?", text: $viewModel.featureDescription, axis: .vertical)
                                .lineLimit(4...8)
                                .font(.custom("Satoshi-Regular", size: 16))
                                .foregroundColor(Color(hex: "#4A2040"))
                                .padding(16)
                                .background(Color.white.opacity(0.8))
                                .cornerRadius(16)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(Color.white.opacity(0.5), lineWidth: 1)
                                )
                                .focused($isTextFieldFocused)
                        }

                        // Your Previous Requests
                        if !viewModel.userRequests.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("your previous requests")
                                    .font(.custom("Satoshi-Bold", size: 16))
                                    .foregroundColor(.white)

                                ForEach(viewModel.userRequests.prefix(3), id: \.id) { request in
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text(request.featureDescription)
                                            .font(.custom("Satoshi-Regular", size: 15))
                                            .foregroundColor(Color(hex: "#4A2040"))
                                            .lineLimit(2)

                                        if let createdAt = request.createdAt {
                                            Text(createdAt, style: .date)
                                                .font(.custom("Satoshi-Regular", size: 12))
                                                .foregroundColor(Color(hex: "#6A3060").opacity(0.7))
                                        }
                                    }
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(16)
                                    .background(Color.white.opacity(0.5))
                                    .cornerRadius(16)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16)
                                            .stroke(Color.white.opacity(0.3), lineWidth: 1)
                                    )
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
                                    Text("submit")
                                        .font(.custom("Satoshi-Bold", size: 17))
                                }
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                LinearGradient(
                                    colors: viewModel.canSubmit
                                        ? [Color(hex: "#E080C0"), Color(hex: "#D070B0")]
                                        : [Color.gray.opacity(0.5), Color.gray.opacity(0.4)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(20)
                        }
                        .disabled(!viewModel.canSubmit)

                        Spacer(minLength: 50)
                    }
                    .padding(.horizontal, 24)
                    .background(
                        Color.clear
                            .contentShape(Rectangle())
                            .onTapGesture {
                                isTextFieldFocused = false
                            }
                    )
                }
            }

            // Success overlay
            if viewModel.showSuccessMessage {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                    .onTapGesture { }

                VStack(spacing: 20) {
                    ZStack {
                        Circle()
                            .fill(Color(hex: "#E080C0").opacity(0.2))
                            .frame(width: 80, height: 80)

                        Image(systemName: "checkmark")
                            .font(.system(size: 36, weight: .bold))
                            .foregroundColor(Color(hex: "#D070B0"))
                    }

                    Text("thank you!")
                        .font(.custom("Satoshi-Bold", size: 24))
                        .foregroundColor(Color(hex: "#4A2040"))

                    Text("we've received your idea and will review it soon")
                        .font(.custom("Satoshi-Regular", size: 16))
                        .foregroundColor(Color(hex: "#6A3060").opacity(0.8))
                        .multilineTextAlignment(.center)
                }
                .padding(32)
                .background(Color.white.opacity(0.95))
                .cornerRadius(24)
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(Color.white.opacity(0.5), lineWidth: 1)
                )
                .shadow(color: Color(hex: "#E080C0").opacity(0.3), radius: 20)
                .padding(.horizontal, 40)
                .transition(.scale.combined(with: .opacity))
            }
        }
        .onAppear {
            Task {
                await viewModel.fetchUserRequests()
            }
        }
        .alert("error", isPresented: $viewModel.showErrorAlert) {
            Button("ok", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage)
        }
    }

    // MARK: - Helper Methods

    private func submitRequest() async {
        isTextFieldFocused = false

        do {
            try await viewModel.submitRequest()

            // Show success message
            withAnimation(.spring()) {
                viewModel.showSuccessMessage = true
            }

            // Hide success message and close after delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                withAnimation {
                    viewModel.showSuccessMessage = false
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    isPresented = false
                }
            }

        } catch {
            viewModel.errorMessage = error.localizedDescription
            viewModel.showErrorAlert = true
        }
    }
}

struct FeatureRequestView_Previews: PreviewProvider {
    static var previews: some View {
        FeatureRequestView(isPresented: .constant(true))
    }
}
