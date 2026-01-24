//
//  MochiChatView.swift
//  Checkpoint
//
//  AI counselor chat interface with Mochi
//

import SwiftUI

struct MochiChatView: View {
    var onDismiss: (() -> Void)? = nil
    @Environment(\.dismiss) private var environmentDismiss
    @Environment(\.colorScheme) private var colorScheme
    @StateObject private var viewModel = MochiChatViewModel()
    @State private var messageText = ""
    @FocusState private var isTextFieldFocused: Bool

    // MARK: - Color Scheme Adaptive Colors

    private var backgroundColor: Color {
        colorScheme == .dark
            ? Color(red: 0.11, green: 0.11, blue: 0.12)  // #1C1C1E
            : Color.clear  // Will show gradient
    }

    private var inputBarBackground: Color {
        colorScheme == .dark
            ? Color(red: 0.17, green: 0.17, blue: 0.18)  // #2C2C2E
            : Color.white.opacity(0.6)
    }

    private var inputFieldBackground: Color {
        colorScheme == .dark
            ? Color(red: 0.22, green: 0.22, blue: 0.23)  // #383838
            : Color.white.opacity(0.8)
    }

    private var typingBubbleBackground: Color {
        colorScheme == .dark
            ? Color(red: 0.22, green: 0.22, blue: 0.23)
            : Color.white.opacity(0.7)
    }

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(spacing: 16) {
                    ForEach(viewModel.messages) { message in
                        ChatMessageRow(message: message)
                            .id(message.id)
                    }

                    // Typing indicator
                    if viewModel.isTyping {
                        HStack(alignment: .top, spacing: 8) {
                            Image("Mochi")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 64, height: 64)
                                .clipShape(Circle())

                            HStack(spacing: 4) {
                                ForEach(0..<3) { index in
                                    Circle()
                                        .fill(colorScheme == .dark ? Color.gray : AppTheme.Colors.textSecondary)
                                        .frame(width: 8, height: 8)
                                }
                            }
                            .frame(height: 16)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 12)
                            .background(typingBubbleBackground)
                            .cornerRadius(16)

                            Spacer()
                        }
                        .padding(.horizontal)
                    }

                    // Bottom padding for input bar
                    Color.clear.frame(height: 20)
                }
                .padding(.top, 16)
            }
            .scrollDismissesKeyboard(.interactively)
            .onChange(of: viewModel.messages.count) { _ in
                // Auto-scroll to bottom when new message
                if let lastMessage = viewModel.messages.last {
                    withAnimation {
                        proxy.scrollTo(lastMessage.id, anchor: .bottom)
                    }
                }
            }
            .onTapGesture {
                // Tap to dismiss keyboard
                isTextFieldFocused = false
            }
        }
        .safeAreaInset(edge: .bottom) {
            // Input bar
            VStack(spacing: 0) {
                HStack(spacing: 12) {
                    TextField("Speak your mind...", text: $messageText, axis: .vertical)
                        .textFieldStyle(.plain)
                        .foregroundColor(Color(.label))
                        .padding(12)
                        .background(inputFieldBackground)
                        .cornerRadius(20)
                        .lineLimit(1...4)
                        .focused($isTextFieldFocused)

                    Button(action: sendMessage) {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 32))
                            .foregroundColor(messageText.isEmpty ? (colorScheme == .dark ? Color.gray : AppTheme.Colors.textSecondary) : AppTheme.Colors.primary)
                    }
                    .disabled(messageText.isEmpty || viewModel.isTyping)
                }
                .padding(.horizontal)
                .padding(.vertical, 12)
            }
            .background(inputBarBackground)
            .background(
                inputBarBackground
                    .ignoresSafeArea(edges: .bottom)
            )
        }
        .background(
            Group {
                if colorScheme == .dark {
                    backgroundColor
                        .ignoresSafeArea()
                } else {
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
                }
            }
        )
            .navigationTitle("Mochi")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        if let onDismiss = onDismiss {
                            // Called with custom dismiss handler
                            onDismiss()
                        } else {
                            // Called from elsewhere - dismiss normally
                            environmentDismiss()
                        }
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(colorScheme == .dark ? .white : .black)
                    }
                }
            }
    }

    private func sendMessage() {
        guard !messageText.isEmpty else { return }

        let text = messageText
        messageText = ""

        Task {
            await viewModel.sendMessage(text)
        }
    }
}

// MARK: - Chat Message Row

struct ChatMessageRow: View {
    let message: ChatMessage
    @Environment(\.colorScheme) private var colorScheme

    // Dark mode colors
    private var mochiBubbleBackground: Color {
        colorScheme == .dark
            ? Color(red: 0.22, green: 0.22, blue: 0.23)  // #383838
            : Color.white.opacity(0.8)
    }

    private var mochiTextColor: Color {
        colorScheme == .dark
            ? Color.white
            : AppTheme.Colors.textPrimary
    }

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            if message.isFromUser {
                Spacer()
                messageBubble
            } else {
                Image("Mochi")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 64, height: 64)
                    .clipShape(Circle())
                messageBubble
                Spacer()
            }
        }
        .padding(.horizontal)
    }

    private var messageBubble: some View {
        Text(formatMessage())
            .font(.custom("Satoshi-Regular", size: 16))
            .foregroundColor(message.isFromUser ? .white : mochiTextColor)
            .fixedSize(horizontal: false, vertical: true)
            .padding(12)
            .background(
                message.isFromUser
                    ? AppTheme.Colors.primary
                    : mochiBubbleBackground
            )
            .cornerRadius(16)
    }

    private func formatMessage() -> AttributedString {
        // Only parse markdown for Mochi's responses, not user messages
        if !message.isFromUser {
            return message.text.parseBasicMarkdown()
        } else {
            // User messages stay plain
            return AttributedString(message.text)
        }
    }
}

// MARK: - Preview

struct MochiChatView_Previews: PreviewProvider {
    static var previews: some View {
        MochiChatView()
    }
}
