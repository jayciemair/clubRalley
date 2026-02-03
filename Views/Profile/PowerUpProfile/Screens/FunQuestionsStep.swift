//
//  FunQuestionsStep.swift
//  Club Ralley
//
//  Step 5: Fun personality questions for Power Up Profile
//

import SwiftUI

struct FunQuestionsStep: View {
    @EnvironmentObject var viewModel: PowerUpProfileViewModel
    @FocusState private var focusedField: Field?

    enum Field {
        case proTeam, hometown
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 28) {
                // Header
                VStack(spacing: 12) {
                    Text(PowerUpStep.funQuestions.title)
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.black)
                        .multilineTextAlignment(.center)

                    Text(PowerUpStep.funQuestions.subtitle)
                        .font(.system(size: 16))
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 24)
                .padding(.top, 40)

                // Favorite pro sports team
                VStack(alignment: .leading, spacing: 12) {
                    Text("Favorite pro sports team?")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)

                    TextField("e.g. Lakers, Patriots, Yankees...", text: $viewModel.data.favoriteProTeam)
                        .font(.system(size: 16))
                        .padding(14)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(.systemGray6))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(focusedField == .proTeam ? ClubRalleyTheme.Colors.darkGreen : Color.clear, lineWidth: 2)
                        )
                        .focused($focusedField, equals: .proTeam)
                }
                .padding(.horizontal, 24)

                // Workout brands
                VStack(alignment: .leading, spacing: 12) {
                    Text("Favorite workout brands?")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)

                    PowerUpTagGrid(
                        items: WorkoutBrandOptions.brands,
                        selectedItems: $viewModel.data.workoutBrands
                    )
                }
                .padding(.horizontal, 24)

                // Workout classes
                VStack(alignment: .leading, spacing: 12) {
                    Text("Favorite type of workout class?")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)

                    PowerUpTagGrid(
                        items: WorkoutClassOptions.classes,
                        selectedItems: $viewModel.data.workoutClasses
                    )
                }
                .padding(.horizontal, 24)

                // Hometown
                VStack(alignment: .leading, spacing: 12) {
                    Text("Hometown")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)

                    TextField("City, State", text: $viewModel.data.hometown)
                        .font(.system(size: 16))
                        .textInputAutocapitalization(.words)
                        .padding(14)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(.systemGray6))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(focusedField == .hometown ? ClubRalleyTheme.Colors.darkGreen : Color.clear, lineWidth: 2)
                        )
                        .focused($focusedField, equals: .hometown)
                }
                .padding(.horizontal, 24)

                // Happy hour question
                VStack(alignment: .leading, spacing: 12) {
                    YesNoToggle(
                        question: "Would you go to happy hour after a workout?",
                        value: $viewModel.data.wouldDoHappyHour
                    )
                }
                .padding(.horizontal, 24)

                // Bottom padding for scroll
                Color.clear.frame(height: 120)
            }
        }
        .onTapGesture {
            focusedField = nil
        }
    }
}

// MARK: - Tag Grid for Multi-Select

struct PowerUpTagGrid: View {
    let items: [String]
    @Binding var selectedItems: [String]

    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 90), spacing: 8)], spacing: 8) {
            ForEach(items, id: \.self) { item in
                PowerUpTagButton(
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

struct PowerUpTagButton: View {
    let title: String
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            Text(title)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(isSelected ? .white : .primary)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(isSelected ? ClubRalleyTheme.Colors.darkGreen : Color(.systemGray6))
                )
                .overlay(
                    Capsule()
                        .stroke(isSelected ? ClubRalleyTheme.Colors.darkGreen : Color(.systemGray5), lineWidth: 1)
                )
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isSelected ? 1.02 : 1.0)
        .animation(.easeInOut(duration: 0.15), value: isSelected)
    }
}

// MARK: - Preview

struct FunQuestionsStep_Previews: PreviewProvider {
    static var previews: some View {
        FunQuestionsStep()
            .environmentObject(PowerUpProfileViewModel())
    }
}
