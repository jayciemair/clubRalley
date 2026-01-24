//
//  SimulatorMessageBubble.swift
//  goh
//
//  iMessage-style message bubble for text simulator
//

import SwiftUI

struct SimulatorMessageBubble: View {
    let message: SimulatorMessage
    let showDeliveryStatus: Bool
    @Environment(\.colorScheme) private var colorScheme

    init(message: SimulatorMessage, showDeliveryStatus: Bool = true) {
        self.message = message
        self.showDeliveryStatus = showDeliveryStatus
    }

    var body: some View {
        VStack(alignment: message.isFromUser ? .trailing : .leading, spacing: 4) {
            HStack {
                if message.isFromUser {
                    Spacer(minLength: 60)
                }

                Text(message.content)
                    .font(.custom("Satoshi-Regular", size: 16))
                    .foregroundColor(message.isFromUser ? .white : (colorScheme == .dark ? .white : .black))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(bubbleBackground)
                    .clipShape(BubbleShape(isFromUser: message.isFromUser))

                if !message.isFromUser {
                    Spacer(minLength: 60)
                }
            }

            // Delivery status for user messages
            if message.isFromUser && showDeliveryStatus && message.deliveryStatus != .none {
                Text(message.deliveryStatus.displayText)
                    .font(.custom("Satoshi-Regular", size: 11))
                    .foregroundColor(.gray)
                    .padding(.trailing, 4)
            }
        }
        .padding(.horizontal, 16)
    }

    private var bubbleBackground: some View {
        Group {
            if message.isFromUser {
                // Pink gradient for user messages
                LinearGradient(
                    colors: [
                        Color(red: 1.0, green: 0.61, blue: 0.87),   // #FE9CDD
                        Color(red: 0.94, green: 0.50, blue: 0.78)   // #F080C8
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            } else {
                // Gray bubble for incoming - adapts to color scheme
                colorScheme == .dark
                    ? Color(red: 0.22, green: 0.22, blue: 0.23)  // #383838
                    : Color(red: 0.93, green: 0.93, blue: 0.94)
            }
        }
    }
}

// MARK: - Bubble Shape

struct BubbleShape: Shape {
    let isFromUser: Bool

    func path(in rect: CGRect) -> Path {
        let radius: CGFloat = 18
        let tailSize: CGFloat = 6

        var path = Path()

        if isFromUser {
            // User message - tail on right
            path.move(to: CGPoint(x: rect.minX + radius, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX - radius, y: rect.minY))
            path.addQuadCurve(
                to: CGPoint(x: rect.maxX, y: rect.minY + radius),
                control: CGPoint(x: rect.maxX, y: rect.minY)
            )
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - radius))
            // Tail
            path.addQuadCurve(
                to: CGPoint(x: rect.maxX + tailSize, y: rect.maxY),
                control: CGPoint(x: rect.maxX, y: rect.maxY)
            )
            path.addQuadCurve(
                to: CGPoint(x: rect.maxX - radius, y: rect.maxY),
                control: CGPoint(x: rect.maxX - tailSize, y: rect.maxY)
            )
            path.addLine(to: CGPoint(x: rect.minX + radius, y: rect.maxY))
            path.addQuadCurve(
                to: CGPoint(x: rect.minX, y: rect.maxY - radius),
                control: CGPoint(x: rect.minX, y: rect.maxY)
            )
            path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + radius))
            path.addQuadCurve(
                to: CGPoint(x: rect.minX + radius, y: rect.minY),
                control: CGPoint(x: rect.minX, y: rect.minY)
            )
        } else {
            // Incoming message - tail on left
            path.move(to: CGPoint(x: rect.minX + radius, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX - radius, y: rect.minY))
            path.addQuadCurve(
                to: CGPoint(x: rect.maxX, y: rect.minY + radius),
                control: CGPoint(x: rect.maxX, y: rect.minY)
            )
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - radius))
            path.addQuadCurve(
                to: CGPoint(x: rect.maxX - radius, y: rect.maxY),
                control: CGPoint(x: rect.maxX, y: rect.maxY)
            )
            path.addLine(to: CGPoint(x: rect.minX + radius, y: rect.maxY))
            // Tail
            path.addQuadCurve(
                to: CGPoint(x: rect.minX - tailSize, y: rect.maxY),
                control: CGPoint(x: rect.minX + tailSize, y: rect.maxY)
            )
            path.addQuadCurve(
                to: CGPoint(x: rect.minX, y: rect.maxY - radius),
                control: CGPoint(x: rect.minX, y: rect.maxY)
            )
            path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + radius))
            path.addQuadCurve(
                to: CGPoint(x: rect.minX + radius, y: rect.minY),
                control: CGPoint(x: rect.minX, y: rect.minY)
            )
        }

        return path
    }
}

#Preview {
    VStack(spacing: 16) {
        SimulatorMessageBubble(
            message: SimulatorMessage(
                content: "Hey, I miss you",
                isFromUser: true,
                deliveryStatus: .delivered
            )
        )

        SimulatorMessageBubble(
            message: SimulatorMessage(
                content: "k",
                isFromUser: false,
                deliveryStatus: .none
            )
        )

        SimulatorMessageBubble(
            message: SimulatorMessage(
                content: "Can we talk?",
                isFromUser: true,
                deliveryStatus: .readNow()
            )
        )
    }
    .padding()
    .background(Color(red: 0.98, green: 0.96, blue: 0.97))
}
