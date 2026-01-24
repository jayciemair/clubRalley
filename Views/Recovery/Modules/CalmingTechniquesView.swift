//
//  CalmingTechniquesView.swift
//  Checkpoint
//
//  Practice Calming Techniques - Prepare when urges hit
//

import SwiftUI

struct CalmingTechniquesView: View {
    let lessonIndex: Int
    let onComplete: () -> Void
    @State private var showBoxBreathingPractice = false

    var body: some View {
        CardNavigationModule(
            moduleTitle: "Your First Line of Defense Against Urges",
            moduleSubtitle: "Use these when urges hit",
            cards: [
                ModuleCard(
                    emoji: "👋",
                    title: "Welcome to Your Recovery",
                    description: """
                    This is the start of your recovery journey.

                    You'll unlock new recovery lessons as you progress. You'll learn how to combat urges, understand your addiction, and rebuild your life.

                    This program is built on neuroscience, psychology, and real recovery stories. You're in the right place.
                    """
                ),
                ModuleCard(
                    emoji: "⚡",
                    title: "Right Now: Your Urges Are Strongest",
                    description: """
                    Early recovery is the hardest. Your brain is screaming for dopamine.

                    You need quick tools to stop urges in their tracks.

                    We have proven methods: Box Breathing, grounding techniques, and physical resets. Use these when the craving hits.
                    """
                ),
                ModuleCard(
                    emoji: "🫁",
                    title: "Box Breathing (4-4-4-4)",
                    description: """
                    1. Breathe in for 4 seconds
                    2. Hold for 4 seconds
                    3. Breathe out for 4 seconds
                    4. Hold for 4 seconds

                    Repeat 4 times. Slows your heart rate, calms anxiety.
                    """,
                    practiceAction: {
                        showBoxBreathingPractice = true
                    }
                ),
                ModuleCard(
                    emoji: "👁️",
                    title: "5-4-3-2-1 Grounding",
                    description: """
                    Name out loud:
                    • 5 things you can see
                    • 4 things you can touch
                    • 3 things you can hear
                    • 2 things you can smell
                    • 1 thing you can taste

                    Pulls you out of your head and into the present.
                    """
                ),
                ModuleCard(
                    emoji: "💧",
                    title: "Cold Water Reset",
                    description: """
                    Splash cold water on your face or dunk your face in a sink of cold water for 30 seconds.

                    Activates the dive reflex, immediately slowing your heart rate. Used by Navy SEALs.
                    """
                ),
                ModuleCard(
                    emoji: "📞",
                    title: "Call Someone",
                    description: """
                    Call a loved one, friend, family member, co-worker, colleague, anyone.

                    Say: "I'm having an urge. I'm not going to gamble, but I need to talk to someone for 5 minutes."

                    Urges peak in 20 minutes. You just need to get past the peak.
                    """
                ),
                ModuleCard(
                    emoji: "🏃",
                    title: "Move Your Body Immediately",
                    description: """
                    Drop and do 20 pushups. Sprint around your block. Do jumping jacks until you're out of breath.

                    Physical exertion releases endorphins and forces your brain to focus on something other than the urge.

                    You can't obsess about him while your body is screaming for oxygen.
                    """
                ),
                ModuleCard(
                    emoji: "🎯",
                    title: "These Sound Simple. They Work.",
                    description: """
                    You might be thinking "Cold water? Breathing? That's it?"

                    Yes. These aren't complicated because they don't need to be.

                    These tactics interrupt the dopamine loop your brain is running. Thousands have used them to stay clean.
                    """
                ),
                ModuleCard(
                    emoji: "💪",
                    title: "You Can Do This",
                    description: """
                    Urges are inevitable. They will come, especially in early recovery.

                    You have to be strong and fight them using these techniques.

                    Continue to the next lesson for more tools, more knowledge, more support.
                    """
                )
            ],
            lessonIndex: lessonIndex,
            onComplete: onComplete
        )
        .fullScreenCover(isPresented: $showBoxBreathingPractice) {
            BoxBreathingPracticeView()
        }
    }
}

#Preview {
    NavigationView {
        CalmingTechniquesView(lessonIndex: 6, onComplete: {})
    }
}
