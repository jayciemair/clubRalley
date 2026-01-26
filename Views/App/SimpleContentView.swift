//
//  SimpleContentView.swift
//  Club Ralley
//
//  Minimal test view to debug app launch
//

import SwiftUI

struct SimpleContentView: View {
    var body: some View {
        VStack(spacing: 20) {
            Text("🎯 Club Ralley")
                .font(.title.bold())
            
            Text("App is working!")
                .font(.body)
            
            Text("If you see this, the basic app structure is fine.")
                .font(.caption)
                .multilineTextAlignment(.center)
                .padding()
        }
        .padding()
    }
}