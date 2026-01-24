//
//  AuthLoadingView.swift
//  Get Over Him
//
//  Centralized loading state shown during authentication and app initialization
//

import SwiftUI

struct AuthLoadingView: View {
    @State private var isAnimating = false

    var body: some View {
        ZStack {
            // Background - matching the logo's pink
            Color(hex: "#FE9CDD")
                .ignoresSafeArea()

            // Get Over Him logo with pulsing animation
            Image("GetOverHimLogo")
                .resizable()
                .scaledToFit()
                .frame(width: 200, height: 200)
                .clipShape(RoundedRectangle(cornerRadius: 44))
                .scaleEffect(isAnimating ? 1.05 : 0.95)
                .animation(
                    Animation.easeInOut(duration: 1.2)
                        .repeatForever(autoreverses: true),
                    value: isAnimating
                )
        }
        .onAppear {
            isAnimating = true
        }
    }
}

struct AuthLoadingView_Previews: PreviewProvider {
    static var previews: some View {
        AuthLoadingView()
    }
}
