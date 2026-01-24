//
//  TypingIndicator.swift
//  goh
//
//  iMessage-style typing indicator (three bouncing dots)
//

import SwiftUI

struct TypingIndicator: View {
    @State private var animationOffset: CGFloat = 0
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack(alignment: .bottom, spacing: 0) {
            HStack(spacing: 4) {
                ForEach(0..<3, id: \.self) { index in
                    Circle()
                        .fill(Color.gray)
                        .frame(width: 8, height: 8)
                        .offset(y: animationOffset(for: index))
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 14)
            .background(colorScheme == .dark ? Color(red: 0.22, green: 0.22, blue: 0.23) : Color(red: 0.93, green: 0.93, blue: 0.94))
            .clipShape(BubbleShape(isFromUser: false))

            Spacer()
        }
        .padding(.horizontal, 16)
        .onAppear {
            withAnimation(
                Animation
                    .easeInOut(duration: 0.5)
                    .repeatForever(autoreverses: true)
            ) {
                animationOffset = -4
            }
        }
    }

    private func animationOffset(for index: Int) -> CGFloat {
        let delay = Double(index) * 0.15
        return animationOffset * cos(delay * .pi)
    }
}

// Alternative simpler animation
struct TypingIndicatorSimple: View {
    @State private var dotOpacities: [Double] = [0.4, 0.4, 0.4]
    let timer = Timer.publish(every: 0.3, on: .main, in: .common).autoconnect()
    @State private var currentDot = 0
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack(alignment: .bottom, spacing: 0) {
            HStack(spacing: 5) {
                ForEach(0..<3, id: \.self) { index in
                    Circle()
                        .fill(Color.gray.opacity(dotOpacities[index]))
                        .frame(width: 8, height: 8)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 14)
            .background(colorScheme == .dark ? Color(red: 0.22, green: 0.22, blue: 0.23) : Color(red: 0.93, green: 0.93, blue: 0.94))
            .clipShape(BubbleShape(isFromUser: false))

            Spacer()
        }
        .padding(.horizontal, 16)
        .onReceive(timer) { _ in
            withAnimation(.easeInOut(duration: 0.2)) {
                dotOpacities = [0.4, 0.4, 0.4]
                dotOpacities[currentDot] = 1.0
                currentDot = (currentDot + 1) % 3
            }
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        TypingIndicator()
        TypingIndicatorSimple()
    }
    .padding()
    .background(Color(red: 0.98, green: 0.96, blue: 0.97))
}
