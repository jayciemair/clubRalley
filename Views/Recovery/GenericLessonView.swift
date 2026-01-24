//
//  GenericLessonView.swift
//  Checkpoint
//
//  Generic view for rendering any lesson from RecoveryLessons
//

import SwiftUI

struct GenericLessonView: View {
    let lesson: LessonContent
    let lessonIndex: Int
    let onComplete: () -> Void

    var body: some View {
        CardNavigationModule(
            moduleTitle: lesson.title,
            moduleSubtitle: lesson.subtitle,
            cards: lesson.cards,
            lessonIndex: lessonIndex,
            onComplete: onComplete
        )
    }
}

#Preview {
    NavigationView {
        GenericLessonView(
            lesson: RecoveryLessons.allLessons[3],
            lessonIndex: 3,
            onComplete: {}
        )
    }
}
