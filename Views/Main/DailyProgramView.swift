//
//  DailyProgramView.swift
//  Checkpoint
//
//  Full-screen daily recovery program view
//

import SwiftUI

struct DailyProgramView: View {
    let dayNumber: Int
    @Environment(\.dismiss) private var dismiss

    @State private var currentStep = 0
    @State private var hasCompletedCheckIn = false
    @State private var hasCompletedMeditation = false
    @State private var hasCompletedLesson = false

    // TODO: Fetch from Supabase based on dayNumber
    private var meditationTitle: String {
        "Managing Triggers"
    }

    private var lessonTitle: String {
        "The 'Just One Bet' Trap"
    }

    var body: some View {
        NavigationView {
            ZStack {
                AppTheme.Colors.background
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    // Progress indicator - modern capsule style
                    HStack(spacing: 6) {
                        ForEach(0..<3) { index in
                            Capsule()
                                .fill(currentStep >= index ? Color.purple : Color.gray.opacity(0.2))
                                .frame(width: currentStep == index ? 24 : 8, height: 8)
                                .animation(.spring(response: 0.3), value: currentStep)
                        }
                    }
                    .padding(.top, 16)
                    .padding(.bottom, 8)

                    // Content based on current step
                    TabView(selection: $currentStep) {
                        // Step 1: Morning Check-In
                        MorningCheckInView(
                            dayNumber: dayNumber,
                            onComplete: {
                                hasCompletedCheckIn = true
                                withAnimation(.spring(response: 0.3)) {
                                    currentStep = 1
                                }
                            }
                        )
                        .tag(0)

                        // Step 2: Meditation
                        MeditationPlayerView(
                            dayNumber: dayNumber,
                            title: meditationTitle,
                            onComplete: {
                                hasCompletedMeditation = true
                                withAnimation(.spring(response: 0.3)) {
                                    currentStep = 2
                                }
                            }
                        )
                        .tag(1)

                        // Step 3: Micro-Lesson
                        MicroLessonView(
                            dayNumber: dayNumber,
                            title: lessonTitle,
                            onComplete: {
                                hasCompletedLesson = true
                                // Save completion to database
                                Task {
                                    await saveCompletion()
                                    dismiss()
                                }
                            }
                        )
                        .tag(2)
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                }
            }
            .navigationTitle("Day \(dayNumber)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(AppTheme.Colors.textSecondary)
                    }
                }
            }
        }
    }

    private func saveCompletion() async {
        // TODO: Save to Supabase user_daily_checkins table
        print("Daily program completed for day \(dayNumber)")
    }
}

// MARK: - Morning Check-In View

struct MorningCheckInView: View {
    let dayNumber: Int
    let onComplete: () -> Void

    @State private var selectedMood: String?
    @State private var selectedChallenge: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Good morning! 🌅")
                        .font(.custom("Satoshi-Bold", size: 28))
                        .foregroundColor(AppTheme.Colors.textPrimary)

                    Text("Today is Day \(dayNumber) of your recovery.")
                        .font(.custom("Satoshi-Regular", size: 16))
                        .foregroundColor(AppTheme.Colors.textSecondary)
                }
                .padding(.horizontal)

                // Mood selection
                VStack(alignment: .leading, spacing: 12) {
                    Text("How are you feeling today?")
                        .font(.custom("Satoshi-Bold", size: 18))
                        .foregroundColor(AppTheme.Colors.textPrimary)

                    HStack(spacing: 12) {
                        MoodButton(emoji: "😊", label: "Strong", isSelected: selectedMood == "strong") {
                            selectedMood = "strong"
                        }
                        MoodButton(emoji: "😐", label: "Okay", isSelected: selectedMood == "okay") {
                            selectedMood = "okay"
                        }
                        MoodButton(emoji: "😰", label: "Struggling", isSelected: selectedMood == "struggling") {
                            selectedMood = "struggling"
                        }
                    }
                }
                .padding(.horizontal)

                // Challenge selection
                VStack(alignment: .leading, spacing: 12) {
                    Text("What's your biggest challenge today?")
                        .font(.custom("Satoshi-Bold", size: 18))
                        .foregroundColor(AppTheme.Colors.textPrimary)

                    VStack(spacing: 8) {
                        ChallengeButton(title: "Missing him", isSelected: selectedChallenge == "missing") {
                            selectedChallenge = "missing"
                        }
                        ChallengeButton(title: "Bored/lonely", isSelected: selectedChallenge == "bored") {
                            selectedChallenge = "bored"
                        }
                        ChallengeButton(title: "Seeing his posts", isSelected: selectedChallenge == "posts") {
                            selectedChallenge = "posts"
                        }
                        ChallengeButton(title: "Other", isSelected: selectedChallenge == "other") {
                            selectedChallenge = "other"
                        }
                    }
                }
                .padding(.horizontal)

                // Daily intention
                VStack(alignment: .leading, spacing: 12) {
                    Text("Your daily intention:")
                        .font(.custom("Satoshi-Bold", size: 18))
                        .foregroundColor(AppTheme.Colors.textPrimary)

                    Text("Today I choose freedom over a few minutes of false hope.")
                        .font(.custom("Satoshi-Medium", size: 16))
                        .foregroundColor(AppTheme.Colors.textSecondary)
                        .italic()
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(AppTheme.Colors.darkSurface)
                        .cornerRadius(12)
                }
                .padding(.horizontal)

                // Continue button
                Button(action: {
                    let generator = UIImpactFeedbackGenerator(style: .medium)
                    generator.impactOccurred()
                    onComplete()
                }) {
                    HStack(spacing: 8) {
                        Text("Continue to Meditation")
                            .font(.custom("Satoshi-Bold", size: 16))
                            .foregroundColor(.white)

                        Image(systemName: "arrow.right")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        selectedMood != nil && selectedChallenge != nil
                            ? Color.black
                            : Color.gray.opacity(0.5)
                    )
                    .cornerRadius(14)
                }
                .disabled(selectedMood == nil || selectedChallenge == nil)
                .padding(.horizontal)
                .padding(.bottom, 40)
            }
            .padding(.top)
        }
    }
}

