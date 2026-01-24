//
//  Unit2Lessons.swift
//  Checkpoint
//
//  Unit 2: Managing Urges
//

import SwiftUI

struct Unit2Lessons {
    static let lessons: [LessonContent] = [
        // Lesson 7: Calming Techniques (Interactive - Box Breathing)
        LessonContent(
            slug: "calming_techniques",
            title: "Your First Line of Defense Against Urges",
            subtitle: "Use these when urges hit",
            icon: "wind",
            cards: [], // CalmingTechniquesView handles its own cards
            hasInteractiveFeature: true
        ),

        // Lesson 8: Finding Triggers
        LessonContent(
            slug: "finding_triggers",
            title: "Finding Your Triggers: The 24-Hour Audit",
            subtitle: "Identify and avoid what sets you off",
            icon: "scope",
            cards: [
                ModuleCard(
                    emoji: "⚠️",
                    title: "What Are Triggers?",
                    description: """
                    Triggers are situations, emotions, or environments that make you want to gamble. They activate the same neural pathways that gambling does, creating an automatic urge.

                    Your brain has been trained to associate certain cues with gambling. Seeing these cues fires up the dopamine system before you even make a conscious decision.
                    """
                ),
                ModuleCard(
                    emoji: "🎯",
                    title: "Common Triggers",
                    description: """
                    • Sports on TV
                    • Payday (having cash available)
                    • Boredom or loneliness
                    • Alcohol, drugs, or any substance use
                    • Seeing gambling ads
                    • Friends who gamble
                    • Financial stress or money problems
                    • Celebrating wins or coping with losses
                    """
                ),
                ModuleCard(
                    emoji: "🍺",
                    title: "Substances Lower Your Guard",
                    description: """
                    Alcohol and drugs are extremely dangerous triggers. They impair judgment and destroy impulse control.

                    When you're under the influence, your rational brain shuts down. The part that says "don't gamble" goes offline.

                    Many relapses happen while drinking or using. If you're serious about recovery, avoid substances.
                    """
                ),
                ModuleCard(
                    emoji: "⚡",
                    title: "Why Triggers Are Dangerous",
                    description: """
                    Triggers bypass your rational brain. You don't decide to gamble. Your brain reacts automatically.

                    Each time you're triggered and don't gamble, you weaken that connection. Each time you give in, you strengthen it.

                    Recovery is about breaking the trigger → urge → gamble cycle.
                    """
                ),
                ModuleCard(
                    emoji: "📝",
                    title: "Identify Your Triggers",
                    description: """
                    Get a piece of paper. Write down:

                    • Where do you want to gamble?
                    • When do you want to gamble?
                    • Who are you with when you want to gamble?
                    • What emotions make you want to gamble?

                    Awareness is the first step. You can't avoid what you don't acknowledge.
                    """
                ),
                ModuleCard(
                    emoji: "🛡️",
                    title: "Avoid These Triggers",
                    description: """
                    This is war. It's YOU vs this addiction.

                    Do whatever it takes:
                    • Unfollow sports accounts on social media
                    • Block gambling-related social media accounts
                    • Stop watching sports if you have to
                    • Abandon your favorite sports team if necessary
                    """
                ),
                ModuleCard(
                    emoji: "⚔️",
                    title: "Your Recovery Comes First",
                    description: """
                    • Distance yourself from friends who gamble
                    • Change your routine completely

                    If something triggers you, cut it out. No exceptions. Your recovery is worth more than any friendship, team, or habit.
                    """
                )
            ],
            hasInteractiveFeature: false
        ),

        // Lesson 9: 90-Second Rule
        LessonContent(
            slug: "90_second_rule",
            title: "The 90-Second Rule That Kills Urges",
            subtitle: "Science-backed urge surfing technique",
            icon: "timer",
            cards: [
                ModuleCard(
                    emoji: "⏱️",
                    title: "The 90-Second Emotional Reset",
                    description: """
                    When you feel anger, anxiety, or shame, stress hormones surge through your body.

                    Neuroscientist Dr. Jill Bolte Taylor discovered these chemicals flush out in 90 seconds if you don't retrigger them.
                    """
                ),
                ModuleCard(
                    emoji: "⚡",
                    title: "How to Use the 90-Second Rule",
                    description: """
                    When a strong emotion hits (anger, shame, anxiety), don't fight it. Just notice it.

                    Take a deep breath. Feel where the emotion lives in your body (chest, throat, stomach). Watch it without judgment for 90 seconds. The chemical surge will complete and the intensity drops. The emotion doesn't control you anymore.
                    """
                ),
                ModuleCard(
                    emoji: "🌊",
                    title: "Gambling Cravings Are a Little Different",
                    description: """
                    The 90-second rule works for emotions. Gambling cravings are similar, but a little different. They last longer.

                    Research shows gambling cravings last 20 minutes on average however they peak within a few minutes.
                    """
                ),
                ModuleCard(
                    emoji: "⛰️",
                    title: "Get Through the First Few Minutes",
                    description: """
                    Cravings peak fast, then fade. If you can get through the first few minutes, you can overcome the urge.

                    Your brain releases craving chemicals in waves. The wave WILL pass. You just need to ride it out.
                    """
                ),
                ModuleCard(
                    emoji: "🏄",
                    title: "Urge Surfing",
                    description: """
                    When a gambling urge hits:
                    1. Notice the sensation without fighting it
                    2. Watch it build like a wave (peaks in ~5 minutes)
                    3. Observe it crest
                    4. Watch it start to fall
                    5. Ride it out for 20 minutes

                    You're not "resisting." You're observing. The urge WILL fade.
                    """
                ),
                ModuleCard(
                    emoji: "🎯",
                    title: "The 3-Step Process",
                    description: """
                    Dr. Taylor's method for letting emotions pass:

                    1. Identify it: "This is anger" or "This is shame"
                    2. Label it: Say it out loud if you can
                    3. Observe it: Watch the feeling without trying to change it

                    Don't fight the emotion. Just watch it for 90 seconds.
                    """
                ),
                ModuleCard(
                    emoji: "💥",
                    title: "What Your Body Actually Feels",
                    description: """
                    Urges aren't just mental. Your body reacts physically:

                    Chest tightness. Stomach churning. Throat closing. Hands shaking. Heart racing.

                    Notice WHERE you feel the urge in your body. That physical sensation is the chemical flush. It peaks, then fades.
                    """
                ),
                ModuleCard(
                    emoji: "⏰",
                    title: "What to Do During Those 90 Seconds",
                    description: """
                    Breathe slowly. Count to 90 in your head. Name the feeling out loud: "This is anxiety."

                    Don't judge yourself. Don't fight it. Don't feed it by replaying what triggered it.

                    Just observe. The chemicals WILL flush out. You just have to wait.
                    """
                ),
                ModuleCard(
                    emoji: "🔁",
                    title: "Anything Beyond 90 Seconds Is a Choice",
                    description: """
                    This is the key insight from Dr. Taylor's research:

                    If you're still angry or anxious after 90 seconds, it's because you're re-triggering the chemical loop. You're replaying the situation. You're feeding the emotion. The initial surge is over. What remains is your choice to keep it going.
                    """
                ),
                ModuleCard(
                    emoji: "🧪",
                    title: "Research: Urge Surfing for Gambling",
                    description: """
                    Mindfulness-Based Relapse Prevention (MBRP) adapted for gambling was tested on treatment patients.

                    Results: Medium-to-large reductions in gambling urges, gambling behavior, and depression after using urge surfing and mindfulness techniques.

                    It works. The data proves it.
                    """
                ),
                ModuleCard(
                    emoji: "📚",
                    title: "Sources",
                    description: """
                    • Dr. Jill Bolte Taylor: "90-Second Rule for Emotional Regulation" (Neuroscientist, Harvard-trained)

                    • NIH/PMC: "The clinical significance of drug craving" (Cue-driven cravings last 5-30 minutes, peak within few minutes)
                    """
                ),
                ModuleCard(
                    emoji: "📖",
                    title: "Additional Sources",
                    description: """
                    • PMC: "Cognitive-behavioral treatment for gambling harm" (CBT 65% urge reduction in 12 weeks)

                    • Positive Psychology: "Urge Surfing" (Mindfulness-based technique)
                    """
                )
            ],
            hasInteractiveFeature: false
        ),

        // Lesson 10: Idle Mind
        LessonContent(
            slug: "idle_mind_devil_workshop",
            title: "Idle Mind = Devil's Workshop: Stay Busy",
            subtitle: "Why empty time kills recovery",
            icon: "clock.fill",
            cards: [
                ModuleCard(
                    emoji: "⚡",
                    title: "You Can't Quit Gambling and Replace It With Nothing",
                    description: """
                    This is the most important lesson in early recovery. If you quit gambling but don't fill that time with something else, you will relapse. Guaranteed.

                    Your brain craves stimulation. Empty time means your brain will fill it with old habits. Gambling was how you escaped boredom before.
                    """
                ),
                ModuleCard(
                    emoji: "🧠",
                    title: "Boredom Is Physical Pain to Your Brain",
                    description: """
                    Boredom is the number one relapse trigger in addiction studies. Brain scans show boredom activates the same regions as physical pain.

                    When you're understimulated, your brain becomes restless and irritable. It will create drama or chaos just to feel something.
                    """
                ),
                ModuleCard(
                    emoji: "🎯",
                    title: "Find a New Hobby, Get Obsessed",
                    description: """
                    You need to replace gambling with something that demands your attention. A new hobby, skill, project, or goal.

                    The goal is to stay so busy that you don't even remember to gamble. Make yourself so engaged with your new activity that gambling doesn't cross your mind.
                    """
                ),
                ModuleCard(
                    emoji: "📅",
                    title: "Schedule Everything in Early Recovery",
                    description: """
                    In the beginning, schedule every hour of your day. Build a morning routine that requires no decisions.

                    Keep three go-to activities ready for unexpected free time. Physical activity is especially helpful because it burns restless energy.
                    """
                ),
                ModuleCard(
                    emoji: "💪",
                    title: "Early Recovery Is Overscheduled on Purpose",
                    description: """
                    Accept that your life needs to be overscheduled right now. This isn't forever, but it's necessary in early recovery.

                    You need to be obsessively busy. Fill every gap. Leave no room for boredom to creep in and trigger an urge.
                    """
                ),
                ModuleCard(
                    emoji: "📚",
                    title: "Sources",
                    description: """
                    • Immunize Nevada: "Cognitive and Behavioral Aspects of Gambling Addiction" (Boredom as primary trigger)

                    • PMC: "Circadian rhythms and addiction: Mechanistic insights" (Understimulation and relapse risk)
                    """
                )
            ],
            hasInteractiveFeature: false
        ),

        // Lesson 11: 2AM Danger Zone
        LessonContent(
            slug: "danger_relapse_time",
            title: "The 2AM Danger Zone: Late-Night Relapse Prevention",
            subtitle: "Most relapses happen at night",
            icon: "moon.stars.fill",
            cards: [
                ModuleCard(
                    emoji: "🌙",
                    title: "Your Urges Get Strongest at Night",
                    description: """
                    You've probably noticed that your gambling urges get strongest at night. This is not a bug. It's a feature of addiction.

                    Everyone's asleep, so you're alone with your thoughts. There's nothing to do and no distractions. Your phone is right there with betting apps just 3 taps away.
                    """
                ),
                ModuleCard(
                    emoji: "⚠️",
                    title: "The Goal: Avoid Being Awake at Night",
                    description: """
                    To combat this, the goal is really simple: avoid being awake late at night to the best of your ability. That's when your willpower is depleted the most.

                    Research shows that 2AM to 4AM is the peak relapse window. Sleep deprivation wrecks your impulse control. Your partner and friends are asleep, so there's no accountability.
                    """
                ),
                ModuleCard(
                    emoji: "🚨",
                    title: "If You're Awake: Use These Protocols",
                    description: """
                    If you do find yourself awake at night, this is when your willpower is at its lowest. You need to take immediate action because you're fighting with depleted resources.

                    Put your phone in another room immediately. Turn on all the lights to mimic daytime. Splash cold water on your face or take a cold shower to reset your nervous system.
                    """
                ),
                ModuleCard(
                    emoji: "📞",
                    title: "Emergency Actions When Willpower Is Gone",
                    description: """
                    Do physical activity like push-ups, a walk, or jumping jacks to burn off the anxious energy. If the urge is still strong, call the 24/7 helpline at 1-800-522-4700.

                    Do NOT scroll social media, watch sports, or check odds. These activities will trigger you further when your defenses are already down.
                    """
                ),
                ModuleCard(
                    emoji: "🌅",
                    title: "Wake Up Earlier If You Have To",
                    description: """
                    What does avoiding nights mean? Go to bed earlier and wake up earlier. If you have to wake up at 5AM every day to avoid staying up late, do it.

                    Shift your schedule earlier. Put your phone in a different room at 10PM. Late nights are a luxury you cannot afford right now.
                    """
                ),
                ModuleCard(
                    emoji: "📚",
                    title: "Sources",
                    description: """
                    • PMC: "Circadian rhythms and addiction: Mechanistic insights" (Evening chronotype increases addiction risk)

                    • PMC: "Circadian Rhythms, Sleep, and Substance Abuse" (Disrupted rhythms contribute to relapse)
                    """
                )
            ],
            hasInteractiveFeature: false
        ),

        // Lesson 12: Replace the Rush
        LessonContent(
            slug: "healthy_dopamine_source",
            title: "Replace the Rush: Healthy Dopamine Sources",
            subtitle: "Activities that retrain your brain",
            icon: "bolt.fill",
            cards: [
                ModuleCard(
                    emoji: "🧠",
                    title: "Why You Crave Gambling",
                    description: """
                    Gambling gives you a dopamine spike. Your brain craves that rush and it won't just turn off because you decided to quit.

                    You can't stop gambling without replacing it with something else. You need other activities that provide dopamine in healthy ways.
                    """
                ),
                ModuleCard(
                    emoji: "⚡",
                    title: "Fill Your Time or Gambling Will",
                    description: """
                    You need to be busy and always engaged with something. You can't sit alone and replace your urge to gamble with nothing.

                    When you're sitting around with an urge and nothing to do, you're going to lose 10 out of 10 times. Fill your time or gambling will fill it for you.
                    """
                ),
                ModuleCard(
                    emoji: "🏃",
                    title: "High-Intensity Activities",
                    description: """
                    Sprint intervals, boxing, heavy lifting, running, or intense cardio. These get your heart racing and create the adrenaline rush closest to gambling's high.

                    High-intensity exercise floods your brain with endorphins and dopamine. It's the most effective replacement for the gambling rush.
                    """
                ),
                ModuleCard(
                    emoji: "🚶",
                    title: "Medium-Intensity Activities",
                    description: """
                    Going for walks, hiking, biking, swimming, or playing sports. These keep you moving and engaged without being overwhelming.

                    Medium intensity is perfect for when you need to burn restless energy but don't want to exhaust yourself. It clears your head and gives steady dopamine.
                    """
                ),
                ModuleCard(
                    emoji: "🍳",
                    title: "Low-Intensity Activities",
                    description: """
                    Cooking, reading, learning an instrument, building something with your hands, gardening, or working on a creative project.

                    Low intensity activities give you progression-based dopamine. You see yourself improving over time, which keeps your brain engaged and satisfied.
                    """
                ),
                ModuleCard(
                    emoji: "💼",
                    title: "Channel Your Energy Into Building",
                    description: """
                    Start a side hustle, flip items for profit, learn a new skill, or work on a passion project. Make money instead of losing it.

                    The risk-taking energy you had for gambling can be channeled into building something real. This gives you control and real rewards, not false hope.
                    """
                ),
                ModuleCard(
                    emoji: "✅",
                    title: "Pick ONE and Commit",
                    description: """
                    Don't try all of them at once. Pick one activity and commit to it for the next seven days.

                    When you feel the urge to gamble, do this activity instead. Make it your default response to cravings.
                    """
                )
            ],
            hasInteractiveFeature: false
        ),

        // Lesson 13: Relapse Warning Signs
        LessonContent(
            slug: "relapse_warning_signs",
            title: "Recognizing Relapse Warning Signs",
            subtitle: "Catch the slide before it becomes a fall",
            icon: "exclamationmark.triangle.fill",
            cards: [
                ModuleCard(
                    emoji: "⚠️",
                    title: "Why This Matters Now",
                    description: """
                    You're past the acute withdrawal phase. The worst cravings have faded. This is exactly when complacency sets in.

                    Relapse doesn't start when you place the bet. It starts weeks earlier with small warning signs you ignore. If you can catch these early, you can stop a relapse before it happens.
                    """
                ),
                ModuleCard(
                    emoji: "😔",
                    title: "Emotional Warning Signs",
                    description: """
                    You start bottling up emotions instead of processing them. You're isolating more, pulling away from support networks and people who care about you.

                    Mood swings increase. Irritability and anxiety spike. You're neglecting self-care like sleep, exercise, and healthy eating. These emotional changes happen first, before you even think about gambling again.
                    """
                ),
                ModuleCard(
                    emoji: "🧠",
                    title: "Mental Warning Signs",
                    description: """
                    You start romanticizing past wins and forgetting the losses. Thoughts like "just once won't hurt" or "I can control it now" creep in.

                    You justify gambling as a "manageable activity" or tell yourself you're different now. You start planning how you could gamble without getting caught. This is mental relapse, and it's the stage right before you actually do it.
                    """
                ),
                ModuleCard(
                    emoji: "🚩",
                    title: "Behavioral Warning Signs",
                    description: """
                    You stop doing recovery work. You skip lessons, avoid accountability, or stop showing up to therapy or support meetings.

                    You start testing limits by saying things like "I'll just watch the game" or "I'll only check the odds." You become secretive about your activities and hide what you're doing from loved ones.
                    """
                ),
                ModuleCard(
                    emoji: "🛡️",
                    title: "What to Do When You Notice These",
                    description: """
                    If you catch even one of these warning signs, act immediately. Call your sponsor, therapist, or a trusted friend before the urge gets stronger.

                    Get brutally honest with someone about what you're feeling. Don't wait until you're already in crisis mode. The earlier you intervene, the easier it is to stop the slide.
                    """
                ),
                ModuleCard(
                    emoji: "⛔",
                    title: "The Trap of Overconfidence",
                    description: """
                    Thinking you're "cured" or that you can handle "just one bet" is one of the biggest relapse warning signs. You're not fixed. You're in recovery.

                    Recovery is a daily practice, not a destination. The moment you think you've mastered it is the moment you're most vulnerable. Stay humble and stay vigilant.
                    """
                ),
                ModuleCard(
                    emoji: "💪",
                    title: "Relapse Is Not Failure",
                    description: """
                    If you do slip or relapse, it doesn't mean you failed. It means you need a different approach or more support.

                    Get back on track immediately. Don't let one slip turn into a full spiral. The only true failure is giving up completely.
                    """
                ),
                ModuleCard(
                    emoji: "📚",
                    title: "Sources",
                    description: """
                    • Right Choice Recovery NJ: "Gambling Addiction Relapse Prevention Strategies"

                    • Georgia Addiction Treatment Center: "Substance Use and Gambling Relapse: What to Watch For" (2025)

                    • Florida Council on Compulsive Gambling: "To Beat Relapse in Problem Gambling Recovery, Know Your Warning Signs"
                    """
                )
            ],
            hasInteractiveFeature: false
        )
    ]
}
