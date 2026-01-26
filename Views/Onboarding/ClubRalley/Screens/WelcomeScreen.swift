//
//  WelcomeScreen.swift
//  Club Ralley
//
//  Welcome screen for Club Ralley onboarding
//

import SwiftUI

struct WelcomeScreen: View {
    @EnvironmentObject var controller: ClubRalleyOnboardingController
    @State private var showingAnimation = false
    
    var body: some View {
        OnboardingScrollableLayout {
            VStack(spacing: 32) {
                Spacer()
                
                // App logo/icon
                VStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [.blue, .purple],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 120, height: 120)
                            .scaleEffect(showingAnimation ? 1.05 : 1.0)
                            .animation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true), value: showingAnimation)
                        
                        Image(systemName: "figure.run")
                            .font(.system(size: 50, weight: .bold))
                            .foregroundColor(.white)
                    }
                    
                    Text("Club Ralley")
                        .font(.largeTitle.bold())
                        .foregroundColor(.primary)
                }
                
                // Tagline
                VStack(spacing: 12) {
                    Text("GFTO")
                        .font(.title.bold())
                        .foregroundColor(.blue)
                    
                    Text("Get the F*** Outside")
                        .font(.title2.bold())
                        .foregroundColor(.secondary)
                }
                
                // Value propositions
                VStack(spacing: 20) {
                    WelcomeFeature(
                        icon: "person.2.fill",
                        title: "Make New Friends",
                        description: "Connect with athletes and active people in your area"
                    )
                    
                    WelcomeFeature(
                        icon: "sportscourt.fill",
                        title: "Find Your Activity",
                        description: "Discover ralleys for every sport and fitness level"
                    )
                    
                    WelcomeFeature(
                        icon: "star.fill",
                        title: "Get Verified",
                        description: "Show your athlete credentials and unlock exclusive features"
                    )
                }
                
                Spacer()
                
                // Continue button
                Button(action: {
                    controller.goToNextStep()
                }) {
                    HStack {
                        Text("Get Started")
                            .font(.headline)
                        
                        Image(systemName: "arrow.right")
                            .font(.headline)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(12)
                }
                .padding(.horizontal, 32)
                
                // Terms text
                Text("By continuing, you agree to our Terms of Service and Privacy Policy")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                    .padding(.bottom, 32)
            }
        }
        .onAppear {
            showingAnimation = true
        }
    }
}

struct WelcomeFeature: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.1))
                    .frame(width: 44, height: 44)
                
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.blue)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer()
        }
        .padding(.horizontal, 32)
    }
}

// MARK: - Scrollable Layout Component

struct OnboardingScrollableLayout<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                content
                    .frame(minHeight: geometry.size.height)
            }
            .scrollIndicators(.hidden)
        }
    }
}

// MARK: - Preview

struct WelcomeScreen_Previews: PreviewProvider {
    static var previews: some View {
        WelcomeScreen()
            .environmentObject(ClubRalleyOnboardingController())
    }
}