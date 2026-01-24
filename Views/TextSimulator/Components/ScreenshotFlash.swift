//
//  ScreenshotFlash.swift
//  goh
//
//  Screenshot flash animation and alert for text simulator
//

import SwiftUI

struct ScreenshotFlash: View {
    @Binding var isShowing: Bool

    var body: some View {
        if isShowing {
            Color.white
                .ignoresSafeArea()
                .opacity(isShowing ? 1 : 0)
                .animation(.easeOut(duration: 0.15), value: isShowing)
                .onAppear {
                    // Flash briefly then hide
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                        isShowing = false
                    }
                }
        }
    }
}

struct ScreenshotAlert: View {
    @Binding var isShowing: Bool
    let onDismiss: () -> Void

    var body: some View {
        if isShowing {
            VStack(spacing: 0) {
                Spacer()

                VStack(spacing: 16) {
                    // Icon
                    ZStack {
                        Circle()
                            .fill(Color.orange.opacity(0.2))
                            .frame(width: 60, height: 60)

                        Image(systemName: "camera.viewfinder")
                            .font(.system(size: 28))
                            .foregroundColor(.orange)
                    }

                    // Title
                    Text("He screenshotted your message")
                        .font(.custom("Satoshi-Bold", size: 18))
                        .foregroundColor(.black)
                        .multilineTextAlignment(.center)

                    // Subtitle
                    Text("This is what happens when you text him. He shows it to everyone.")
                        .font(.custom("Satoshi-Regular", size: 14))
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)

                    // Dismiss button
                    Button(action: {
                        withAnimation {
                            isShowing = false
                        }
                        onDismiss()
                    }) {
                        Text("I understand")
                            .font(.custom("Satoshi-Medium", size: 16))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Color.orange)
                            .cornerRadius(12)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                }
                .padding(.vertical, 24)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.white)
                )
                .shadow(color: Color.black.opacity(0.15), radius: 20)
                .padding(.horizontal, 24)

                Spacer()
            }
            .background(
                Color.black.opacity(0.5)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation {
                            isShowing = false
                        }
                        onDismiss()
                    }
            )
            .transition(.opacity)
        }
    }
}

#Preview {
    ZStack {
        Color(red: 0.98, green: 0.96, blue: 0.97)
            .ignoresSafeArea()

        ScreenshotAlert(
            isShowing: .constant(true),
            onDismiss: {}
        )
    }
}
