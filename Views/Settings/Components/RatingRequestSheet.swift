//
//  RatingRequestSheet.swift
//  Checkpoint
//
//  Half-modal sheet requesting App Store rating
//

import SwiftUI

struct RatingRequestSheet: View {

    @Binding var isPresented: Bool
    let onAccept: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Spacer()
                .frame(height: 24)

            // Message in a card
            VStack(alignment: .leading, spacing: 12) {
                Text("hey, it's the founder!")
                    .font(.custom("Satoshi-Bold", size: 18))
                    .foregroundColor(Color(hex: "#4A2040"))

                (Text("it would mean so much if you left a ")
                    .foregroundColor(Color(hex: "#4A2040"))
                + Text("5-star review")
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                Color(hex: "#E080C0"),
                                Color(hex: "#F0A0C0")
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .fontWeight(.bold)
                + Text(" to help other girls get over him too.")
                    .foregroundColor(Color(hex: "#4A2040")))
                    .font(.custom("Satoshi-Regular", size: 16))
                    .multilineTextAlignment(.leading)
                    .lineSpacing(5)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(20)
            .background(Color.white.opacity(0.6))
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.white.opacity(0.3), lineWidth: 1)
            )

            // Buttons
            VStack(spacing: 8) {
                // Accept button
                Button(action: {
                    let impact = UIImpactFeedbackGenerator(style: .medium)
                    impact.impactOccurred()
                    isPresented = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        onAccept()
                    }
                }) {
                    Text("i'm in")
                        .font(.custom("Satoshi-Bold", size: 17))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            LinearGradient(
                                colors: [
                                    Color(hex: "#E080C0"),
                                    Color(hex: "#D070B0")
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(20)
                }

                // Decline button
                Button(action: {
                    let impact = UIImpactFeedbackGenerator(style: .light)
                    impact.impactOccurred()
                    isPresented = false
                }) {
                    Text("not now")
                        .font(.custom("Satoshi-Medium", size: 17))
                        .foregroundColor(Color(hex: "#6A3060").opacity(0.7))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                }
            }
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 20)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            LinearGradient(
                colors: [
                    Color(hex: "#F8C8DC"),
                    Color(hex: "#F0A0C0"),
                    Color(hex: "#E890B8")
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .presentationDetents([.height(300)])
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(24)
    }
}

#Preview {
    Color.black
        .sheet(isPresented: .constant(true)) {
            RatingRequestSheet(isPresented: .constant(true), onAccept: {})
        }
}