// MARK: - Meditation Player View

struct MeditationPlayerView: View {
    let dayNumber: Int
    let title: String
    let onComplete: () -> Void

    @State private var isPlaying = false
    @State private var progress: Double = 0.0

    // TODO: Replace with actual audio player
    private let duration = 300.0 // 5 minutes in seconds

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            // Meditation icon
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.purple.opacity(0.3), Color.blue.opacity(0.2)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 120, height: 120)

                Image(systemName: "brain.head.profile")
                    .font(.system(size: 60))
                    .foregroundColor(.purple)
            }

            VStack(spacing: 8) {
                Text(title)
                    .font(.custom("Satoshi-Bold", size: 24))
                    .foregroundColor(AppTheme.Colors.textPrimary)
                    .multilineTextAlignment(.center)

                Text("5 minute guided meditation")
                    .font(.custom("Satoshi-Regular", size: 16))
                    .foregroundColor(AppTheme.Colors.textSecondary)
            }
            .padding(.horizontal)

            // Progress bar
            VStack(spacing: 8) {
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(height: 4)
                            .cornerRadius(2)

                        Rectangle()
                            .fill(Color.purple)
                            .frame(width: geometry.size.width * progress, height: 4)
                            .cornerRadius(2)
                    }
                }
                .frame(height: 4)

                HStack {
                    Text(formatTime(progress * duration))
                        .font(.custom("Satoshi-Regular", size: 12))
                        .foregroundColor(AppTheme.Colors.textSecondary)

                    Spacer()

                    Text(formatTime(duration))
                        .font(.custom("Satoshi-Regular", size: 12))
                        .foregroundColor(AppTheme.Colors.textSecondary)
                }
            }
            .padding(.horizontal, 40)

            // Play/Pause button
            Button(action: {
                isPlaying.toggle()
                if isPlaying {
                    startMeditation()
                }
            }) {
                ZStack {
                    Circle()
                        .fill(Color.purple)
                        .frame(width: 80, height: 80)

                    Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: 32))
                        .foregroundColor(.white)
                }
            }

            Spacer()

            // Skip button (for demo purposes)
            Button(action: {
                onComplete()
            }) {
                HStack(spacing: 6) {
                    Text("Skip for now")
                        .font(.custom("Satoshi-Medium", size: 14))
                        .foregroundColor(AppTheme.Colors.textSecondary)
                    Image(systemName: "chevron.right")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(AppTheme.Colors.textSecondary)
                }
            }
            .padding(.bottom, 40)
        }
    }

    private func startMeditation() {
        // TODO: Implement actual audio playback
        // For now, just simulate progress
        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { timer in
            if progress >= 1.0 {
                timer.invalidate()
                isPlaying = false
                onComplete()
            } else if isPlaying {
                progress += 0.1 / duration
            } else {
                timer.invalidate()
            }
        }
    }

    private func formatTime(_ seconds: Double) -> String {
        let minutes = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%d:%02d", minutes, secs)
    }
}

// MARK: - Micro Lesson View

struct MicroLessonView: View {
    let dayNumber: Int
    let title: String
    let onComplete: () -> Void

