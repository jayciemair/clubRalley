//
//  CardNavigationModule.swift
//  Checkpoint
//
//  Universal card navigation component for recovery modules
//

import SwiftUI
import StoreKit

// MARK: - Module Card Model

struct ModuleCard: Identifiable {
    let id = UUID()
    let emoji: String
    let title: String
    let description: String
    let practiceAction: (() -> Void)?

    init(emoji: String, title: String, description: String, practiceAction: (() -> Void)? = nil) {
        self.emoji = emoji
        self.title = title
        self.description = description
        self.practiceAction = practiceAction
    }
}

// MARK: - Card Navigation Module

struct CardNavigationModule: View {
    let moduleTitle: String
    let moduleSubtitle: String
    let cards: [ModuleCard]
    let lessonIndex: Int
    let onComplete: () -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.requestReview) private var requestReview
    @State private var currentCardIndex = 0
    @State private var navigationDirection: NavigationDirection = .forward
    @State private var showingCompletionCard = false
    @State private var showCompletionHUD = false
    @State private var dragOffset: CGFloat = 0

    /// Colors derived from AppTheme based on lesson index
    private var lessonColor: AppTheme.LessonColors.LessonColor {
        AppTheme.LessonColors.color(for: lessonIndex)
    }

    enum NavigationDirection {
        case forward
        case backward
    }

    private var currentCard: ModuleCard {
        cards[currentCardIndex]
    }

    private var isFirstCard: Bool {
        currentCardIndex == 0 && !showingCompletionCard
    }

    private var isLastCard: Bool {
        currentCardIndex == cards.count - 1 && !showingCompletionCard
    }

    private var totalCards: Int {
        cards.count + 1 // +1 for completion card
    }

    private var currentPosition: Int {
        showingCompletionCard ? cards.count : currentCardIndex
    }

    @ViewBuilder
    private var cardContent: some View {
        if showingCompletionCard {
            // Completion card - vertically centered
            VStack(spacing: 24) {
                Spacer()

                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.3))
                        .frame(width: 100, height: 100)

                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.white)
                }

                VStack(spacing: 12) {
                    Text("Module Completed")
                        .font(.custom("Satoshi-Bold", size: 28))
                        .foregroundColor(.white)

                    Text("Great work finishing this module.\nYou're building the foundation for recovery.")
                        .font(.custom("Satoshi-Regular", size: 17))
                        .foregroundColor(.white.opacity(0.8))
                        .lineSpacing(6)
                        .multilineTextAlignment(.center)
                }

                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.horizontal, 32)
        } else {
            // Regular module card content
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Emoji at top
                    Text(currentCard.emoji)
                        .font(.system(size: 56))

                    // Title
                    Text(currentCard.title)
                        .font(.custom("Satoshi-Bold", size: 26))
                        .foregroundColor(.white)

                    // Description
                    Text(currentCard.description)
                        .font(.custom("Satoshi-Regular", size: 17))
                        .foregroundColor(.white.opacity(0.85))
                        .lineSpacing(8)

                    // Practice button (if provided)
                    if let practiceAction = currentCard.practiceAction {
                        Button(action: practiceAction) {
                            Text("Practice")
                                .font(.custom("Satoshi-Bold", size: 16))
                                .foregroundColor(lessonColor.primary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(Color.white)
                                .cornerRadius(12)
                        }
                        .padding(.top, 8)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .topLeading)
                .padding(.horizontal, 28)
                .padding(.top, 100) // Space for header
                .padding(.bottom, 140) // Space for navigation
            }
            .scrollIndicators(.hidden)
        }
    }

    var body: some View {
        ZStack {
            // Full-screen gradient background (primary to light, like ExerciseCard)
            LinearGradient(
                colors: [lessonColor.primary, lessonColor.light],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            // Card content with swipe gesture
            cardContent
                .offset(x: dragOffset)
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            // Only allow dragging if there's somewhere to go
                            let canGoBack = !isFirstCard || showingCompletionCard
                            let canGoForward = !showingCompletionCard

                            if value.translation.width > 0 && canGoBack {
                                dragOffset = value.translation.width * 0.4
                            } else if value.translation.width < 0 && canGoForward {
                                dragOffset = value.translation.width * 0.4
                            }
                        }
                        .onEnded { value in
                            let threshold: CGFloat = 50

                            if value.translation.width > threshold && (!isFirstCard || showingCompletionCard) {
                                // Swipe right - go back
                                goToPrevious()
                            } else if value.translation.width < -threshold && !showingCompletionCard {
                                // Swipe left - go forward
                                goToNext()
                            }

                            withAnimation(.easeOut(duration: 0.2)) {
                                dragOffset = 0
                            }
                        }
                )
                .transition(.asymmetric(
                    insertion: .move(edge: navigationDirection == .forward ? .trailing : .leading).combined(with: .opacity),
                    removal: .move(edge: navigationDirection == .forward ? .leading : .trailing).combined(with: .opacity)
                ))
                .id(showingCompletionCard ? "completion-card" : currentCard.id.uuidString)

            // Overlay UI
            VStack(spacing: 0) {
                // Top bar: X button and module title (X hidden on completion card)
                HStack(alignment: .top) {
                    if !showingCompletionCard {
                        Button(action: { dismiss() }) {
                            Image(systemName: "xmark")
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(width: 36, height: 36)
                                .background(Color.white.opacity(0.2))
                                .clipShape(Circle())
                        }
                    } else {
                        // Placeholder to maintain layout
                        Color.clear
                            .frame(width: 36, height: 36)
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 4) {
                        Text(moduleTitle)
                            .font(.custom("Satoshi-Bold", size: 15))
                            .foregroundColor(.white)
                            .lineLimit(2)
                            .multilineTextAlignment(.trailing)
                    }
                    .frame(maxWidth: 200)
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)

                Spacer()

                // Bottom: Progress dots + Navigation buttons
                VStack(spacing: 20) {
                    // Progress dots
                    HStack(spacing: 6) {
                        ForEach(0..<totalCards, id: \.self) { index in
                            Circle()
                                .fill(index == currentPosition ? Color.white : Color.white.opacity(0.3))
                                .frame(width: index == currentPosition ? 8 : 6, height: index == currentPosition ? 8 : 6)
                                .animation(.easeInOut(duration: 0.2), value: currentPosition)
                        }
                    }

                    // Navigation buttons
                    HStack(spacing: 12) {
                        // Previous button
                        Button(action: goToPrevious) {
                            HStack(spacing: 6) {
                                Image(systemName: "chevron.left")
                                    .font(.system(size: 14, weight: .bold))
                                Text("Previous")
                                    .font(.custom("Satoshi-Bold", size: 15))
                            }
                            .foregroundColor(isFirstCard ? .white.opacity(0.3) : .white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.white.opacity(isFirstCard ? 0.1 : 0.2))
                            .cornerRadius(12)
                        }
                        .disabled(isFirstCard)

                        // Next/Done button (green when Done)
                        Button(action: goToNext) {
                            HStack(spacing: 6) {
                                Text(showingCompletionCard ? "Done" : "Next")
                                    .font(.custom("Satoshi-Bold", size: 15))
                                if !showingCompletionCard {
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 14, weight: .bold))
                                }
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(showingCompletionCard ? Color.green : Color.white.opacity(0.25))
                            .cornerRadius(12)
                        }
                    }
                    .padding(.horizontal, 20)
                }
                .padding(.bottom, 40)
            }
        }
        .navigationBarBackButtonHidden(true)
        .moduleCompletionHUD(
            isShowing: $showCompletionHUD,
            moduleTitle: moduleTitle,
            moduleColor: lessonColor.primary,
            onDismiss: {
                // Save completion and dismiss
                Task {
                    print("🟠 HUD dismissed, calling onComplete()")
                    await MainActor.run {
                        onComplete()
                        dismiss()
                    }
                }
            }
        )
    }

    // MARK: - Navigation Actions

    private func goToPrevious() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()

        if showingCompletionCard {
            navigationDirection = .backward
            withAnimation(.easeInOut(duration: 0.3)) {
                showingCompletionCard = false
            }
        } else if currentCardIndex > 0 {
            navigationDirection = .backward
            withAnimation(.easeInOut(duration: 0.3)) {
                currentCardIndex -= 1
            }
        }
    }

    private func goToNext() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()

        if showingCompletionCard {
            print("🟠 Done button pressed on completion card")

            // Request App Store review (only for first 3 lessons)
            if lessonIndex < 3 {
                print("🟠 Requesting App Store review for lesson \(lessonIndex)")
                requestReview()
            }

            // Show the celebration HUD
            showCompletionHUD = true
        } else if isLastCard {
            navigationDirection = .forward
            withAnimation(.easeInOut(duration: 0.3)) {
                showingCompletionCard = true
            }
        } else {
            navigationDirection = .forward
            withAnimation(.easeInOut(duration: 0.3)) {
                currentCardIndex += 1
            }
        }
    }
}

// MARK: - Preview

#Preview {
    CardNavigationModule(
        moduleTitle: "Practice Calming Techniques",
        moduleSubtitle: "Use these when urges hit",
        cards: [
            ModuleCard(
                emoji: "🫁",
                title: "Box Breathing",
                description: "Breathe in for 4 seconds, hold for 4 seconds, breathe out for 4 seconds, hold for 4 seconds."
            ),
            ModuleCard(
                emoji: "👁️",
                title: "5-4-3-2-1 Grounding",
                description: "Name 5 things you can see, 4 things you can touch, 3 things you can hear, 2 things you can smell, 1 thing you can taste."
            ),
            ModuleCard(
                emoji: "💧",
                title: "Cold Water Reset",
                description: "Splash cold water on your face for 30 seconds to activate the dive reflex."
            )
        ],
        lessonIndex: 0,
        onComplete: {}
    )
}
