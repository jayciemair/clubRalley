//
//  Unit1Lessons.swift
//  Checkpoint
//
//  Unit 1: Understanding Your Addiction
//

import SwiftUI

struct Unit1Lessons {
    static let lessons: [LessonContent] = [
        // Lesson 1: Understanding Dopamine
        LessonContent(
            slug: "understanding_dopamine",
            title: "Why Your Brain is Hijacked (And It's Not Your Fault)",
            subtitle: "The science behind your addiction",
            icon: "brain.head.profile",
            cards: [
                ModuleCard(
                    emoji: "🧠",
                    title: "What is Dopamine?",
                    description: """
                    Dopamine is your brain's reward chemical. It's designed to keep you alive.

                    When you do something good for survival (eat food, have sex, accomplish a goal), your brain releases dopamine. This makes you feel good and want to do it again.

                    Dopamine isn't the problem. It's a survival mechanism. But gambling hijacks it.
                    """
                ),
                ModuleCard(
                    emoji: "🎰",
                    title: "How Gambling Hijacks Your Brain",
                    description: """
                    Here's the trick: uncertainty maximizes dopamine release.

                    Research shows 50% probability of winning creates MORE dopamine than guaranteed wins. Your brain lights up most when you don't know what's going to happen.
                    """
                ),
                ModuleCard(
                    emoji: "🎲",
                    title: "Why Uncertainty Is Addictive",
                    description: """
                    Slots, sports betting, card games. The "not knowing" is what hooks you.

                    Your brain releases MORE dopamine during uncertainty than guaranteed rewards.

                    That's why you can't stop after a win or loss. Uncertainty pulls you back in...
                    """
                ),
                ModuleCard(
                    emoji: "📉",
                    title: "Why Losses Feel Like Wins",
                    description: """
                    This is the cruelest part:

                    Studies found that pathological gamblers release MORE dopamine from losses than healthy people do. Your brain treats a loss like it's close to a win.

                    That's why you chase losses. Your brain is literally telling you that losing feels good. It's not weakness. It's neurobiology.
                    """
                ),
                ModuleCard(
                    emoji: "🎯",
                    title: "The Near-Miss Trick",
                    description: """
                    Cherry, cherry, lemon. You didn't win, but your brain says you almost did.

                    Research shows near-misses activate the SAME reward circuits as actual wins in problem gamblers. Your brain treats a loss like it's close enough to count.

                    That's why slot machines are designed to give you near-misses constantly. They make you feel like you're "getting close," so you keep playing.

                    Non-gamblers' brains correctly recognize near-misses as losses. But if you're addicted, your brain sees them as wins.
                    """
                ),
                ModuleCard(
                    emoji: "💪",
                    title: "Why Willpower Fails",
                    description: """
                    You're not fighting a habit. You're fighting brain chemistry.

                    Chronic gambling makes your dopamine system less sensitive (tolerance). You need bigger bets, more risk, more action to feel the same high.
                    """
                ),
                ModuleCard(
                    emoji: "🛠️",
                    title: "What Works When Willpower Doesn't",
                    description: """
                    Willpower alone can't beat brain chemistry. You need:
                    • Barriers (blocking, self-exclusion)
                    • Replacement activities (new dopamine sources)
                    • Support (people who understand)
                    • Time (to rewire your brain)
                    """
                ),
                ModuleCard(
                    emoji: "✨",
                    title: "The Good News",
                    description: """
                    Your brain can rewire itself. It's called neuroplasticity.

                    Every day you don't gamble, your dopamine system resets a little bit. The cravings get weaker. The urges get shorter. The triggers lose their power.

                    Recovery isn't about fighting your brain. It's about giving your brain time to heal.
                    """
                ),
                ModuleCard(
                    emoji: "🔬",
                    title: "Science Confirms Recovery Works",
                    description: """
                    In 2013, the American Psychiatric Association reclassified gambling as an addiction (not an impulse control disorder) because neuroscience proved it's neurologically identical to drug addiction.

                    That means recovery works the same way. And recovery is possible.
                    """
                ),
                ModuleCard(
                    emoji: "📚",
                    title: "Sources",
                    description: """
                    • National Institutes of Health (PMC): "Pathological Choice: The Neuroscience of Gambling and Gambling Addiction"

                    • National Institutes of Health (PMC): "What motivates gambling behavior? Insight into dopamine's role"

                    • National Institutes of Health (PMC): "Neurobehavioral Evidence for the 'Near-Miss' Effect in Pathological Gamblers"
                    """
                ),
                ModuleCard(
                    emoji: "📚",
                    title: "Sources (Continued)",
                    description: """
                    • Journal of Gambling Studies (2024): "The Role of Social Support and Belonging in Predicting Recovery from Problem Gambling"

                    • University of Cambridge: "Near misses are like winning to problem gamblers"

                    • Scientific American: "How the Brain Gets Addicted to Gambling"

                    • Nature Scientific Reports: "A potential link between gambling addiction severity and central dopamine levels"
                    """
                )
            ],
            hasInteractiveFeature: false
        ),

        // Lesson 2: Why You Chase Losses
        LessonContent(
            slug: "why_you_chase_losses",
            title: "Why You Always Chase Losses (And How to Stop)",
            subtitle: "The psychology of loss aversion",
            icon: "arrow.down.circle.fill",
            cards: [
                ModuleCard(
                    emoji: "🧠",
                    title: "Loss Aversion: Your Brain's Fatal Flaw",
                    description: """
                    Humans feel losses 2x more intensely than equivalent gains.

                    Losing $100 hurts more than winning $100 feels good.

                    Your brain will do ANYTHING to "undo" a loss. This is evolutionary (losing food = death in the wild), but gambling exploits it.
                    """
                ),
                ModuleCard(
                    emoji: "💸",
                    title: "The Sunk Cost Fallacy",
                    description: """
                    "I've already lost $500, I need to win it back."

                    Your brain treats past losses as "investment." Rational brain says: past money is gone, stop now.

                    Emotional brain says: must justify the loss by winning.
                    """
                ),
                ModuleCard(
                    emoji: "❌",
                    title: "Why the Fallacy Fails",
                    description: """
                    The fallacy: throwing more money at a loss never makes it better.

                    The odds don't change because you already lost. The casino doesn't owe you a win.

                    Every new bet is a fresh loss with the same terrible odds.
                    """
                ),
                ModuleCard(
                    emoji: "🎲",
                    title: "The Gambler's Fallacy",
                    description: """
                    "I'm due for a win" after 5 losses.

                    FALSE: Each outcome is independent. Past results don't affect future probability.

                    Coin flip: 10 heads in a row doesn't make tails more likely next flip.

                    Your brain sees patterns in randomness that don't exist.
                    """
                ),
                ModuleCard(
                    emoji: "🔥",
                    title: "The Hot Hand Fallacy",
                    description: """
                    "I'm on a streak, keep betting!"

                    FALSE: Streaks are luck, not skill. They always end.

                    You remember the 3 wins in a row. You forget the 10 losses that came after.

                    Your brain tricks you into thinking you're "hot" when it's just random chance.
                    """
                ),
                ModuleCard(
                    emoji: "✋",
                    title: "The Truth About Your Losses",
                    description: """
                    Past losses are not debts you owe the universe.

                    That money is GONE. More gambling can't recover it.

                    Acceptance: you can't undo the past, only protect the future.
                    """
                ),
                ModuleCard(
                    emoji: "🛡️",
                    title: "Breaking the Chase Cycle",
                    description: """
                    Recognize the thought: "I need to win it back."

                    Challenge it: "That money is gone. More bets = more losses."

                    Stopping NOW prevents FUTURE losses. That's the actual win.

                    Every dollar you don't bet today is a dollar you keep.
                    """
                ),
                ModuleCard(
                    emoji: "📚",
                    title: "Sources",
                    description: """
                    • Kahneman & Tversky (1979): "Prospect Theory: An Analysis of Decision under Risk" (Loss aversion, Nobel Prize 2002)

                    • The Decision Lab: "Prospect Theory" (Sunk cost fallacy research)
                    """
                ),
                ModuleCard(
                    emoji: "📖",
                    title: "Additional Sources",
                    description: """
                    • Behavioral Economics: "Gambler's Fallacy" (Well-documented cognitive bias)

                    • The Decision Lab: "Hot Hand Fallacy" (Regression to mean research)
                    """
                )
            ],
            hasInteractiveFeature: false
        ),

        // Lesson 3: Slot Machines
        LessonContent(
            slug: "slot_machines",
            title: "How Slot Machines Are Designed to Enslave You",
            subtitle: "The science of addiction by design",
            icon: "camera.metering.matrix",
            cards: [
                ModuleCard(
                    emoji: "🎰",
                    title: "The Near-Miss Effect",
                    description: """
                    Getting two 7s and missing the third feels like "almost winning." Your brain treats this as progress and releases dopamine just like an actual win.

                    Studies show near-misses activate the same brain regions as real wins. Neurologically, losing becomes indistinguishable from winning. This keeps you playing.
                    """
                ),
                ModuleCard(
                    emoji: "🎲",
                    title: "Variable Reward Schedules",
                    description: """
                    This is the most addictive pattern in behavioral psychology. Unpredictable rewards create stronger compulsion than predictable ones.

                    Slot machines are programmed with variable ratio schedules. This is the same technique used in animal addiction studies to create the strongest compulsive behavior.
                    """
                ),
                ModuleCard(
                    emoji: "🐀",
                    title: "Your Brain Is Being Conditioned",
                    description: """
                    Just like lab rats pressing levers for random food pellets, your brain is being conditioned to keep playing for random payouts.

                    The randomness is what makes it so addictive. You never know when the next win is coming, so you keep going. This is behavioral conditioning at its most powerful.
                    """
                ),
                ModuleCard(
                    emoji: "💡",
                    title: "Every Sound and Light Triggers Dopamine",
                    description: """
                    Every sound, flash, and animation is designed to trigger dopamine in your brain. Winning sounds play even on losses and near-misses to trick you into feeling like you're succeeding.

                    High-pitched sounds create excitement and dopamine spikes. These sensory cues keep your brain engaged and craving more.
                    """
                ),
                ModuleCard(
                    emoji: "🎨",
                    title: "Colors and Design Weaponized Against You",
                    description: """
                    Red and yellow colors stimulate arousal and risk-taking behavior. Bright flashing lights keep your attention locked on the machine.

                    Casinos hire neuroscientists specifically to make machines more addictive. Every element is engineered to exploit your brain. This is war, and you're unarmed.
                    """
                ),
                ModuleCard(
                    emoji: "📚",
                    title: "Sources",
                    description: """
                    • PMC: "Gambling Near-Misses Enhance Motivation to Gamble and Recruit Win-Related Brain Circuitry"

                    • University of Cambridge: "Near misses are like winning to problem gamblers" (Dr. Luke Clark research)

                    • Journal of Neuroscience: "Gambling Severity Predicts Midbrain Response to Near-Miss Outcomes"
                    """
                )
            ],
            hasInteractiveFeature: false
        ),

        // Lesson 4: Sports Betting Science
        LessonContent(
            slug: "science_sports_addiction",
            title: "The Science Behind Sports Betting Addiction",
            subtitle: "Why it's uniquely dangerous",
            icon: "sportscourt.fill",
            cards: [
                ModuleCard(
                    emoji: "⚖️",
                    title: "How the Gambling Crisis Started",
                    description: """
                    In 2006, online gambling was effectively banned in the US. But there was a loophole for "skill games" like fantasy sports.

                    Fantasy sports companies exploited this loophole and normalized online betting. DraftKings and FanDuel made gambling feel like a hobby, not an addiction risk.

                    Then in 2018, the Supreme Court struck down the federal sports betting ban. The floodgates opened. Now every state can legalize sports betting, and apps are everywhere.
                    """
                ),
                ModuleCard(
                    emoji: "📱",
                    title: "Why Sports Betting Is Worse Than Casinos",
                    description: """
                    Casinos require you to travel and have discrete sessions. You have to physically go somewhere to gamble.

                    Sports betting gives you 24/7 access in your pocket. You never leave. Live in-play betting creates constant dopamine hits during games with microbets every 30 seconds.

                    Your brain never leaves the gambling state. The game is always on, and you can always bet.
                    """
                ),
                ModuleCard(
                    emoji: "🧠",
                    title: "The False Expertise Trap",
                    description: """
                    At a casino, you know the games are random. You understand it's pure luck. But with sports, you think differently.

                    You believe "I know football. I watch every game. I have an edge over the books." This belief is what keeps you betting even after massive losses.
                    """
                ),
                ModuleCard(
                    emoji: "🎯",
                    title: "You Never Had an Edge",
                    description: """
                    The truth is the sportsbooks employ professional oddsmakers, use advanced algorithms, and have decades of data. You don't have an edge. You never did.

                    Research shows sports bettors have lower quit rates than casino gamblers precisely because of this false expertise belief. You keep betting because you think you know something the books don't.
                    """
                ),
                ModuleCard(
                    emoji: "📊",
                    title: "You Don't Know More Than the Books",
                    description: """
                    The books are designed to win. They adjust lines in real time based on betting patterns, injury reports, weather, and thousands of variables you can't track.

                    When you win, it's luck. When you lose, it's the system working exactly as designed.
                    """
                ),
                ModuleCard(
                    emoji: "🔄",
                    title: "Research Only Deepens the Addiction",
                    description: """
                    The endless research and analysis you do only deepens the addiction by making you feel like you're learning and improving.

                    You're not getting better at betting. You're getting better at justifying losses.
                    """
                ),
                ModuleCard(
                    emoji: "📚",
                    title: "Sources",
                    description: """
                    • PMC: "Neurobiology of Gambling Behaviors" (24/7 access, in-play betting effects)

                    • Scientific American: "How the Brain Gets Addicted to Gambling"

                    • Journal of Gambling Studies: "Sports betting has lower treatment-seeking and quit rates than casino gambling due to illusion of control and false expertise beliefs"
                    """
                )
            ],
            hasInteractiveFeature: false
        ),

        // Lesson 5: Parlay Math
        LessonContent(
            slug: "parlay_math",
            title: "The Parlay Math: Why You'll Never Win",
            subtitle: "The mathematics of false hope",
            icon: "function",
            cards: [
                ModuleCard(
                    emoji: "💰",
                    title: "The Parlay Seduction",
                    description: """
                    A $10 bet with 5 legs could pay out $5,000. Your brain fixates on that massive payout and completely ignores the probability of actually hitting it.

                    Sportsbooks love parlays because they have the highest profit margins. This isn't betting. It's buying lottery tickets with worse odds.
                    """
                ),
                ModuleCard(
                    emoji: "📺",
                    title: "Why They Always Advertise Parlays",
                    description: """
                    Every sportsbook ad pushes parlays. Why? Because they're the most losing bets you can make.

                    The house makes more money on parlays than any other bet type. When you see ads showing someone hitting a massive parlay, that's bait. They're advertising the one winner and hiding the thousands of losers.
                    """
                ),
                ModuleCard(
                    emoji: "🧮",
                    title: "The Actual Math",
                    description: """
                    Each individual leg at standard -110 odds requires a 52.4% win rate just to break even. When you combine multiple legs, the probability drops fast.

                    A 2-leg parlay has a 27.5% win rate. A 3-leg parlay drops to 14.4%. By the time you hit a 5-leg parlay, you're down to a 3.7% chance of winning.
                    """
                ),
                ModuleCard(
                    emoji: "📉",
                    title: "The Math Never Lies",
                    description: """
                    To break even on one winning 5-leg parlay, you would need to hit 27 of them in a row. The house edge compounds with each additional leg you add.

                    Every leg you add makes the math worse for you and better for the sportsbook. The odds are designed to drain your bankroll slowly while giving you just enough hope to keep playing.
                    """
                ),
                ModuleCard(
                    emoji: "🧠",
                    title: "Why You Remember the Wins (Availability Bias)",
                    description: """
                    Your brain suffers from availability bias. The wins are vivid and memorable, so they're easier to recall. You remember the one parlay you hit and forget the 26 that lost.

                    Your brain encodes wins as proof the system works. Losses feel like bad luck or flukes, not math working exactly as designed.
                    """
                ),
                ModuleCard(
                    emoji: "⏰",
                    title: "The Memory Trap",
                    description: """
                    That parlay you hit six months ago still feels possible today. Your brain fetches that memory easily because it was exciting and emotionally charged.

                    Meanwhile, the dozens of parlays you lost fade from memory. Math doesn't care about your memory. The odds never change. Every new parlay has the same terrible probability.
                    """
                )
            ],
            hasInteractiveFeature: false
        ),

        // Lesson 6: Brain Healing Timeline
        LessonContent(
            slug: "brain_health",
            title: "The Timeline: When Your Brain Actually Heals",
            subtitle: "Recovery milestones backed by science",
            icon: "chart.line.uptrend.xyaxis",
            cards: [
                ModuleCard(
                    emoji: "🧠",
                    title: "Your Brain Is Physically Healing",
                    description: """
                    Recovery isn't just willpower. It's biology. Your brain is physically repairing itself from the damage gambling caused.

                    These changes are measurable with brain scans. The timeline is predictable. Here's what the science says about when your brain actually heals.
                    """
                ),
                ModuleCard(
                    emoji: "📅",
                    title: "Days 1-7: Acute Withdrawal Phase",
                    description: """
                    Dopamine receptors begin to regenerate. Your brain starts responding to normal rewards again instead of only reacting to gambling.

                    Sleep quality starts improving. Decision-making centers in the prefrontal cortex begin coming back online, which means better impulse control.
                    """
                ),
                ModuleCard(
                    emoji: "⚡",
                    title: "Days 14-21: Momentum Builds",
                    description: """
                    Dopamine receptor density continues improving. Prefrontal cortex function measurably stronger. Sleep architecture normalizes, and stress hormone levels drop.

                    You're through the acute withdrawal phase. The worst is behind you.
                    """
                ),
                ModuleCard(
                    emoji: "📈",
                    title: "The 30-Day Mark",
                    description: """
                    Dopamine sensitivity 30-40% improved compared to when you started. Urge frequency drops by roughly 50%.

                    Cognitive function measurably better: focus, memory, and decision-making all show improvement. This is when recovery starts feeling "real."
                    """
                ),
                ModuleCard(
                    emoji: "🔬",
                    title: "90 Days and Beyond",
                    description: """
                    Brain structure continues repairing. Gray matter volume in the prefrontal cortex increases. Dopamine pathways closer to baseline.

                    Most people report urges become rare and manageable. Your brain is healing whether you feel it every day or not. Trust the process.
                    """
                )
            ],
            hasInteractiveFeature: false
        )
    ]
}
