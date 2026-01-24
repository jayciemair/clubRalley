//
//  RecoveryProgramCoordinator.swift
//  Checkpoint
//
//  Coordinates the flow: Breathing Entry -> Program Overview -> Exercises
//

import SwiftUI

struct RecoveryProgramCoordinator: View {
    @ObservedObject private var viewModel = RecoveryProgramViewModel.shared
    @State private var showBreathingEntry = true

    var body: some View {
        ZStack {
            if showBreathingEntry {
                BreathingEntryView {
                    withAnimation(.easeOut(duration: 0.3)) {
                        showBreathingEntry = false
                    }
                }
                .transition(.opacity)
            } else {
                // New: Week-filtered view with colorful cards and top toggle
                ProgramOverviewView_Filtered(viewModel: viewModel)
                    .transition(.opacity)
            }
        }
    }
}

// MARK: - Old implementations kept for reference
// ProgramOverviewView - original flat list (7 modules)
// ProgramOverviewView_Weekly - modal sheet approach (not used)

// MARK: - Preview

#Preview {
    RecoveryProgramCoordinator()
}
