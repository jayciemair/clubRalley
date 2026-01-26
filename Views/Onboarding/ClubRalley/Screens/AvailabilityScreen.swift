//
//  AvailabilityScreen.swift
//  Club Ralley
//
//  Availability and preferences screen for scheduling and social preferences
//

import SwiftUI

struct AvailabilityScreen: View {
    @EnvironmentObject var controller: ClubRalleyOnboardingController
    @State private var availabilitySlots: [AvailabilitySlot] = []
    @State private var maxDistance = 25
    @State private var selectedSocialPreferences: [SocialPreference] = []
    
    private let daysOfWeek = [
        "Monday", "Tuesday", "Wednesday", "Thursday", 
        "Friday", "Saturday", "Sunday"
    ]
    
    private let timeSlots = [
        "Early Morning (6-9 AM)",
        "Morning (9 AM-12 PM)",
        "Afternoon (12-5 PM)",
        "Evening (5-8 PM)",
        "Night (8-11 PM)"
    ]
    
    var body: some View {
        OnboardingScrollableLayout {
            VStack(spacing: 32) {
                // Header
                OnboardingHeader(
                    title: controller.currentStep.title,
                    subtitle: controller.currentStep.subtitle
                )
                
                VStack(spacing: 32) {
                    // Quick availability selection
                    VStack(alignment: .leading, spacing: 16) {
                        Text("When are you usually free?")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Text("Select your typical availability (you can always change this later)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        VStack(spacing: 12) {
                            QuickAvailabilityOption(
                                title: "Weekday Evenings",
                                subtitle: "Monday-Friday, 5-8 PM",
                                isSelected: hasWeekdayEvenings,
                                onTap: toggleWeekdayEvenings
                            )
                            
                            QuickAvailabilityOption(
                                title: "Weekends",
                                subtitle: "Saturday-Sunday, flexible times",
                                isSelected: hasWeekends,
                                onTap: toggleWeekends
                            )
                            
                            QuickAvailabilityOption(
                                title: "Morning Person",
                                subtitle: "Early mornings, 6-9 AM",
                                isSelected: hasMornings,
                                onTap: toggleMornings
                            )
                        }
                    }
                    .padding(.horizontal, 32)
                    
                    // Distance preference
                    VStack(alignment: .leading, spacing: 16) {
                        Text("How far will you travel?")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        VStack(spacing: 12) {
                            HStack {
                                Text("Up to \(maxDistance) miles")
                                    .font(.subheadline)
                                    .foregroundColor(.primary)
                                
                                Spacer()
                            }
                            
                            Slider(value: Binding(
                                get: { Double(maxDistance) },
                                set: { maxDistance = Int($0) }
                            ), in: 5...100, step: 5) {
                                Text("Distance")
                            }
                            .tint(.blue)
                            
                            HStack {
                                Text("5 miles")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                Spacer()
                                
                                Text("100 miles")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(.systemGray6))
                        )
                    }
                    .padding(.horizontal, 32)
                    
                    // Social preferences
                    VStack(alignment: .leading, spacing: 16) {
                        Text("What kind of activities do you prefer?")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 12) {
                            ForEach(SocialPreference.allCases, id: \.self) { preference in
                                SocialPreferenceCard(
                                    preference: preference,
                                    isSelected: selectedSocialPreferences.contains(preference),
                                    onTap: {
                                        toggleSocialPreference(preference)
                                    }
                                )
                            }
                        }
                    }
                    .padding(.horizontal, 32)
                }
                
                Spacer()
                
                // Continue button
                ContinueButton(
                    title: "Complete Setup",
                    isEnabled: !availabilitySlots.isEmpty,
                    action: {
                        saveAndContinue()
                    }
                )
                .padding(.horizontal, 32)
                .padding(.bottom, 32)
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Back") {
                    controller.goToPreviousStep()
                }
            }
        }
        .onAppear {
            // Pre-populate if data exists
            let availability = controller.onboardingData.availability
            availabilitySlots = availability.availabilitySlots
            maxDistance = availability.maxDistance
            selectedSocialPreferences = availability.socialPreferences
        }
    }
    
    // Computed properties for quick availability checks
    private var hasWeekdayEvenings: Bool {
        availabilitySlots.contains { slot in
            (1...5).contains(slot.dayOfWeek) && slot.startTime >= "17:00"
        }
    }
    
    private var hasWeekends: Bool {
        availabilitySlots.contains { slot in
            [6, 7].contains(slot.dayOfWeek)
        }
    }
    
    private var hasMornings: Bool {
        availabilitySlots.contains { slot in
            slot.startTime < "09:00"
        }
    }
    
    private func toggleWeekdayEvenings() {
        if hasWeekdayEvenings {
            availabilitySlots.removeAll { slot in
                (1...5).contains(slot.dayOfWeek) && slot.startTime >= "17:00"
            }
        } else {
            for day in 1...5 {
                let slot = AvailabilitySlot(
                    id: UUID(),
                    dayOfWeek: day,
                    startTime: "17:00",
                    endTime: "20:00"
                )
                availabilitySlots.append(slot)
            }
        }
    }
    
    private func toggleWeekends() {
        if hasWeekends {
            availabilitySlots.removeAll { slot in
                [6, 7].contains(slot.dayOfWeek)
            }
        } else {
            for day in [6, 7] {
                let slot = AvailabilitySlot(
                    id: UUID(),
                    dayOfWeek: day,
                    startTime: "10:00",
                    endTime: "18:00"
                )
                availabilitySlots.append(slot)
            }
        }
    }
    
    private func toggleMornings() {
        if hasMornings {
            availabilitySlots.removeAll { slot in
                slot.startTime < "09:00"
            }
        } else {
            for day in 1...7 {
                let slot = AvailabilitySlot(
                    id: UUID(),
                    dayOfWeek: day,
                    startTime: "06:00",
                    endTime: "09:00"
                )
                availabilitySlots.append(slot)
            }
        }
    }
    
    private func toggleSocialPreference(_ preference: SocialPreference) {
        if let index = selectedSocialPreferences.firstIndex(of: preference) {
            selectedSocialPreferences.remove(at: index)
        } else {
            selectedSocialPreferences.append(preference)
        }
    }
    
    private func saveAndContinue() {
        controller.updateAvailability(
            slots: availabilitySlots,
            maxDistance: maxDistance,
            socialPreferences: selectedSocialPreferences
        )
        controller.goToNextStep()
    }
}

// MARK: - Quick Availability Option

struct QuickAvailabilityOption: View {
    let title: String
    let subtitle: String
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.leading)
                    
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.leading)
                }
                
                Spacer()
                
                ZStack {
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(isSelected ? Color.blue : Color(.systemGray4), lineWidth: 2)
                        .frame(width: 20, height: 20)
                    
                    if isSelected {
                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.blue)
                    }
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? Color.blue : Color(.systemGray5), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Social Preference Card

struct SocialPreferenceCard: View {
    let preference: SocialPreference
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                Image(systemName: preference.icon)
                    .font(.title2)
                    .foregroundColor(isSelected ? .blue : .secondary)
                
                Text(preference.displayName)
                    .font(.caption)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(12)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.blue.opacity(0.1) : Color(.systemGray6))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isSelected ? 1.05 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
}

// MARK: - Preview

struct AvailabilityScreen_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            AvailabilityScreen()
                .environmentObject(ClubRalleyOnboardingController())
        }
    }
}