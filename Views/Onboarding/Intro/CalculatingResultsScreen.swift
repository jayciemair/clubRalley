//
//  CalculatingResultsScreen.swift
//  Club Ralley
//
//  Loading screen before showing attachment results
//

import SwiftUI

// Progress segment types for animated loading
enum ProgressSegment {
    case ramp(to: Double, duration: Double, easing: EasingFunction)
    case hold(at: Double, duration: Double)

    var duration: Double {
        switch self {
        case .ramp(_, let duration, _), .hold(_, let duration):
            return duration
        }
    }
}

// Easing functions for natural motion
enum EasingFunction {
    case linear
    case easeIn
    case easeOut
    case easeInOut
    case easeInQuad
    case easeOutQuad

    func apply(_ t: Double) -> Double {
        switch self {
        case .linear:
            return t
        case .easeIn:
            return t * t
        case .easeOut:
            return t * (2 - t)
        case .easeInOut:
            return t < 0.5 ? 2 * t * t : -1 + (4 - 2 * t) * t
        case .easeInQuad:
            return t * t * t
        case .easeOutQuad:
            return 1 - pow(1 - t, 3)
        }
    }
}

struct CalculatingResultsScreen: View {
    @EnvironmentObject var flowController: OnboardingFlowController
    @State private var progress: Double = 0.0
    @State private var currentMessageIndex = 0
    @State private var timer: Timer?
    @State private var startTime: Date?
    @State private var lastMessageChangeTime: Date?
    @State private var lastHapticPercent: Int = 0
    @State private var isComplete: Bool = false

    private let updateInterval: Double = 1.0 / 60.0

    // Segment-based progress profile
    private let progressProfile: [ProgressSegment] = [
        .ramp(to: 0.15, duration: 0.6, easing: .easeOut),
        .ramp(to: 0.25, duration: 0.4, easing: .linear),
        .hold(at: 0.25, duration: 0.3),
        .ramp(to: 0.45, duration: 0.5, easing: .easeIn),
        .ramp(to: 0.65, duration: 0.7, easing: .easeOut),
        .hold(at: 0.65, duration: 0.5),
        .ramp(to: 0.85, duration: 0.6, easing: .easeInOut),
        .ramp(to: 0.92, duration: 0.4, easing: .easeOut),
        .hold(at: 0.92, duration: 0.4),
        .ramp(to: 1.0, duration: 0.8, easing: .easeOutQuad)
    ]

    // Messages for breakup context
    private let messages: [(text: String, minDuration: Double)] = [
        ("looking at your responses...", 1.2),
        ("understanding your situation...", 1.5),
        ("building your healing path...", 1.0),
        ("done!", 1.0)
    ]

    var body: some View {
        ZStack {
            // Soft pink gradient
            OnboardingGradientBackground(style: .mochiWelcome, animated: true)

            VStack(spacing: 40) {
                Spacer()

                // Title
                VStack {
                    Text(isComplete ? "done!" : "one sec...")
                        .font(.custom("Satoshi-Bold", size: 36))
                        .foregroundColor(Color(hex: "#4A2040"))
                        .multilineTextAlignment(.center)
                        .animation(nil, value: isComplete)
                }
                .frame(height: 70)
                .padding(.horizontal, 24)

                // Current progress message
                VStack {
                    if !isComplete {
                        Text(currentMessage)
                            .font(.custom("Satoshi-Regular", size: 16))
                            .foregroundColor(Color(hex: "#6A3060").opacity(0.7))
                            .multilineTextAlignment(.center)
                            .animation(nil, value: currentMessageIndex)
                    }
                }
                .frame(height: 20)
                .padding(.horizontal, 24)

                // Progress Bar
                VStack(spacing: 8) {
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            // Background
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color(hex: "#6A3060").opacity(0.2))
                                .frame(height: 8)

                            // Progress fill - pink gradient
                            RoundedRectangle(cornerRadius: 8)
                                .fill(
                                    LinearGradient(
                                        colors: [Color(hex: "#FE9CDD"), Color(hex: "#E080C0")],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: geometry.size.width * CGFloat(progress), height: 8)
                        }
                    }
                    .frame(height: 8)
                    .padding(.horizontal, 40)

                    // Percentage text
                    Text("\(Int(progress * 100))%")
                        .font(.custom("Satoshi-Bold", size: 48))
                        .foregroundColor(Color(hex: "#4A2040"))
                        .padding(.top, 12)
                }

                Spacer()
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .onAppear {
            startAnimation()
        }
        .onDisappear {
            timer?.invalidate()
        }
    }

