//
//  InterestsScreen.swift
//  Club Ralley
//
//  Interests and hobbies selection screen
//

import SwiftUI

struct InterestsScreen: View {
    @EnvironmentObject var controller: ClubRalleyOnboardingController
    @State private var selectedHobbies: [String] = []
    @State private var selectedWorkoutBrands: [String] = []
    @State private var selectedClassTypes: [String] = []
    @State private var hometown = ""
    @State private var favoriteTeams: [String] = []
    
    private let availableHobbies = [
        "Hiking", "Photography", "Cooking", "Reading", "Music",
        "Gaming", "Art", "Travel", "Dancing", "Yoga",
        "Meditation", "Volunteering", "Gardening", "Movies"
    ]
    
    private let workoutBrands = [
        "Nike", "Adidas", "Lululemon", "Under Armour", "Reebok",
        "New Balance", "Gymshark", "Athleta", "Patagonia", "ALO"
    ]
    
    private let classTypes = [
        "CrossFit", "Pilates", "Yoga", "Spin", "Barre",
        "Boxing", "HIIT", "Zumba", "Kickboxing", "Bootcamp"
    ]
    
    var body: some View {
        OnboardingScrollableLayout {
            VStack(spacing: 32) {
                // Header
                OnboardingHeader(
                    title: controller.currentStep.title,
                    subtitle: controller.currentStep.subtitle
                )
                
                VStack(spacing: 32) {
                    // Hobbies section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("What are your hobbies?")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        TagSelectionView(
                            items: availableHobbies,
                            selectedItems: $selectedHobbies
                        )
                    }
                    .padding(.horizontal, 32)
                    
                    // Workout brands section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Favorite workout brands?")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        TagSelectionView(
                            items: workoutBrands,
                            selectedItems: $selectedWorkoutBrands
                        )
                    }
                    .padding(.horizontal, 32)
                    
                    // Class types section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("What classes do you like?")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        TagSelectionView(
                            items: classTypes,
                            selectedItems: $selectedClassTypes
                        )
                    }
                    .padding(.horizontal, 32)
                    
                    // Hometown
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Where's your hometown? (optional)")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        OnboardingTextField(
                            title: "",
                            placeholder: "City, State",
                            text: $hometown,
                            autocapitalization: .words
                        )
                    }
                    .padding(.horizontal, 32)
                }
                
                Spacer()
                
                // Continue button
                ContinueButton(
                    title: "Continue",
                    isEnabled: hasSelectedInterests,
                    action: {
                        saveAndContinue()
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
            // Pre-populate if data exists
            let interests = controller.onboardingData.interests
            selectedHobbies = interests.hobbies
            selectedWorkoutBrands = interests.workoutBrands
            selectedClassTypes = interests.classTypes
            hometown = interests.hometown
            favoriteTeams = interests.favoriteTeams
        }
    }
    
    private var hasSelectedInterests: Bool {
        !selectedHobbies.isEmpty || 
        !selectedWorkoutBrands.isEmpty || 
        !selectedClassTypes.isEmpty
    }
    
    private func saveAndContinue() {
        controller.updateInterests(
            hobbies: selectedHobbies,
            workoutBrands: selectedWorkoutBrands,
            classTypes: selectedClassTypes,
            hometown: hometown,
            favoriteTeams: favoriteTeams
        )
        controller.goToNextStep()
    }
}

// MARK: - Tag Selection View

struct TagSelectionView: View {
    let items: [String]
    @Binding var selectedItems: [String]
    
    var body: some View {
        LazyVGrid(columns: [
            GridItem(.adaptive(minimum: 100), spacing: 8)
        ], spacing: 8) {
            ForEach(items, id: \.self) { item in
                TagButton(
                    title: item,
                    isSelected: selectedItems.contains(item),
                    onTap: {
                        toggleItem(item)
                    }
                )
            }
        }
    }
    
    private func toggleItem(_ item: String) {
        if let index = selectedItems.firstIndex(of: item) {
            selectedItems.remove(at: index)
        } else {
            selectedItems.append(item)
        }
    }
}

// MARK: - Tag Button

struct TagButton: View {
    let title: String
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            Text(title)
                .font(.subheadline)
                .foregroundColor(isSelected ? .white : .primary)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(isSelected ? Color.blue : Color(.systemGray6))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(isSelected ? Color.blue : Color(.systemGray5), lineWidth: 1)
                )
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isSelected ? 1.05 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
}

// MARK: - Preview

struct InterestsScreen_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            InterestsScreen()
                .environmentObject(ClubRalleyOnboardingController())
        }
    }
}