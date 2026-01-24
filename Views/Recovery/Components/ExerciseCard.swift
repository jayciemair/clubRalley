//
//  ExerciseCard.swift
//  Checkpoint
//
//  Colorful gradient card component for exercises
//

import SwiftUI

struct ExerciseCard: View {
    let exercise: Exercise
    let lessonIndex: Int
    let onTap: (() -> Void)?

    private var lessonColor: AppTheme.LessonColors.LessonColor {
        AppTheme.LessonColors.color(for: lessonIndex)
    }

    var body: some View {
        ZStack(alignment: .topTrailing) {
            ZStack {
                // Gradient background using theme colors
                LinearGradient(
                    colors: [lessonColor.primary, lessonColor.light],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                HStack(alignment: .top) {
                    // Left: Text content
                    VStack(alignment: .leading, spacing: 6) {
                        Text(exercise.title)
                            .font(.custom("Satoshi-Bold", size: 19))
                            .foregroundColor(.white)
                            .lineLimit(2)
                            .fixedSize(horizontal: false, vertical: true)

                        Text(exercise.subtitle)
                            .font(.custom("Satoshi-Regular", size: 14))
                            .foregroundColor(.white)
                            .lineLimit(1)
                    }

                    Spacer()

                    // Right: Icon
                    Image(systemName: exercise.icon)
                        .font(.system(size: 32, weight: .medium))
                        .foregroundColor(.white)
                }
                .padding(20)
            }
            .frame(minHeight: 100)
            .cornerRadius(20)
            .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
            .opacity(exercise.isLocked ? 0.5 : 1.0)

            // Completion badge in top-right corner
            if exercise.isCompleted {
                ZStack {
                    Circle()
                        .fill(Color.white)
                        .frame(width: 28, height: 28)

                    Circle()
                        .fill(Color.green)
                        .frame(width: 24, height: 24)

                    Image(systemName: "checkmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white)
                }
                .offset(x: -8, y: 8)
            } else if exercise.isLocked {
                // Lock badge in top-right corner
                ZStack {
                    Circle()
                        .fill(Color.white)
                        .frame(width: 28, height: 28)

                    Circle()
                        .fill(Color.gray)
                        .frame(width: 24, height: 24)

                    Image(systemName: "lock.fill")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white)
                }
                .offset(x: -8, y: 8)
            }
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 16) {
        // Lesson 0 (Gold)
        ExerciseCard(
            exercise: Exercise(
                id: UUID(),
                type: .calmingTechniques,
                slug: "calming_techniques",
                title: "Practice Calming Techniques",
                subtitle: "Prepare when urges hit",
                icon: "wind",
                duration: 5,
                isCompleted: false,
                isLocked: false
            ),
            lessonIndex: 0,
            onTap: nil
        )

        // Lesson 1 (Pink) - Completed
        ExerciseCard(
            exercise: Exercise(
                id: UUID(),
                type: .replaceRush,
                slug: "replace_rush",
                title: "Replace the Rush",
                subtitle: "Healthy habits instead",
                icon: "bolt.fill",
                duration: 4,
                isCompleted: true,
                isLocked: false
            ),
            lessonIndex: 1,
            onTap: nil
        )

        // Lesson 2 (Orange) - Locked
        ExerciseCard(
            exercise: Exercise(
                id: UUID(),
                type: .selfExclusion,
                slug: "self_exclusion",
                title: "Self Exclusion Guide",
                subtitle: "Block access permanently",
                icon: "hand.raised.fill",
                duration: 6,
                isCompleted: false,
                isLocked: true
            ),
            lessonIndex: 2,
            onTap: nil
        )
    }
    .padding()
    .background(Color.white)
}
