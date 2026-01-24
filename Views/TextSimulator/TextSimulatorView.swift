//
//  TextSimulatorView.swift
//  goh
//
//  Main view for the "Text Him" simulator feature
//

import SwiftUI

struct TextSimulatorView: View {
    @StateObject private var viewModel = TextSimulatorViewModel()
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @State private var keyboardIsShowing = false
    @State private var shouldDismissAfterReflection = false

    private var backgroundColor: Color {
        colorScheme == .dark
            ? Color(red: 0.11, green: 0.11, blue: 0.12)  // #1C1C1E like onboarding
            : Color(red: 0.98, green: 0.96, blue: 0.97)
    }

    var body: some View {
        ZStack {
            // Background - adapts to color scheme
            backgroundColor
                .ignoresSafeArea()
                .onTapGesture {
                    // Dismiss keyboard on tap
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                }

            VStack(spacing: 0) {
                // Header
                SimulatorHeader(
                    contactStatus: viewModel.contactStatus,
                    onBack: {
                        // Show reflection if they had a conversation, otherwise just dismiss
                        if viewModel.messages.count > 1 {
                            shouldDismissAfterReflection = true
                            viewModel.showReflection = true
                        } else {
                            dismiss()
                        }
                    }
                )

                // Messages
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 8) {
                            // Conversation start indicator
                            if viewModel.messages.isEmpty {
                                conversationStartView
                            }

                            // Messages
                            ForEach(viewModel.messages) { message in
                                if message.messageType == .systemEvent {
                                    // System event - centered text
                                    Text(message.content)
                                        .font(.custom("Satoshi-Regular", size: 14))
                                        .foregroundColor(.gray)
                                        .multilineTextAlignment(.center)
                                        .frame(maxWidth: .infinity)
                                        .padding(.horizontal, 24)
                                        .padding(.vertical, 12)
                                        .id(message.id)
                                } else {
                                    SimulatorMessageBubble(
                                        message: message,
                                        showDeliveryStatus: message.isFromUser && isLastUserMessage(message)
                                    )
                                    .id(message.id)
                                }
                            }

                            // Typing indicator
                            if viewModel.isTyping {
                                TypingIndicatorSimple()
                                    .id("typing")
                            }

                            // Ghosting indicator
                            if viewModel.state == .ghosting && !viewModel.isTyping {
                                ghostingIndicator
                                    .id("ghosting")
                            }

                            // Bottom padding for input bar
                            Color.clear.frame(height: 20)
                        }
                        .padding(.vertical, 16)
                    }
                    .scrollDismissesKeyboard(.interactively)
                    .onChange(of: viewModel.messages.count) { _, _ in
                        // Auto-scroll to bottom when new message
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            withAnimation(.easeOut(duration: 0.2)) {
                                if let lastMessage = viewModel.messages.last {
                                    proxy.scrollTo(lastMessage.id, anchor: .bottom)
                                }
                            }
                        }
                    }
                    .onChange(of: viewModel.isTyping) { _, isTyping in
                        if isTyping {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                withAnimation(.easeOut(duration: 0.2)) {
                                    proxy.scrollTo("typing", anchor: .bottom)
                                }
                            }
                        }
                    }
                    .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)) { _ in
                        // Scroll to bottom when keyboard appears
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            withAnimation(.easeOut(duration: 0.2)) {
                                if let lastMessage = viewModel.messages.last {
                                    proxy.scrollTo(lastMessage.id, anchor: .bottom)
                                }
                            }
                        }
                    }
                }

            }
            .safeAreaInset(edge: .bottom) {
                // Input bar - fills to bottom like Mochi
                SimulatorInputBar(
                    text: $viewModel.inputText,
                    isDisabled: viewModel.state == .sending || viewModel.state == .typing,
                    onSend: {
                        Task {
                            await viewModel.sendMessage()
                        }
                    }
                )
            }

            // Screenshot flash overlay - simple white flash like onboarding
            if viewModel.showScreenshotFlash {
                Color.white
                    .ignoresSafeArea()
            }

            // Disclaimer overlay
            if viewModel.showDisclaimer {
                disclaimerView
            }
        }
        .navigationBarHidden(true)
        .fullScreenCover(isPresented: $viewModel.showReflection) {
            SimulatorReflectionView(onComplete: {
                if shouldDismissAfterReflection {
                    dismiss()
                } else {
                    viewModel.performReset()
                }
            })
        }
    }

    // MARK: - Helpers

    private func isLastUserMessage(_ message: SimulatorMessage) -> Bool {
        // Find the last user message in the array
        guard let lastUserMessage = viewModel.messages.last(where: { $0.isFromUser && $0.messageType == .userMessage }) else {
            return false
        }
        return message.id == lastUserMessage.id
    }

    // MARK: - Subviews

    private var conversationStartView: some View {
        Spacer()
            .frame(height: 40)
    }

    private var ghostingIndicator: some View {
        VStack(spacing: 8) {
            Rectangle()
                .fill(Color.gray.opacity(0.3))
                .frame(height: 1)
                .padding(.horizontal, 40)

            Text("he's not going to respond.")
                .font(.custom("Satoshi-Medium", size: 14))
                .foregroundColor(.gray)
        }
        .padding(.vertical, 20)
    }

    private var disclaimerView: some View {
        let pinkColor = Color(red: 1.0, green: 0.61, blue: 0.87) // #FE9CDD

        return ZStack {
            Color.black.opacity(0.85)
                .ignoresSafeArea()

            VStack(spacing: 24) {
                // Icon
                ZStack {
                    Circle()
                        .fill(pinkColor.opacity(0.2))
                        .frame(width: 80, height: 80)

                    Image(systemName: "bubble.left.and.bubble.right.fill")
                        .font(.system(size: 36))
                        .foregroundColor(pinkColor)
                }

                // Title
                Text("Text Him Simulator")
                    .font(.custom("Satoshi-Bold", size: 24))
                    .foregroundColor(.white)

                // Description
                VStack(spacing: 16) {
                    Text("This is a safe space to work through your urge to text him.")
                        .font(.custom("Satoshi-Regular", size: 16))
                        .foregroundColor(.white.opacity(0.9))
                        .multilineTextAlignment(.center)

                    Text("The responses are AI-generated and designed to show you how these conversations usually go - disappointing and unfulfilling.")
                        .font(.custom("Satoshi-Regular", size: 14))
                        .foregroundColor(.white.opacity(0.7))
                        .multilineTextAlignment(.center)

                    Text("No real messages will be sent.")
                        .font(.custom("Satoshi-Bold", size: 14))
                        .foregroundColor(.green)
                }
                .padding(.horizontal, 20)

                // Continue button
                Button(action: {
                    viewModel.dismissDisclaimer()
                }) {
                    Text("I Understand")
                        .font(.custom("Satoshi-Bold", size: 16))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background(
                            LinearGradient(
                                colors: [
                                    Color(red: 1.0, green: 0.61, blue: 0.87),
                                    Color(red: 0.94, green: 0.50, blue: 0.78)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(14)
                }
                .padding(.horizontal, 40)
                .padding(.top, 8)
            }
            .padding(.vertical, 40)
        }
        .transition(.opacity)
    }
}

#Preview {
    TextSimulatorView()
}
