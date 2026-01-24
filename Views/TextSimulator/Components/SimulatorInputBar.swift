//
//  SimulatorInputBar.swift
//  goh
//
//  iMessage-style input bar for text simulator
//

import SwiftUI

struct SimulatorInputBar: View {
    @Binding var text: String
    let isDisabled: Bool
    let onSend: () -> Void

    @FocusState private var isFocused: Bool
    @Environment(\.colorScheme) private var colorScheme

    private let pinkColor = Color(red: 1.0, green: 0.61, blue: 0.87) // #FE9CDD

    private var inputBackground: Color {
        colorScheme == .dark ? Color(red: 0.11, green: 0.11, blue: 0.12) : Color.white
    }

    var body: some View {
        VStack(spacing: 0) {
            // Separator
            Rectangle()
                .fill(Color.gray.opacity(0.2))
                .frame(height: 0.5)

            HStack(spacing: 12) {
                // Text field
                TextField("Message...", text: $text, axis: .vertical)
                    .font(.custom("Satoshi-Regular", size: 16))
                    .lineLimit(1...5)
                    .focused($isFocused)
                    .disabled(isDisabled)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(colorScheme == .dark ? Color(red: 0.17, green: 0.17, blue: 0.18) : Color(red: 0.95, green: 0.95, blue: 0.96))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 0.5)
                    )

                // Send button
                Button(action: {
                    if !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        onSend()
                        isFocused = false
                    }
                }) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 34))
                        .foregroundColor(canSend ? pinkColor : .gray.opacity(0.4))
                }
                .disabled(!canSend || isDisabled)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .background(inputBackground)
        .background(
            // Extend background below safe area
            inputBackground
                .ignoresSafeArea(edges: .bottom)
        )
    }

    private var canSend: Bool {
        !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isDisabled
    }
}

#Preview {
    VStack {
        Spacer()
        SimulatorInputBar(
            text: .constant(""),
            isDisabled: false,
            onSend: {}
        )
    }
    .background(Color(red: 0.98, green: 0.96, blue: 0.97))
}
