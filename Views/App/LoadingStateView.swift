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
        AuthLoadingView()
            .transition(.opacity)
            .id("authLoadingView")
    }
}

#Preview {
    LoadingStateView()
}
