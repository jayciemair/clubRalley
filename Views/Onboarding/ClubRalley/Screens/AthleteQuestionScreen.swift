//
//  AthleteQuestionScreen.swift
//  Club Ralley
//
//  Screen asking users if they are athletes and want verification
//

import SwiftUI

struct AthleteQuestionScreen: View {
    @EnvironmentObject var controller: ClubRalleyOnboardingController
    @State private var selectedOption: AthleteOption?
    @State private var showingAnimation = false
    
    var body: some View {
        OnboardingScrollableLayout {
            VStack(spacing: 40) {
                // Header
                OnboardingHeader(
                    title: controller.currentStep.title,
                    subtitle: controller.currentStep.subtitle
                )
                
                // Athlete icon with animation
                VStack(spacing: 20) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [.blue.opacity(0.2), .purple.opacity(0.2)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 100, height: 100)
                            .scaleEffect(showingAnimation ? 1.1 : 1.0)
                            .animation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true), value: showingAnimation)
                        
                        Image(systemName: "star.circle.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.blue)
                    }
                    
                    Text("Get Verified & Stand Out")
                        .font(.title2.bold())
                        .foregroundColor(.primary)
                }
                
                // Options
                VStack(spacing: 16) {
                    AthleteOptionCard(
                        option: .currentAthlete,
                        isSelected: selectedOption == .currentAthlete,
                        onTap: { selectedOption = .currentAthlete }
                    )
                    
                    AthleteOptionCard(
                        option: .formerAthlete,
                        isSelected: selectedOption == .formerAthlete,
                        onTap: { selectedOption = .formerAthlete }
                    )
                    
                    AthleteOptionCard(
                        option: .notAthlete,
                        isSelected: selectedOption == .notAthlete,
                        onTap: { selectedOption = .notAthlete }
                    )
                }
                .padding(.horizontal, 32)
                
                // Benefits of verification
                if selectedOption == .currentAthlete || selectedOption == .formerAthlete {
                    VerificationBenefitsView()
                        .transition(.slide.combined(with: .opacity))
                }
                
                Spacer()
                
                // Continue button
                ContinueButton(
                    title: "Continue",
                    isEnabled: selectedOption != nil,
                    action: {
                        saveSelectionAndContinue()
                    }
                )
                .padding(.horizontal, 32)
                .padding(.bottom, 32)
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Back") {
                    controller.goToPreviousStep()
                }
            }
        }
        .onAppear {
            showingAnimation = true
            // Pre-populate selection if data exists
            if controller.onboardingData.athlete.isAthlete {
                selectedOption = .currentAthlete // Default to current, could be refined
            }
        }
    }
    
    private func saveSelectionAndContinue() {
        guard let option = selectedOption else { return }
        
        let isAthlete = option == .currentAthlete || option == .formerAthlete
        controller.updateAthleteStatus(isAthlete: isAthlete)
        controller.goToNextStep()
    }
}

// MARK: - Athlete Option Enum

enum AthleteOption: CaseIterable {
    case currentAthlete
    case formerAthlete
    case notAthlete
    
    var title: String {
        switch self {
        case .currentAthlete:
            return "Current College Athlete"
        case .formerAthlete:
            return "Former College Athlete"
        case .notAthlete:
            return "Not a College Athlete"
        }
    }
    
    var subtitle: String {
        switch self {
        case .currentAthlete:
            return "I currently play a sport in college"
        case .formerAthlete:
            return "I previously played a sport in college"
        case .notAthlete:
            return "I haven't played college sports"
        }
    }
    
    var icon: String {
        switch self {
        case .currentAthlete:
            return "star.fill"
        case .formerAthlete:
            return "star.leadinghalf.filled"
        case .notAthlete:
            return "person.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .currentAthlete:
            return .blue
        case .formerAthlete:
            return .purple
        case .notAthlete:
            return .green
        }
    }
}

// MARK: - Athlete Option Card

struct AthleteOptionCard: View {
    let option: AthleteOption
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // Icon
                ZStack {
                    Circle()
                        .fill(option.color.opacity(isSelected ? 0.2 : 0.1))
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: option.icon)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(isSelected ? option.color : option.color.opacity(0.6))
                }
                
                // Text content
                VStack(alignment: .leading, spacing: 4) {
                    Text(option.title)
                        .font(.headline)
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.leading)
                    
                    Text(option.subtitle)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.leading)
                }
                
                Spacer()
                
                // Selection indicator
                ZStack {
                    Circle()
                        .stroke(isSelected ? option.color : Color(.systemGray4), lineWidth: 2)
                        .frame(width: 24, height: 24)
                    
                    if isSelected {
                        Circle()
                            .fill(option.color)
                            .frame(width: 12, height: 12)
                    }
                }
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(isSelected ? option.color : Color(.systemGray5), lineWidth: isSelected ? 2 : 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isSelected ? 1.02 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
}

// MARK: - Verification Benefits View

struct VerificationBenefitsView: View {
    var body: some View {
        VStack(spacing: 16) {
            Text("🏆 Verification Benefits")
                .font(.headline)
                .foregroundColor(.primary)
            
            VStack(spacing: 12) {
                BenefitRow(icon: "checkmark.shield.fill", text: "Verified athlete badge", color: .blue)
                BenefitRow(icon: "star.fill", text: "Priority in search results", color: .purple)
                BenefitRow(icon: "person.2.fill", text: "Connect with other verified athletes", color: .green)
                BenefitRow(icon: "trophy.fill", text: "Access to exclusive events", color: .orange)
            }
            
            Text("We'll ask you to upload proof in the next step")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.blue.opacity(0.05))
        )
        .padding(.horizontal, 32)
    }
}

struct BenefitRow: View {
    let icon: String
    let text: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.subheadline)
                .foregroundColor(color)
                .frame(width: 20)
            
            Text(text)
                .font(.subheadline)
                .foregroundColor(.primary)
            
            Spacer()
        }
    }
}

// MARK: - Preview

struct AthleteQuestionScreen_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            AthleteQuestionScreen()
                .environmentObject(ClubRalleyOnboardingController())
        }
    }
}