//
//  RollingNumberView.swift
//  Checkpoint
//
//  Animated rolling number display like a slot machine or odometer
//

import SwiftUI

struct RollingNumberView: View {
    let value: String
    let fontSize: CGFloat
    let fontName: String
    let color: Color

    var body: some View {
        HStack(spacing: fontSize * 0.02) {  // Small positive spacing for natural look
            ForEach(Array(value.enumerated()), id: \.offset) { index, character in
                if character.isNumber {
                    // Use smooth rolling animation for digits
                    SmoothRollingDigitView(
                        targetDigit: Int(String(character)) ?? 0,
                        fontSize: fontSize,
                        fontName: fontName,
                        color: color
                    )
                } else {
                    // Static character (like $ or , or .) - no fixed frame, natural width
                    Text(String(character))
                        .font(.custom(fontName, size: fontSize))
                        .foregroundColor(color)
                }
            }
        }
    }
}

// Wrapper that handles smooth counting animation from old value to new value
struct AnimatedCountingNumberView: View {
    let targetValue: Double
    let fontSize: CGFloat
    let fontName: String
    let color: Color

    @State private var displayedValue: Double?
    @State private var animationTimer: Timer?

    private var formattedValue: String {
        formatAmount(displayedValue ?? targetValue)
    }

    var body: some View {
        RollingNumberView(
            value: formattedValue,
            fontSize: fontSize,
            fontName: fontName,
            color: color
        )
        .onAppear {
            // Initialize to target value immediately without animation
            if displayedValue == nil {
                displayedValue = targetValue
            }
        }
        .onChange(of: targetValue) { newValue in
            // Only animate if we've already been initialized
            if displayedValue != nil {
                animateToValue(newValue)
            } else {
                displayedValue = newValue
            }
        }
    }

    private func animateToValue(_ newValue: Double) {
        guard let startValue = displayedValue else {
            displayedValue = newValue
            return
        }

        let difference = newValue - startValue

        // Don't animate if difference is too small
        guard abs(difference) > 0.01 else {
            displayedValue = newValue
            return
        }

        // Cancel existing animation
        animationTimer?.invalidate()

        // Determine animation duration based on difference
        let duration: TimeInterval
        if abs(difference) < 10 {
            duration = 0.3
        } else if abs(difference) < 100 {
            duration = 0.5
        } else if abs(difference) < 1000 {
            duration = 0.8
        } else {
            duration = 1.2
        }

        let steps = 60 // 60 frames for smooth animation
        let increment = difference / Double(steps)
        let timeInterval = duration / Double(steps)

        var currentStep = 0

        animationTimer = Timer.scheduledTimer(withTimeInterval: timeInterval, repeats: true) { timer in
            currentStep += 1

            if currentStep >= steps {
                displayedValue = newValue
                timer.invalidate()
            } else {
                // Use ease-out curve for smooth deceleration
                let progress = Double(currentStep) / Double(steps)
                let easedProgress = easeOutCubic(progress)
                displayedValue = startValue + (difference * easedProgress)
            }
        }
    }

    // Ease-out cubic function for smooth animation
    private func easeOutCubic(_ t: Double) -> Double {
        let t1 = t - 1
        return t1 * t1 * t1 + 1
    }

    // Format amount with proper decimal places and thousands separators
    private func formatAmount(_ amount: Double) -> String {
        if amount < 10 {
            return String(format: "$%.2f", amount)
        } else if amount < 100 {
            return String(format: "$%.2f", amount)
        } else if amount < 1000 {
            return String(format: "$%.0f", amount)
        } else {
            let formatter = NumberFormatter()
            formatter.numberStyle = .decimal
            formatter.maximumFractionDigits = 0
            formatter.minimumFractionDigits = 0
            formatter.groupingSeparator = ","
            formatter.usesGroupingSeparator = true

            if let formatted = formatter.string(from: NSNumber(value: amount)) {
                return "$\(formatted)"
            } else {
                return String(format: "$%.0f", amount)
            }
        }
    }
}

// DEAD CODE: Static digit view without animation
// Kept for reference but no longer used - we now use SmoothRollingDigitView for animated rolling digits
struct RollingDigitView: View {
    let digit: Character
    let fontSize: CGFloat
    let fontName: String
    let color: Color

    var body: some View {
        Text(String(digit))
            .font(.custom(fontName, size: fontSize))
            .foregroundColor(color)
            .frame(height: fontSize * 1.3)  // Only set height, let width be natural
    }
}

// Alternative: Smooth rolling animation with multiple digits visible
struct SmoothRollingDigitView: View {
    let targetDigit: Int
    let fontSize: CGFloat
    let fontName: String
    let color: Color

    @State private var currentOffset: CGFloat = 0

    private let digitHeight: CGFloat
    private let digitWidth: CGFloat

    init(targetDigit: Int, fontSize: CGFloat, fontName: String, color: Color) {
        self.targetDigit = targetDigit
        self.fontSize = fontSize
        self.fontName = fontName
        self.color = color
        self.digitHeight = fontSize * 1.2

        // Calculate actual width by measuring the widest digit
        let font = UIFont(name: fontName, size: fontSize) ?? UIFont.systemFont(ofSize: fontSize)
        let widestWidth = (0...9).map { digit in
            let text = "\(digit)" as NSString
            return text.size(withAttributes: [.font: font]).width
        }.max() ?? fontSize * 0.6

        self.digitWidth = widestWidth
    }

    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                ForEach(0..<10, id: \.self) { digit in
                    Text("\(digit)")
                        .font(.custom(fontName, size: fontSize))
                        .foregroundColor(color)
                        .frame(height: digitHeight)
                }
            }
            .offset(y: currentOffset)
        }
        .frame(width: digitWidth, height: digitHeight)
        .clipped()
        .onAppear {
            currentOffset = -CGFloat(targetDigit) * digitHeight
        }
        .onChange(of: targetDigit) { newDigit in
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                currentOffset = -CGFloat(newDigit) * digitHeight
            }
        }
    }
}

// MARK: - Preview

struct RollingNumberView_Previews: PreviewProvider {
    struct PreviewWrapper: View {
        @State private var amount: Double = 47.83
        @State private var timer: Timer?

        var formattedAmount: String {
            if amount < 100 {
                return String(format: "$%.2f", amount)
            } else {
                return String(format: "$%.0f", amount)
            }
        }

        var body: some View {
            VStack(spacing: 40) {
                Text("Live Ticker Demo")
                    .font(.title)

                RollingNumberView(
                    value: formattedAmount,
                    fontSize: 60,
                    fontName: "Satoshi-Bold",
                    color: .green
                )

                HStack(spacing: 20) {
                    Button("Start Ticker") {
                        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
                            amount += 0.27  // Simulate per-second savings
                        }
                    }
                    .padding()
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(8)

                    Button("Stop") {
                        timer?.invalidate()
                        timer = nil
                    }
                    .padding()
                    .background(Color.red)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }

                Button("Jump to $1000") {
                    amount = 1000
                }
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(8)
            }
            .padding()
        }
    }

    static var previews: some View {
        PreviewWrapper()
            .preferredColorScheme(.light)
    }
}