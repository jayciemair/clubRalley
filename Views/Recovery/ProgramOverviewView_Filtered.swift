//
//  ProgramOverviewView_Filtered.swift
//  Checkpoint
//
//  Colorful cards with unit filter toggle at top
//

import SwiftUI

struct ProgramOverviewView_Filtered: View {
    @ObservedObject var viewModel: RecoveryProgramViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var navigationPath = NavigationPath()
    @State private var selectedUnit: Int = 1 // Filter by unit
    @State private var showLockedAlert = false
    @State private var lockedExercise: Exercise?
    @State private var trialDaysRemaining: Int? = nil

    private var exercises: [Exercise] {
        viewModel.exercises
    }

    /// Get the exercises for the currently selected unit
    private var filteredExercises: [Exercise] {
        guard let currentUnit = viewModel.weeks.first(where: { $0.weekNumber == selectedUnit }) else {
            return []
        }
        return currentUnit.days
    }

    /// Get the index of an exercise in the full exercises array (for lock logic)
    private func globalIndex(for exercise: Exercise) -> Int {
        exercises.firstIndex(where: { $0.id == exercise.id }) ?? 0
    }

    /// Get the index of an exercise within its unit (for color assignment)
    private func indexWithinUnit(for exercise: Exercise) -> Int {
        filteredExercises.firstIndex(where: { $0.id == exercise.id }) ?? 0
    }

    private func lockReason(for exercise: Exercise) -> String {
        let index = globalIndex(for: exercise)

        // Check if user is on free trial trying to access Lesson 4+
        if index >= 3 && StoreManager.shared.hasActiveSubscription {
            // They have active subscription, but might be trial
            // If they're hitting this lock, they must be trial (paid users would have access)
            if let daysLeft = trialDaysRemaining {
                if daysLeft == 0 {
                    return "This module unlocks today when your trial converts"
                } else if daysLeft == 1 {
                    return "This module unlocks in 1 day"
                } else {
                    return "This module unlocks in \(daysLeft) days"
                }
            }
            return "This module is only available with an active subscription (not free trials)"
        }

        // Check if non-subscriber trying to access any locked content
        if !StoreManager.shared.hasActiveSubscription {
            return "Subscribe to unlock this module"
        }

        // If we get here, user has paid subscription but module is sequentially locked
        if index > 0 {
            let previousExercise = exercises[index - 1]
            return "Complete \"\(previousExercise.title)\" first"
        }

        return "Complete the previous module first"
    }