    // TODO: Fetch from Supabase based on dayNumber
    private var lessonContent: String {
        """
        Your brain will tell you:
        "Just one text won't hurt."

        This is a LIE. Here's why:

        1. There's no such thing as "just one"
           • 87% of setbacks start with "just one text"

        2. Your brain wants the dopamine hit
           • One text triggers the attachment cycle all over again

        3. It's never about closure
           • It's about chasing the feeling

        Today's Reality Check:
        How many times have you told yourself "just one text" and actually felt better?

        Exactly. Your brain is lying to you.
        """
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Icon
                ZStack {
                    Circle()
                        .fill(Color.red.opacity(0.2))
                        .frame(width: 60, height: 60)

                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 30))
                        .foregroundColor(.red)
                }
                .frame(maxWidth: .infinity)

                VStack(alignment: .leading, spacing: 8) {
                    Text(title)
                        .font(.custom("Satoshi-Bold", size: 28))
                        .foregroundColor(AppTheme.Colors.textPrimary)

                    Text("Day \(dayNumber) Lesson")
                        .font(.custom("Satoshi-Regular", size: 14))
                        .foregroundColor(AppTheme.Colors.textSecondary)
                }
                .padding(.horizontal)

                Text(lessonContent)
                    .font(.custom("Satoshi-Regular", size: 16))
                    .foregroundColor(AppTheme.Colors.textPrimary)
                    .lineSpacing(6)
                    .padding()
                    .background(AppTheme.Colors.darkSurface)
                    .cornerRadius(12)
                    .padding(.horizontal)

                // Action items
                VStack(alignment: .leading, spacing: 12) {
                    Text("Today's Tools:")
                        .font(.custom("Satoshi-Bold", size: 18))
                        .foregroundColor(AppTheme.Colors.textPrimary)

                    VStack(spacing: 8) {
                        ActionItem(text: "Text accountability partner")
                        ActionItem(text: "Play meditation again")
                        ActionItem(text: "Remember: You're \(dayNumber) days strong")
                    }
                }
                .padding(.horizontal)

                // Complete button
                Button(action: {
                    let generator = UIImpactFeedbackGenerator(style: .medium)
                    generator.impactOccurred()
                    onComplete()
                }) {
                    HStack(spacing: 8) {
                        Text("Mark Complete")
                            .font(.custom("Satoshi-Bold", size: 16))
                            .foregroundColor(.white)

                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 18))
                            .foregroundColor(.white)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        LinearGradient(
                            colors: [Color.green, Color.green.opacity(0.8)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(14)
                }
                .padding(.horizontal)
                .padding(.bottom, 40)
            }
            .padding(.top)
        }
    }
}

// MARK: - Supporting Components

struct MoodButton: View {
    let emoji: String
    let label: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Text(emoji)
                    .font(.system(size: 40))
                Text(label)
                    .font(.custom("Satoshi-Medium", size: 13))
                    .foregroundColor(isSelected ? .white : AppTheme.Colors.textPrimary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                isSelected
                    ? LinearGradient(
                        colors: [Color.purple, Color.purple.opacity(0.8)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    : LinearGradient(
                        colors: [AppTheme.Colors.darkSurface, AppTheme.Colors.darkSurface],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
            )
            .cornerRadius(16)
            .shadow(color: isSelected ? Color.purple.opacity(0.3) : Color.clear, radius: 8, x: 0, y: 4)
        }
        .animation(.spring(response: 0.3), value: isSelected)
    }
}

struct ChallengeButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Text(title)
                    .font(.custom("Satoshi-Medium", size: 15))
                    .foregroundColor(isSelected ? .white : AppTheme.Colors.textPrimary)
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.white)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(
                isSelected
                    ? LinearGradient(
                        colors: [Color.purple, Color.purple.opacity(0.8)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    : LinearGradient(
                        colors: [AppTheme.Colors.darkSurface, AppTheme.Colors.darkSurface],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
            )
            .cornerRadius(14)
            .shadow(color: isSelected ? Color.purple.opacity(0.2) : Color.clear, radius: 6, x: 0, y: 3)
        }
        .animation(.spring(response: 0.3), value: isSelected)
    }
}

struct ActionItem: View {
    let text: String

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(Color.purple.opacity(0.2))
                .frame(width: 32, height: 32)
                .overlay(
                    Image(systemName: "arrow.right")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(Color.purple)
                )

            Text(text)
                .font(.custom("Satoshi-Regular", size: 14))
                .foregroundColor(AppTheme.Colors.textPrimary)
            Spacer()
        }
        .padding()
        .background(AppTheme.Colors.darkSurface)
        .cornerRadius(12)
    }
}

// MARK: - Preview

struct DailyProgramView_Previews: PreviewProvider {
    static var previews: some View {
        DailyProgramView(dayNumber: 47)
    }
}