    private var currentMessage: String {
        messages[currentMessageIndex].text
    }

    private func startAnimation() {
        startTime = Date()
        lastMessageChangeTime = Date()
        progress = 0.0
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()

        var cumulativeDurations: [Double] = []
        var totalDuration = 0.0
        for segment in progressProfile {
            totalDuration += segment.duration
            cumulativeDurations.append(totalDuration)
        }

        timer = Timer.scheduledTimer(withTimeInterval: updateInterval, repeats: true) { _ in
            guard let startTime = self.startTime else { return }

            let elapsed = Date().timeIntervalSince(startTime)

            var segmentIndex = 0
            var segmentStartTime = 0.0
            for (index, cumDuration) in cumulativeDurations.enumerated() {
                if elapsed < cumDuration {
                    segmentIndex = index
                    if index > 0 {
                        segmentStartTime = cumulativeDurations[index - 1]
                    }
                    break
                }
            }

            let segment = self.progressProfile[segmentIndex]
            let segmentElapsed = elapsed - segmentStartTime
            let segmentProgress = min(1.0, segmentElapsed / segment.duration)

            switch segment {
            case .ramp(let targetProgress, _, let easing):
                let startProgress = segmentIndex > 0 ? self.getSegmentEndProgress(segmentIndex - 1) : 0.0
                let easedProgress = easing.apply(segmentProgress)
                self.progress = startProgress + (targetProgress - startProgress) * easedProgress

            case .hold(let holdProgress, _):
                self.progress = holdProgress
            }

            // Update messages
            if let lastChange = self.lastMessageChangeTime {
                let timeSinceLastChange = Date().timeIntervalSince(lastChange)
                let currentMessage = self.messages[self.currentMessageIndex]

                if timeSinceLastChange >= currentMessage.minDuration &&
                   self.currentMessageIndex < self.messages.count - 2 {
                    let nextMessageProgress = Double(self.currentMessageIndex + 1) / Double(self.messages.count - 1)
                    if self.progress >= nextMessageProgress * 0.8 {
                        self.currentMessageIndex += 1
                        self.lastMessageChangeTime = Date()
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    }
                }
            }

            // Haptic feedback
            let currentPercent = Int(self.progress * 100)
            if currentPercent != self.lastHapticPercent {
                let percentDelta = abs(currentPercent - self.lastHapticPercent)
                if percentDelta >= 5 || currentPercent % 10 == 0 {
                    let style: UIImpactFeedbackGenerator.FeedbackStyle = percentDelta > 2 ? .soft : .light
                    UIImpactFeedbackGenerator(style: style).impactOccurred()
                    self.lastHapticPercent = currentPercent
                }
            }

            // Complete animation
            if elapsed >= totalDuration && !self.isComplete {
                self.timer?.invalidate()
                self.progress = 1.0
                self.isComplete = true
                self.currentMessageIndex = self.messages.count - 1
                UIImpactFeedbackGenerator(style: .heavy).impactOccurred()

                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    flowController.navigateNext()
                }
            }
        }
    }

    private func getSegmentEndProgress(_ index: Int) -> Double {
        guard index >= 0 && index < progressProfile.count else { return 0.0 }

        let segment = progressProfile[index]
        switch segment {
        case .ramp(let to, _, _):
            return to
        case .hold(let at, _):
            return at
        }
    }
}

struct CalculatingResultsScreen_Previews: PreviewProvider {
    static var previews: some View {
        CalculatingResultsScreen()
            .environmentObject(OnboardingFlowController())
    }
}