    var body: some View {
        let _ = print("🔴 ProgramOverviewView_Filtered body re-rendering")

        return NavigationStack(path: $navigationPath) {
            ZStack {
                // Beautiful gradient background
                RecoveryGradientBackground()

                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        // X button at top
                        HStack {
                            Button(action: { dismiss() }) {
                                Image(systemName: "xmark")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(AppTheme.Colors.textPrimary)
                            }
                            Spacer()
                        }
                        .padding(.horizontal, AppTheme.Spacing.lg)
                        .padding(.top, 20)

                        // Header
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Recovery Program")
                                .font(.custom("Satoshi-Bold", size: 32))
                                .foregroundColor(AppTheme.Colors.textPrimary)

                            Text("Complete units at your own pace")
                                .font(.custom("Satoshi-Regular", size: 16))
                                .foregroundColor(AppTheme.Colors.textSecondary)
                        }
                        .padding(.horizontal, AppTheme.Spacing.lg)

                        // Unit selector toggle
                        HStack(spacing: 12) {
                            ForEach(1...4, id: \.self) { unit in
                                Button(action: {
                                    let generator = UIImpactFeedbackGenerator(style: .light)
                                    generator.impactOccurred()

                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        selectedUnit = unit
                                    }
                                }) {
                                    let unitData = viewModel.weeks.first(where: { $0.weekNumber == unit })
                                    let isCompleted = unitData?.isCompleted ?? false

                                    VStack(spacing: 4) {
                                        HStack(spacing: 4) {
                                            Text("Unit \(unit)")
                                                .font(.custom("Satoshi-Bold", size: 14))
                                                .foregroundColor(
                                                    isCompleted ? .green :
                                                    (selectedUnit == unit ? AppTheme.Colors.textPrimary : AppTheme.Colors.textSecondary)
                                                )

                                            // Checkmark for completed units
                                            if isCompleted {
                                                Image(systemName: "checkmark.circle.fill")
                                                    .font(.system(size: 12))
                                                    .foregroundColor(.green)
                                            }
                                        }

                                        // Progress indicator
                                        if let unitData = unitData {
                                            Text("\(unitData.completedCount)/\(unitData.totalCount)")
                                                .font(.custom("Satoshi-Medium", size: 11))
                                                .foregroundColor(
                                                    isCompleted ? .green.opacity(0.8) :
                                                    (selectedUnit == unit ? AppTheme.Colors.textPrimary : AppTheme.Colors.textSecondary.opacity(0.7))
                                                )
                                        }
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(
                                        isCompleted ?
                                        Color.green.opacity(0.15) :
                                        (selectedUnit == unit ? AppTheme.Colors.textPrimary.opacity(0.05) : Color.clear)
                                    )
                                    .cornerRadius(12)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(
                                                selectedUnit == unit ?
                                                AppTheme.Colors.textPrimary.opacity(0.3) :
                                                (isCompleted ?
                                                Color.green.opacity(0.4) :
                                                AppTheme.Colors.textSecondary.opacity(0.2)),
                                                lineWidth: selectedUnit == unit ? 2 : 1
                                            )
                                    )
                                }
                            }
                        }
                        .padding(.horizontal, AppTheme.Spacing.lg)

                        // Unit title
                        if let currentUnit = viewModel.weeks.first(where: { $0.weekNumber == selectedUnit }) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(currentUnit.title)
                                    .font(.custom("Satoshi-Bold", size: 20))
                                    .foregroundColor(AppTheme.Colors.textPrimary)

                                Text(currentUnit.subtitle)
                                    .font(.custom("Satoshi-Regular", size: 14))
                                    .foregroundColor(AppTheme.Colors.textSecondary)
                            }
                            .padding(.horizontal, AppTheme.Spacing.lg)
                        }

                        // Progress indicator for selected unit (show for all units)
                        if let currentUnit = viewModel.weeks.first(where: { $0.weekNumber == selectedUnit }),
                           currentUnit.totalCount > 0 {
                            let completed = currentUnit.completedCount
                            let total = currentUnit.totalCount

                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text("\(completed) of \(total) modules completed")
                                        .font(.custom("Satoshi-Medium", size: 15))
                                        .foregroundColor(AppTheme.Colors.textPrimary)

                                    Spacer()

                                    Text("\(Int((Double(completed) / Double(total)) * 100))%")
                                        .font(.custom("Satoshi-Bold", size: 15))
                                        .foregroundColor(AppTheme.Colors.textSecondary)
                                }

                                // Progress bar
                                GeometryReader { geometry in
                                    ZStack(alignment: .leading) {
                                        Capsule()
                                            .fill(AppTheme.Colors.textSecondary.opacity(0.2))
                                            .frame(height: 8)

                                        Capsule()
                                            .fill(
                                                LinearGradient(
                                                    colors: [.green, .green.opacity(0.7)],
                                                    startPoint: .leading,
                                                    endPoint: .trailing
                                                )
                                            )
                                            .frame(
                                                width: geometry.size.width * (Double(completed) / Double(total)),
                                                height: 8
                                            )
                                    }
                                }
                                .frame(height: 8)
                            }
                            .padding(.horizontal, AppTheme.Spacing.lg)
                        }

                        // Module cards (filtered by unit)
                        VStack(spacing: 12) {
                            ForEach(filteredExercises) { exercise in
                                let colorIndex = indexWithinUnit(for: exercise)

                                if exercise.isLocked {
                                    // Locked card - show alert on tap
                                    Button(action: {
                                        let generator = UIImpactFeedbackGenerator(style: .medium)
                                        generator.impactOccurred()
                                        lockedExercise = exercise
                                        showLockedAlert = true
                                    }) {
                                        ExerciseCard(exercise: exercise, lessonIndex: colorIndex, onTap: nil)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                    .id("\(exercise.id)-\(exercise.isCompleted)-\(exercise.isLocked)")
                                } else {
                                    // Unlocked card - navigate normally
                                    NavigationLink(value: exercise) {
                                        ExerciseCard(exercise: exercise, lessonIndex: colorIndex, onTap: {
                                            let generator = UIImpactFeedbackGenerator(style: .medium)
                                            generator.impactOccurred()
                                        })
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                    .simultaneousGesture(TapGesture().onEnded { _ in
                                        let generator = UIImpactFeedbackGenerator(style: .medium)
                                        generator.impactOccurred()
                                    })
                                    .id("\(exercise.id)-\(exercise.isCompleted)")
                                }
                            }
                        }
                        .id(filteredExercises.map { $0.isCompleted }.description)
                        .padding(.horizontal, AppTheme.Spacing.lg)

                        // Spacer at bottom
                        Color.clear.frame(height: 40)
                    }
                }
                .scrollIndicators(.hidden)
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .onAppear {
                Task {
                    await viewModel.refreshCompletions()
                    trialDaysRemaining = await RecoveryProgressService.daysRemainingInTrial()
                }
            }
            .alert("Module Locked", isPresented: $showLockedAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                if let exercise = lockedExercise {
                    Text(lockReason(for: exercise))
                }
            }
            .navigationDestination(for: Exercise.self) { exercise in
                exerciseView(for: exercise)
            }
        }
    }

    /// Get the index of an exercise within its unit (for navigation destination)
    private func colorIndexForExercise(_ exercise: Exercise) -> Int {
        // Find which unit contains this exercise and get its position within that unit
        for week in viewModel.weeks {
            if let index = week.days.firstIndex(where: { $0.id == exercise.id }) {
                return index
            }
        }
        return 0
    }

    @ViewBuilder
    private func exerciseView(for exercise: Exercise) -> some View {
        let colorIndex = colorIndexForExercise(exercise)

        // Get lesson content by slug
        if let lesson = RecoveryLessons.allLessons.first(where: { $0.slug == exercise.slug }) {
            // Special views with interactive features (like box breathing)
            if lesson.hasInteractiveFeature {
                CalmingTechniquesView(
                    lessonIndex: colorIndex,
                    onComplete: {
                        Task {
                            await viewModel.completeExercise(exercise)
                        }
                    }
                )
            } else {
                // All other lessons use generic card view
                GenericLessonView(
                    lesson: lesson,
                    lessonIndex: colorIndex,
                    onComplete: {
                        Task {
                            await viewModel.completeExercise(exercise)
                        }
                    }
                )
            }
        } else {
            // Fallback if lesson not found
            Text("Lesson content not found")
        }
    }
}

#Preview {
    NavigationView {
        ProgramOverviewView_Filtered(viewModel: RecoveryProgramViewModel.shared)
    }
}
