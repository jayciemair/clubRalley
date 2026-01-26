//
//  LoadingStateView.swift
//  Checkpoint
//
//  View for .initializing app state (checking authentication)
//  Part of MVVM refactor - extracted from ContentView
//

import SwiftUI

struct LoadingStateView: View {

    var body: some View {
        ZStack {
            Color.white
                .ignoresSafeArea()

            VStack(spacing: 20) {
                // Club Ralley logo
                ZStack {
                    Circle()
                        .fill(Color(hex: "#2C4F40"))
                        .frame(width: 80, height: 80)
                    
                    Image(systemName: "figure.run")
                        .font(.system(size: 30, weight: .bold))
                        .foregroundColor(.white)
                }

                Text("Club Ralley")
                    .font(.title.bold())
                    .foregroundColor(Color(hex: "#2C4F40"))
                
                Text("GFTO - Get the F*** Outside")
                    .font(.subheadline)
                    .foregroundColor(Color(hex: "#666666"))

                ProgressView()
                    .scaleEffect(1.2)
                    .tint(Color(hex: "#2C4F40"))
                    .padding(.top)
            }
        }
    }
}

#Preview {
    LoadingStateView()
}
