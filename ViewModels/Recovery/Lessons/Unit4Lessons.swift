//
//  Unit4Lessons.swift
//  Checkpoint
//
//  Unit 4: Becoming Who You Want to Be
//

import SwiftUI

struct Unit4Lessons {
    static let lessons: [LessonContent] = [
        // Lesson 21: Language & Identity
        LessonContent(
            slug: "identity_I_cant_I_Dont",
            title: "From 'I Can't Gamble' to 'I Don't Gamble'",
            subtitle: "Language that shapes identity",
            icon: "quote.bubble.fill",
            cards: [
                ModuleCard(
                    emoji: "🧠",
                    title: "Your Internal Dialogue Shapes Your Reality",
                    description: """
                    The way you talk to yourself matters more than you think. Your internal dialogue creates the framework for how you see yourself.

                    When you say "I can't gamble," you're framing recovery as deprivation. When you say "I don't gamble," you're stating who you are. This subtle shift changes everything.
                    """
                ),
                ModuleCard(
                    emoji: "💬",
                    title: "Why Language Matters",
                    description: """
                    "I can't gamble" suggests external restriction, like you're being forced to abstain. It's diet mentality. You're constantly resisting something you want but can't have.

                    "I don't gamble" is internal identity. It's who you are, not what you're restricted from. Your brain hears the difference and responds accordingly.
                    """
                ),
                ModuleCard(
                    emoji: "🔄",
                    title: "External vs Internal Motivation",
                    description: """
                    External motivation is fear-based. "I'll get in trouble if I gamble" or "I'll lose everything if I relapse." This works temporarily but fades when the fear decreases.

                    Internal motivation is identity-based. "I'm someone who doesn't gamble" comes from within. External motivation fades over time. Identity persists.
                    """
                ),
                ModuleCard(
                    emoji: "⚖️",
                    title: "Deprivation vs Choice",
                    description: """
                    Framing recovery as deprivation makes gambling feel like something you're missing out on. Your brain naturally resists restrictions and wants what it can't have.

                    Framing recovery as choice makes gambling feel like something you're actively rejecting because it doesn't serve you. This is the difference between willpower and identity.
                    """
                ),
                ModuleCard(
                    emoji: "🎯",
                    title: "Practice the Language Shift",
                    description: """
                    Old: "I'm trying not to gamble."
                    New: "I don't gamble."

                    Old: "I can't bet on sports."
                    New: "I don't bet on sports."

                    Old: "I'm in recovery."
                    New: "I'm building a new life."

                    Say these out loud. Your brain believes what you tell it.
                    """
                ),
                ModuleCard(
                    emoji: "💪",
                    title: "You're Not Resisting, You're Being Yourself",
                    description: """
                    When you shift your language from "can't" to "don't," recovery stops feeling like a constant battle. You're not white-knuckling through urges. You're not resisting gambling every day.

                    You're simply being yourself. A person who doesn't gamble. This is who you are now. Own it.
                    """
                )
            ],
            hasInteractiveFeature: false
        ),

        // Lesson 22: Forgiving Yourself
        LessonContent(
            slug: "forgive_yourself",
            title: "Forgiving Yourself: Letting Go of Shame",
            subtitle: "You can't heal while carrying the weight",
            icon: "heart.fill",
            cards: [
                ModuleCard(
                    emoji: "⚖️",
                    title: "The Weight You're Carrying",
                    description: """
                    The money you lost. The lies you told. The trust you broke. The time you wasted.

                    You've been carrying this weight every single day. It's exhausting.

                    Shame tells you: "You're a bad person." That's the lie keeping you stuck.
                    """
                ),
                ModuleCard(
                    emoji: "🔗",
                    title: "Why Shame Keeps You Stuck",
                    description: """
                    Shame says: "I AM bad" (identity).
                    Guilt says: "I DID something bad" (behavior).

                    Shame is paralyzing. It makes you feel unworthy of recovery.

                    Research shows shame INCREASES relapse risk. Self-hatred doesn't motivate change. It sabotages it.
                    """
                ),
                ModuleCard(
                    emoji: "💔",
                    title: "Self-Forgiveness vs Self-Hatred",
                    description: """
                    Self-hatred: "I'm worthless, I deserve to suffer."

                    Self-forgiveness: "I made terrible choices. I hurt people. I can't undo it. But I can do better from here."

                    Forgiveness isn't excusing what you did. It's choosing not to punish yourself forever.
                    """
                ),
                ModuleCard(
                    emoji: "🕊️",
                    title: "How to Actually Forgive Yourself",
                    description: """
                    Acknowledge the damage without drowning in it.

                    Make amends where possible (financial repayment, honest conversations).

                    Accept that some things can't be fixed, only learned from. Your past actions don't define your future worth.
                    """
                ),
                ModuleCard(
                    emoji: "🌱",
                    title: "Moving Forward Without Forgetting",
                    description: """
                    You don't erase the past. You learn from it.

                    The shame you feel? That means you have a conscience. Use it as fuel, not an anchor.

                    Every day in recovery is proof you're not the person you were. Forgiveness is earned through action, not words. Show yourself through consistency.
                    """
                )
            ],
            hasInteractiveFeature: false
        ),

        // Lesson 23: Setting Goals
        LessonContent(
            slug: "goals_beyond_gambling",
            title: "Setting Goals Beyond 'Not Gambling'",
            subtitle: "Recovery can't be your only identity",
            icon: "target",
            cards: [
                ModuleCard(
                    emoji: "🎯",
                    title: "Why Not Gambling Isn't Enough",
                    description: """
                    You can't build a meaningful life around what you don't do. "I don't gamble" is necessary but not sufficient for a fulfilling future.

                    You need something you're moving toward, not just running from. Goals give you direction and purpose beyond avoiding relapse. They give you a reason to stay sober that's bigger than fear.
                    """
                ),
                ModuleCard(
                    emoji: "🏗️",
                    title: "Building on Your Foundation",
                    description: """
                    Recovery is the foundation. Now what are you building on it?
                    """
                ),
                ModuleCard(
                    emoji: "🎯",
                    title: "What Are You Building Toward?",
                    description: """
                    Most people in early recovery only focus on what they're avoiding. "Don't gamble, don't relapse, don't mess up." That's purely defensive.

                    You need offensive goals too. What are you building? What career do you want? What relationships do you want to repair? What skills do you want to master? What impact do you want to have?

                    Write down three specific things you're building toward. Not avoiding, building.
                    """
                ),
                ModuleCard(
                    emoji: "📅",
                    title: "The 3-Tier Goal Framework",
                    description: """
                    Set a 90-day goal that's achievable and concrete, like paying off $5,000 in debt, running a 5K, or learning a new skill.

                    Set a 1-year goal with bigger vision, like becoming debt-free, getting a new job, or rebuilding a damaged relationship.

                    Set a 5-year vision for who you want to be and what life you're building. Write all three down and make them specific.
                    """
                ),
                ModuleCard(
                    emoji: "📈",
                    title: "Track More Than Just Sobriety",
                    description: """
                    Days without gambling is your foundation metric. But you need to track other dimensions too.

                    Money saved shows financial recovery. Relationships improved shows trust being rebuilt. Skills learned shows personal growth. Health markers like sleep quality, exercise frequency, and nutrition show physical recovery.

                    Track multiple dimensions of your life. You're building something bigger than just "not gambling."
                    """
                )
            ],
            hasInteractiveFeature: false
        ),

        // Lesson 24: Identity Reconstruction
        LessonContent(
            slug: "new_identity",
            title: "Who You're Becoming: Identity Reconstruction",
            subtitle: "Building yourself from scratch",
            icon: "person.fill.badge.plus",
            cards: [
                ModuleCard(
                    emoji: "🪪",
                    title: "Why Identity Matters in Recovery",
                    description: """
                    Your identity is how you see yourself at your core. It's the answer to "Who am I?" and it drives every decision you make.

                    When your identity is "I'm a gambler," recovery feels like constant resistance. When your identity shifts to something new, recovery becomes natural. You're not fighting urges. You're being yourself.

                    Identity is more powerful than willpower. Willpower runs out. Identity persists.
                    """
                ),
                ModuleCard(
                    emoji: "🎭",
                    title: "Old Identity vs New Identity",
                    description: """
                    Old: "I'm a gambler trying to quit."

                    New: "I'm a [new defining traits] who used to gamble."

                    Gambling was what you DID, not who you ARE.

                    Fill in the blank: runner, dad, builder, creator, friend.
                    """
                ),
                ModuleCard(
                    emoji: "⛏️",
                    title: "You're Not Starting from Zero",
                    description: """
                    Recovery isn't about building a completely new person. It's about excavating who you were before gambling buried you.

                    Parts of you got lost along the way. Your personality, your interests, your values. They're still there, just covered up. Now you dig them back up.
                    """
                ),
                ModuleCard(
                    emoji: "🔍",
                    title: "Rediscovering Buried Interests",
                    description: """
                    What did you love before gambling took over? Think back to before the addiction consumed your time and energy.

                    Hobbies you abandoned like music, sports, reading, or building things with your hands. Skills you always wanted to learn like a language, an instrument, or a trade. These interests didn't disappear. You just stopped feeding them. It's time to bring them back to life.
                    """
                ),
                ModuleCard(
                    emoji: "⚖️",
                    title: "Building Identity Around Values",
                    description: """
                    What matters to you? (Family, health, freedom, contribution, growth?)

                    Your identity should reflect your values, not your vices.

                    "I'm someone who values [X]" is more powerful than "I don't do [Y]."

                    Recovery gives you the space to become who you actually want to be.
                    """
                )
            ],
            hasInteractiveFeature: false
        ),

        // Lesson 25: Finding Purpose
        LessonContent(
            slug: "finding_purpose",
            title: "Finding Purpose: Building a Life Worth Living",
            subtitle: "What makes life meaningful",
            icon: "lightbulb.fill",
            cards: [
                ModuleCard(
                    emoji: "🎯",
                    title: "Recovery Can't Be Your Only Identity",
                    description: """
                    You can't build a meaningful life around what you don't do. "I don't gamble" is necessary but not sufficient for a fulfilling life.

                    You need something you're moving toward, not just running from. Purpose gives you a reason to stay in recovery beyond fear of relapse.
                    """
                ),
                ModuleCard(
                    emoji: "🌱",
                    title: "The Four Pillars of Meaning",
                    description: """
                    Research shows meaningful lives are built on four foundations.

                    Contribution is what you give to others. Mastery is what you're getting better at. Connection is who you love and who loves you. Autonomy is the choices you control.

                    These four pillars create a life worth living.
                    """
                ),
                ModuleCard(
                    emoji: "💔",
                    title: "How Gambling Destroyed Contribution and Mastery",
                    description: """
                    Contribution: Gambling made you take from others, not give. You lied, borrowed, and broke trust. Instead of adding value to people's lives, you became a burden.

                    Mastery: You got worse at everything that mattered. Work performance declined, relationships deteriorated, and your health suffered. You weren't growing. You were regressing.
                    """
                ),
                ModuleCard(
                    emoji: "🏚️",
                    title: "How Gambling Destroyed Connection and Autonomy",
                    description: """
                    Connection: Gambling isolated you from everyone who loved you. The relationships that mattered most slowly died.

                    Autonomy: Gambling controlled every decision you made. Your schedule revolved around it. Your finances revolved around it. You had no real freedom or control over your own life.
                    """
                ),
                ModuleCard(
                    emoji: "🔨",
                    title: "Now You Rebuild All Four",
                    description: """
                    Start small. You don't rebuild meaning overnight.

                    Pick one pillar to focus on first. Contribute by helping someone. Master a skill by practicing daily. Connect by being honest with one person. Own a choice by following through on one commitment.

                    Build all four over time. That's how you create a life worth protecting.
                    """
                ),
                ModuleCard(
                    emoji: "❓",
                    title: "Your Why for Living",
                    description: """
                    Why do you get up in the morning beyond not gambling? Who depends on you? What would you regret never doing? What impact do you want to make?

                    Your why has to be bigger than avoiding something. It has to be building toward something. Answer these questions honestly. Write them down. This is your north star.
                    """
                ),
                ModuleCard(
                    emoji: "🏛️",
                    title: "Legacy Thinking",
                    description: """
                    What do you want to be remembered for? In 10 years, what will you be proud of? When you're 80, what stories do you want to tell?

                    Legacy isn't about wealth or fame. It's about the impact you have on the people around you. You get to choose what you build from here.
                    """
                )
            ],
            hasInteractiveFeature: false
        ),

        // Lesson 26: Giving Back
        LessonContent(
            slug: "helping_others",
            title: "How Helping Others Strengthens Recovery",
            subtitle: "You can't keep it without giving it away",
            icon: "heart.fill",
            cards: [
                ModuleCard(
                    emoji: "🔄",
                    title: "Why Giving Back Strengthens Your Recovery",
                    description: """
                    Research by Dr. Maria Pagano at Case Western University shows that helping others can increase your chances of staying sober by up to 50 percent.

                    When you mentor someone new to recovery, you reinforce your own commitment. Teaching what you've learned solidifies those neural pathways and creates purpose beyond yourself.
                    """
                ),
                ModuleCard(
                    emoji: "🧠",
                    title: "The Helper's High",
                    description: """
                    Research shows that helping others triggers the release of oxytocin in your brain, which then boosts serotonin and dopamine. This natural mood boost is called the helper's high.

                    When you support someone else in recovery, you get a genuine sense of satisfaction that replaces the artificial high from gambling.
                    """
                ),
                ModuleCard(
                    emoji: "🤝",
                    title: "How to Give Back in Recovery",
                    description: """
                    Answer questions in recovery forums or support groups. Share your story honestly, not performatively. Be an accountability partner for someone on Day 1 who's struggling.

                    Volunteer with gambling addiction organizations. Donate to recovery programs. Simply listen when someone needs to talk. Every act of service reinforces your own sobriety.
                    """
                ),
                ModuleCard(
                    emoji: "💡",
                    title: "You Remind Yourself Why You Quit",
                    description: """
                    When someone thanks you for helping them stay sober, you remember why you quit gambling in the first place.

                    Seeing someone else struggle with urges reminds you how far you've come. Watching someone succeed because of your support proves that recovery is possible. Service keeps your "why" fresh and relevant.
                    """
                ),
                ModuleCard(
                    emoji: "✨",
                    title: "Turning Pain Into Purpose",
                    description: """
                    Your suffering wasn't meaningless if it helps someone else avoid the same mistakes. Everything you learned the hard way becomes wisdom for others.

                    The worst parts of your story might save someone's life. The shame you carried can become strength for someone else. You can't keep recovery without giving it away.
                    """
                ),
                ModuleCard(
                    emoji: "📚",
                    title: "Sources",
                    description: """
                    • Greater Good Science Center (UC Berkeley): "Can Helping Others Keep You Sober?" (Dr. Maria Pagano research shows helping others increases sobriety rates by up to 50%)

                    • PMC: "Helping Others and Long-term Sobriety" (Helping other addicts rated as contributing most to staying sober)
                    """
                ),
                ModuleCard(
                    emoji: "📖",
                    title: "Additional Sources",
                    description: """
                    • PMC: "Prosocial behavior, psychological well-being, positive and negative affect" (Positive correlation between prosocial behavior and well-being)
                    """
                )
            ],
            hasInteractiveFeature: false
        )
    ]
}
