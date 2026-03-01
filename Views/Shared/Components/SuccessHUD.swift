//
//  SuccessHUD.swift
//  Dial
//
//  Success overlay shown after completing onboarding
//

import SwiftUI

struct SuccessHUD: View {
    @Binding var isShowing: Bool
    let message: String
    let duration: Double
    
    @State private var opacity: Double = 0
    @State private var scale: CGFloat = 0.8
    
    init(isShowing: Binding<Bool>, message: String = "You're all set!", duration: Double = 2.5) {
        self._isShowing = isShowing
        self.message = message
        self.duration = duration
    }
    
    var body: some View {
        if isShowing {
            VStack(spacing: 16) {
                // Checkmark circle
                ZStack {
                    Circle()
                        .fill(Color.green.opacity(0.15))
                        .frame(width: 64, height: 64)
                    
                    Image(systemName: "checkmark")
                        .font(.system(size: 32, weight: .bold))
                        .fontDesign(.rounded)
                        .foregroundColor(.green)
                }
                
                // Success message
                Text(message)
                    .font(.system(size: 18, weight: .medium))
                    .fontDesign(.rounded)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 32)
            .padding(.vertical, 24)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.black.opacity(0.85))
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
            )
            .scaleEffect(scale)
            .opacity(opacity)
            .onAppear {
                showHUD()
            }
            .transition(.opacity.combined(with: .scale))
        }
    }
    
    private func showHUD() {
        // Haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.prepare()
        
        // Animate in
        withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
            opacity = 1
            scale = 1
            impactFeedback.impactOccurred()
        }
        
        // Auto dismiss after duration
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
            withAnimation(.easeOut(duration: 0.3)) {
                opacity = 0
                scale = 0.8
            }
            
            // Clean up state after animation
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                isShowing = false
            }
        }
    }
}

// MARK: - View Extension for Easy Use

extension View {
    func successHUD(isShowing: Binding<Bool>, message: String = "You're all set!") -> some View {
        ZStack {
            self
            
            if isShowing.wrappedValue {
                ZStack {
                    // Dimmed background
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                        .allowsHitTesting(false)
                    
                    SuccessHUD(isShowing: isShowing, message: message)
                        .allowsHitTesting(false)
                }
                .transition(.opacity)
            }
        }
    }
}

// MARK: - Preview

struct SuccessHUD_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()
            
            VStack {
                Text("Main Content")
                    .foregroundColor(.white)
            }
            .successHUD(isShowing: .constant(true))
        }
    }
}
