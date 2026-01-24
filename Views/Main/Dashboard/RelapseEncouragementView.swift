//
//  RelapseEncouragementView.swift
//  goh
//
//  Simple encouragement screen shown after user admits they texted him
//

import SwiftUI
import UIKit

struct RelapseEncouragementView: View {
    @Binding var isPresented: Bool

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

            VStack(spacing: 32) {
                Spacer()

                // Mochi image
                Image("Mochi")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 140, height: 140)

                // Main message
                VStack(spacing: 16) {
                    Text("it's okay")
                        .font(.custom("Satoshi-Black", size: 36))
                        .foregroundColor(Color(hex: "#4A2040"))

                    Text("healing isn't linear. one text doesn't erase your progress - it's just a bump in the road.")
                        .font(.custom("Satoshi-Regular", size: 18))
                        .foregroundColor(Color(hex: "#6A3060").opacity(0.8))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                }

                // Encouragement card
                VStack(spacing: 12) {
                    Text("remember why you started")
                        .font(.custom("Satoshi-Bold", size: 17))
                        .foregroundColor(Color(hex: "#4A2040"))

                    Text("you deserve someone who chooses you. every day you don't text him, you choose yourself.")
                        .font(.custom("Satoshi-Regular", size: 15))
                        .foregroundColor(Color(hex: "#6A3060").opacity(0.7))
                        .multilineTextAlignment(.center)
                }
                .padding(24)
                .frame(maxWidth: .infinity)
                .background(Color.white.opacity(0.6))
                .cornerRadius(24)
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(Color.white.opacity(0.3), lineWidth: 1)
                )
                .padding(.horizontal, 24)

                Spacer()

                // Continue button
                Button(action: {
                    let generator = UIImpactFeedbackGenerator(style: .medium)
                    generator.impactOccurred()
                    isPresented = false
                }) {
                    Text("start fresh")
                        .font(.custom("Satoshi-Bold", size: 18))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
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
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
    }
}

// MARK: - Preview

struct RelapseEncouragementView_Previews: PreviewProvider {
    static var previews: some View {
        RelapseEncouragementView(isPresented: .constant(true))
    }
}
