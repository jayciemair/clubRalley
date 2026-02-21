//
//  MochiJourneyScreen.swift
//  Club Ralley
// 
//  Shows the emotional journey graph with Mochi following along
//   j

import SwiftUI

struct MochiJourneyScreen: View {
    @EnvironmentObject var flowController: OnboardingFlowController

    @State private var showTitle: Bool = true  // Always visible
    @State private var journeyLineProgress: CGFloat = 0
    @State private var mochiLineProgress: CGFloat = 0
    @State private var showButton: Bool = false
    @State private var bubbleOpacity: Double = 0
    @State private var displayedText: String = ""
    @State private var typingComplete: Bool = false
    @State private var currentPhrase: Int = 0

    private let phrases = [
        "breakups are full of highs and lows.",
        "but don't worry, i'll join your journey"
    ]

    // The emotional journey points - wavy ups and downs (normalized 0-1 for Y)
    private let journeyPoints: [CGFloat] = [
        0.5,  // Start middle
        0.75, // Up
        0.25, // Down
        0.7,  // Up
        0.3,  // Down
        0.75, // Up
        0.25, // Down
        0.7,  // Up
        0.3,  // Down
        0.75, // Up
        0.25, // Down
        0.5   // End middle
    ]

    var body: some View {
        ZStack {
            OnboardingGradientBackground(style: .mochiWelcome, animated: true)

            OnboardingScrollableLayout(
                showBackButton: true,
                showContinueButton: showButton,
                backgroundColor: .clear
            ) {
                VStack(spacing: 0) {
                    Spacer()
                        .frame(height: 20)

                    // Mochi with speech bubble to the right
                    HStack(alignment: .top, spacing: 8) {
                        Image("Mochi")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 90, height: 90)

                        // Speech bubble with typing animation (tail points left to Mochi)
                        // Fixed height so content below doesn't shift
                        ZStack(alignment: .topLeading) {
                            // Invisible placeholder for full text size
                            Text("breakups are full of highs and lows.\n\nbut don't worry, i'll be here")
                                .font(.custom("Satoshi-Medium", size: 24))
                                .foregroundColor(.clear)
                                .multilineTextAlignment(.leading)
                                .lineLimit(nil)
                                .fixedSize(horizontal: false, vertical: true)

                            // Actual displayed text
                            Text(displayedText)
                                .font(.custom("Satoshi-Medium", size: 24))
                                .foregroundColor(Color(hex: "#4A2040"))
                                .multilineTextAlignment(.leading)
                                .lineLimit(nil)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.leading, 20)
                        .padding(.trailing, 16)
                        .padding(.vertical, 12)
                        .background(
                            LeftTailBubbleShape(tailOffset: 30)
                                .fill(Color.white.opacity(0.7))
                        )
                        .overlay(
                            LeftTailBubbleShape(tailOffset: 30)
                                .stroke(Color(hex: "#E080C0").opacity(0.5), lineWidth: 1.5)
                        )
                        .opacity(bubbleOpacity)
                    }
                    .padding(.horizontal, 24)

                    Spacer()
                        .frame(height: 60)

                    // Title above graph
                    Text("the breakup journey")
                        .font(.custom("Satoshi-Bold", size: 22))
                        .foregroundColor(Color(hex: "#4A2040"))
                        .opacity(showTitle ? 1 : 0)
                        .padding(.horizontal, 24)

                    Spacer()
                        .frame(height: 12)

                    // Graph container
                    ZStack {
                        // Graph background
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.white.opacity(0.7))

                        // Graph area
                        GeometryReader { geometry in
                            let graphWidth = geometry.size.width
                            let graphHeight = geometry.size.height

                            ZStack {
                                // Journey line (gray/neutral)
                                JourneyLinePath(points: journeyPoints, progress: journeyLineProgress)
                                    .stroke(
                                        Color(hex: "#6A3060").opacity(0.3),
                                        style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round)
                                    )

                                // Mochi line (pink) - traces the same path
                                JourneyLinePath(points: journeyPoints, progress: mochiLineProgress)
                                    .stroke(
                                        Color(hex: "#FE9CDD"),
                                        style: StrokeStyle(lineWidth: 4, lineCap: .round, lineJoin: .round)
                                    )

                                // Mochi at the tip of the line - moves with the trace
                                MochiTracer(
                                    points: journeyPoints,
                                    progress: mochiLineProgress,
                                    graphWidth: graphWidth,
                                    graphHeight: graphHeight
                                )
                            }
                        }
                        .padding(20)
                    }
                    .frame(height: 220)
                    .padding(.horizontal, 24)

                    Spacer()
                }
            } continueAction: {
                flowController.saveData(for: "mochi_journey", data: [
                    "viewed": true,
                    "timestamp": Date().timeIntervalSince1970
                ])
                flowController.navigateNext()
            }
        }
        .onAppear {
            animateSequence()
        }
    }

    private func animateSequence() {
        // Show bubble and start typing
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(.easeOut(duration: 0.3)) {
                bubbleOpacity = 1
            }
            typeNextPhrase()
        }
    }

    private func typeNextPhrase() {
        guard currentPhrase < phrases.count else {
            // All phrases done
            typingComplete = true
            return
        }

        let phrase = phrases[currentPhrase]
        let characters = Array(phrase)
        var charIndex = 0
        let typingSpeed = 0.045 // Slower typing

        let lightGenerator = UIImpactFeedbackGenerator(style: .light)
        lightGenerator.prepare()

        Timer.scheduledTimer(withTimeInterval: typingSpeed, repeats: true) { timer in
            if charIndex < characters.count {
                // Add newline before second phrase
                if currentPhrase > 0 && charIndex == 0 {
                    displayedText.append("\n\n")
                }
                displayedText.append(characters[charIndex])
                charIndex += 1

                // Haptic on every few characters
                if charIndex % 3 == 0 {
                    lightGenerator.impactOccurred()
                }
            } else {
                timer.invalidate()
                let justFinishedPhrase = currentPhrase
                currentPhrase += 1

                // After first phrase: draw the gray graph
                if justFinishedPhrase == 0 {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        withAnimation(.easeInOut(duration: 3.0)) {
                            journeyLineProgress = 1.0
                        }
                    }
                    // Start second phrase after gray line is mostly drawn
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                        typeNextPhrase()
                    }
                }
                // After second phrase: Mochi traces over
                else if justFinishedPhrase == 1 {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        withAnimation(.easeInOut(duration: 3.5)) {
                            mochiLineProgress = 1.0
                        }
                    }
                    // Show button after Mochi finishes
                    DispatchQueue.main.asyncAfter(deadline: .now() + 4.5) {
                        withAnimation(.easeOut(duration: 0.3)) {
                            showButton = true
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Mochi Tracer (Animatable position at line tip)

private struct MochiTracer: View, Animatable {
    var points: [CGFloat]
    var progress: CGFloat
    var graphWidth: CGFloat
    var graphHeight: CGFloat

    var animatableData: CGFloat {
        get { progress }
        set { progress = newValue }
    }

    var body: some View {
        let position = getPosition()

        Image("Mochi")
            .resizable()
            .scaledToFit()
            .frame(width: 40, height: 40)
            .position(x: position.x, y: position.y)
            .opacity(progress > 0.01 ? 1 : 0)
    }

    private func getPosition() -> CGPoint {
        guard points.count > 1, progress > 0 else {
            // Start position
            let startY = graphHeight - points[0] * graphHeight
            return CGPoint(x: 0, y: startY)
        }

        let pointCount = points.count
        let totalSegments = CGFloat(pointCount - 1)
        let currentSegment = progress * totalSegments
        let segmentIndex = min(Int(currentSegment), pointCount - 2)
        let segmentProgress = currentSegment - CGFloat(segmentIndex)

        let startY = points[segmentIndex]
        let endY = points[min(segmentIndex + 1, pointCount - 1)]

        let stepX = graphWidth / totalSegments
        let x = CGFloat(segmentIndex) * stepX + segmentProgress * stepX

        // Smooth curve interpolation to match the bezier curve
        let t = segmentProgress
        // Approximate the cubic bezier Y position
        let smoothT = t * t * (3 - 2 * t) // Smoothstep
        let y = graphHeight - (startY + (endY - startY) * smoothT) * graphHeight

        return CGPoint(x: x, y: y)
    }
}

// MARK: - Journey Line Path (Smooth Curves)

private struct JourneyLinePath: Shape {
    var points: [CGFloat]
    var progress: CGFloat

    var animatableData: CGFloat {
        get { progress }
        set { progress = newValue }
    }

    func path(in rect: CGRect) -> Path {
        let path = Path()
        guard points.count > 1 else { return path }

        let width = rect.width
        let height = rect.height
        let stepX = width / CGFloat(points.count - 1)

        // Convert to CGPoints
        var cgPoints: [CGPoint] = []
        for i in 0..<points.count {
            cgPoints.append(CGPoint(
                x: CGFloat(i) * stepX,
                y: height - points[i] * height
            ))
        }

        // Build the full smooth path first
        let fullPath = createSmoothPath(points: cgPoints)

        // Trim based on progress
        return fullPath.trimmedPath(from: 0, to: progress)
    }

    private func createSmoothPath(points: [CGPoint]) -> Path {
        var path = Path()
        guard points.count > 1 else { return path }

        path.move(to: points[0])

        for i in 1..<points.count {
            let current = points[i]
            let previous = points[i - 1]

            // Control points for smooth curve
            let midX = (previous.x + current.x) / 2

            path.addCurve(
                to: current,
                control1: CGPoint(x: midX, y: previous.y),
                control2: CGPoint(x: midX, y: current.y)
            )
        }

        return path
    }
}

// MARK: - Left Tail Bubble Shape (tail points left)

private struct LeftTailBubbleShape: Shape {
    var tailOffset: CGFloat = 30
    var tailSize: CGFloat = 10
    var cornerRadius: CGFloat = 16

    func path(in rect: CGRect) -> Path {
        var path = Path()

        let tailY = tailOffset
        let tailHeight: CGFloat = 14

        // Start at top-left corner (after radius)
        path.move(to: CGPoint(x: tailSize + cornerRadius, y: 0))

        // Top edge
        path.addLine(to: CGPoint(x: rect.width - cornerRadius, y: 0))

        // Top-right corner
        path.addQuadCurve(
            to: CGPoint(x: rect.width, y: cornerRadius),
            control: CGPoint(x: rect.width, y: 0)
        )

        // Right edge
        path.addLine(to: CGPoint(x: rect.width, y: rect.height - cornerRadius))

        // Bottom-right corner
        path.addQuadCurve(
            to: CGPoint(x: rect.width - cornerRadius, y: rect.height),
            control: CGPoint(x: rect.width, y: rect.height)
        )

        // Bottom edge
        path.addLine(to: CGPoint(x: tailSize + cornerRadius, y: rect.height))

        // Bottom-left corner
        path.addQuadCurve(
            to: CGPoint(x: tailSize, y: rect.height - cornerRadius),
            control: CGPoint(x: tailSize, y: rect.height)
        )

        // Left edge down to tail
        path.addLine(to: CGPoint(x: tailSize, y: tailY + tailHeight))

        // Tail pointing left
        path.addLine(to: CGPoint(x: 0, y: tailY + tailHeight / 2))
        path.addLine(to: CGPoint(x: tailSize, y: tailY))

        // Left edge up to top-left corner
        path.addLine(to: CGPoint(x: tailSize, y: cornerRadius))

        // Top-left corner
        path.addQuadCurve(
            to: CGPoint(x: tailSize + cornerRadius, y: 0),
            control: CGPoint(x: tailSize, y: 0)
        )

        path.closeSubpath()
        return path
    }
}

// MARK: - Speech Bubble Shape (tail points up)

private struct SpeechBubbleShape: Shape {
    var tailOffset: CGFloat = 50
    var tailSize: CGFloat = 12
    var cornerRadius: CGFloat = 16

    func path(in rect: CGRect) -> Path {
        var path = Path()

        let tailX = tailOffset
        let tailWidth: CGFloat = 16

        // Start at top-left corner (after radius)
        path.move(to: CGPoint(x: cornerRadius, y: tailSize))

        // Tail pointing up
        path.addLine(to: CGPoint(x: tailX, y: tailSize))
        path.addLine(to: CGPoint(x: tailX + tailWidth / 2, y: 0))
        path.addLine(to: CGPoint(x: tailX + tailWidth, y: tailSize))

        // Top edge to top-right corner
        path.addLine(to: CGPoint(x: rect.width - cornerRadius, y: tailSize))

        // Top-right corner
        path.addQuadCurve(
            to: CGPoint(x: rect.width, y: tailSize + cornerRadius),
            control: CGPoint(x: rect.width, y: tailSize)
        )

        // Right edge
        path.addLine(to: CGPoint(x: rect.width, y: rect.height - cornerRadius))

        // Bottom-right corner
        path.addQuadCurve(
            to: CGPoint(x: rect.width - cornerRadius, y: rect.height),
            control: CGPoint(x: rect.width, y: rect.height)
        )

        // Bottom edge
        path.addLine(to: CGPoint(x: cornerRadius, y: rect.height))

        // Bottom-left corner
        path.addQuadCurve(
            to: CGPoint(x: 0, y: rect.height - cornerRadius),
            control: CGPoint(x: 0, y: rect.height)
        )

        // Left edge
        path.addLine(to: CGPoint(x: 0, y: tailSize + cornerRadius))

        // Top-left corner
        path.addQuadCurve(
            to: CGPoint(x: cornerRadius, y: tailSize),
            control: CGPoint(x: 0, y: tailSize)
        )

        path.closeSubpath()
        return path
    }
}

struct MochiJourneyScreen_Previews: PreviewProvider {
    static var previews: some View {
        MochiJourneyScreen()
            .environmentObject(OnboardingFlowController())
    }
}
