//
//  RecoveryProgramViewModel.swift
//  Checkpoint
//
//  ViewModel for managing recovery program
//

import Foundation
import SwiftUI

@MainActor
class RecoveryProgramViewModel: ObservableObject {

    // MARK: - Singleton

    static let shared = RecoveryProgramViewModel()

    // MARK: - Published Properties

    @Published var exercises: [Exercise] = []
    @Published var weeks: [WeekModule] = []
    @Published var completionState: CompletionState = .notStarted
    @Published var selectedExercise: Exercise?
    @Published var showBreathingEntry = false
    @Published var isLoading = false
    @Published var error: String?

    // MARK: - Dependencies

    private let progressService = RecoveryProgressService.shared

    // MARK: - Initialization

    private init() {
        loadDailyProgram()
    }

    // MARK: - Public Methods

    /// Load the recovery program lessons
    func loadDailyProgram() {
        print("🚨 loadDailyProgram called - This resets all exercises!")
        isLoading = true

        // Load exercises from lesson content
        exercises = RecoveryLessons.allLessons.map { lesson in
            Exercise(
                id: UUID(),
                type: exerciseTypeForLesson(lesson),
                slug: lesson.slug,
                title: lesson.title,
                subtitle: lesson.subtitle,
                icon: lesson.icon,
                duration: lesson.cards.count > 0 ? lesson.cards.count * 2 : 5,
                isCompleted: false,
                isLocked: false
            )
        }

        // Build weekly structure
        buildWeeklyStructure()

        // Load completions from database
        Task {
            exercises = await progressService.loadCompletions(for: exercises)
            buildWeeklyStructure() // Rebuild after loading completions
            updateCompletionState()
            isLoading = false
        }
    }

    /// Map lesson to appropriate exercise type (for routing to views)
    private func exerciseTypeForLesson(_ lesson: LessonContent) -> ExerciseType {
        // Interactive lessons get special view routing
        if lesson.hasInteractiveFeature {
            return .calmingTechniques
        }
        return .mindfulHeadspace // All other lessons use GenericLessonView
    }

    /// Start an exercise
    func startExercise(_ exercise: Exercise) {
        guard !exercise.isLocked else { return }
        selectedExercise = exercise

            }

    /// Mark an exercise as completed
    func completeExercise(_ exercise: Exercise) async {
        print("🟢 completeExercise called for: \(exercise.title)")

        guard let index = exercises.firstIndex(where: { $0.id == exercise.id }) else {
            print("❌ Could not find exercise in array")
            return
        }

        print("📝 Marking exercise at index \(index) as completed")

        // Create a new Exercise with isCompleted = true
        var updatedExercise = exercises[index]
        updatedExercise.isCompleted = true

        // Replace the entire array to force SwiftUI to detect the change
        var newExercises = exercises
        newExercises[index] = updatedExercise
        exercises = newExercises

        print("✅ Exercise isCompleted = \(exercises[index].isCompleted)")
        print("🔄 Recreated exercises array to force UI update")

        selectedExercise = nil

        // Save to database
        print("💾 Saving to database...")
        do {
            try await progressService.saveCompletion(exercise: exercise)
        } catch {
            print("❌ Error saving completion: \(error)")
            self.error = "Failed to save progress"
        }

        // Rebuild weekly structure with updated completion
        buildWeeklyStructure()

        // Update state
        print("🔄 Updating completion state...")
        updateCompletionState()
        print("📊 New completion state: \(completionState)")

        
        // Check if all completed
        if case .completed = completionState {
            celebrateCompletion()
        }
    }

    /// Skip an exercise (still mark as complete but track differently)
    func skipExercise(_ exercise: Exercise) {
        Task {
            await completeExercise(exercise)
        }
    }

    /// Refresh completions from database (called when view appears)
    func refreshCompletions() async {
        print("🔄 refreshCompletions called")
        exercises = await progressService.loadCompletions(for: exercises)
        buildWeeklyStructure() // Rebuild weekly structure with updated completions
        updateCompletionState()
        print("✅ refreshCompletions finished")
    }

    // MARK: - Private Methods

    /// Build unit module structure from exercises
    private func buildWeeklyStructure() {
        let unitColors: [Color] = [
            Color(red: 0.85, green: 0.68, blue: 0.32), // Gold
            Color(red: 0.93, green: 0.35, blue: 0.35), // Red
            Color(red: 0.67, green: 0.28, blue: 0.74), // Purple
            Color(red: 0.26, green: 0.65, blue: 0.96)  // Blue
        ]

        let unitTitles = [
            ("Unit 1: Understanding Your Addiction", "What's happening in your brain"),
            ("Unit 2: Managing Your Urges & Cravings", "Practical tools for when the urge hits"),
            ("Unit 3: Rebuilding Your Life, Health & Finances", "Repairing relationships, finances & wellness"),
            ("Unit 4: Becoming Who You Want to Be", "Identity, purpose & meaning")
        ]

        // Dynamic lesson counts per unit based on actual lesson files
        let lessonsPerUnit = [
            Unit1Lessons.lessons.count,  // Unit 1
            Unit2Lessons.lessons.count,  // Unit 2
            Unit3Lessons.lessons.count,  // Unit 3
            Unit4Lessons.lessons.count   // Unit 4
        ]

        var currentIndex = 0
        weeks = (0..<4).compactMap { unitIndex in
            let lessonCount = lessonsPerUnit[unitIndex]
            let startDay = currentIndex
            let endDay = min(startDay + lessonCount, exercises.count)

            // Guard against invalid range (startDay >= exercises.count)
            guard startDay < exercises.count else {
                // Create locked unit with no modules
                return WeekModule(
                    id: UUID(),
                    weekNumber: unitIndex + 1,
                    title: unitTitles[unitIndex].0,
                    subtitle: unitTitles[unitIndex].1,
                    days: [],
                    color: unitColors[unitIndex]
                )
            }

            let unitModules = Array(exercises[startDay..<endDay])
            currentIndex = endDay  // Move to next week's start

            return WeekModule(
                id: UUID(),
                weekNumber: unitIndex + 1,
                title: unitTitles[unitIndex].0,
                subtitle: unitTitles[unitIndex].1,
                days: unitModules,
                color: unitColors[unitIndex]
            )
        }
    }

    private func updateCompletionState() {
        let completedCount = exercises.filter { $0.isCompleted }.count
        let totalCount = exercises.count

        if completedCount == 0 {
            completionState = .notStarted
        } else if completedCount == totalCount {
            completionState = .completed
        } else {
            completionState = .inProgress(completed: completedCount, total: totalCount)
        }
    }

    private func celebrateCompletion() {
        // Haptic feedback
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)

            }
}
