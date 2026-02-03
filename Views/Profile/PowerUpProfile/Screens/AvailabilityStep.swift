//
//  AvailabilityStep.swift
//  Club Ralley
//
//  Step 4: Availability preferences for Power Up Profile
//

import SwiftUI

struct AvailabilityStep: View {
    @EnvironmentObject var viewModel: PowerUpProfileViewModel

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 28) {
                // Header
                VStack(spacing: 12) {
                    Text(PowerUpStep.availability.title)
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.black)
                        .multilineTextAlignment(.center)

                    Text(PowerUpStep.availability.subtitle)
                        .font(.system(size: 16))
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 24)
                .padding(.top, 40)

                // Day selection
                VStack(alignment: .leading, spacing: 16) {
                    Text("When are you usually free?")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)

                    VStack(spacing: 10) {
                        ForEach(DaySelection.allCases, id: \.self) { option in
                            DayOptionCard(
                                option: option,
                                isSelected: viewModel.data.daySelection == option,
                                onTap: { viewModel.selectDayOption(option) }
                            )
                        }
                    }

                    // Specific days picker (only show when specific days selected)
                    if viewModel.data.daySelection == .specificDays {
                        VStack(spacing: 12) {
                            Text("Select days")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.secondary)

                            HStack(spacing: 8) {
                                ForEach(DayOfWeek.days, id: \.id) { day in
                                    DayCircleButton(
                                        label: day.shortName,
                                        isSelected: viewModel.data.selectedDays.contains(day.id),
                                        onTap: { viewModel.toggleDay(day.id) }
                                    )
                                }
                            }
                        }
                        .padding(.top, 8)
                    }
                }
                .padding(.horizontal, 24)

                // Time preference
                VStack(alignment: .leading, spacing: 16) {
                    Text("What time works best?")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                        ForEach(TimePreference.allCases, id: \.self) { time in
                            TimePreferenceCard(
                                preference: time,
                                isSelected: viewModel.data.timePreference == time,
                                onTap: { viewModel.data.timePreference = time }
                            )
                        }
                    }
                }
                .padding(.horizontal, 24)

                // Distance slider
                VStack(alignment: .leading, spacing: 16) {
                    Text("How far will you travel?")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)

                    VStack(spacing: 12) {
                        HStack {
                            Text("Up to")
                                .font(.system(size: 15))
                                .foregroundColor(.secondary)

                            Text("\(viewModel.data.maxDistance) miles")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(ClubRalleyTheme.Colors.darkGreen)

                            Spacer()
                        }

                        Slider(
                            value: Binding(
                                get: { Double(viewModel.data.maxDistance) },
                                set: { viewModel.data.maxDistance = Int($0) }
                            ),
                            in: 5...100,
                            step: 5
                        )
                        .tint(ClubRalleyTheme.Colors.darkGreen)

                        HStack {
                            Text("5 mi")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                            Spacer()
                            Text("100 mi")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.systemGray6))
                    )
                }
                .padding(.horizontal, 24)

                // Bottom padding for scroll
                Color.clear.frame(height: 120)
            }
        }
    }
}

// MARK: - Day Option Card

struct DayOptionCard: View {
    let option: DaySelection
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(option.displayName)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.primary)

                    Text(option.subtitle)
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                }

                Spacer()

                ZStack {
                    Circle()
                        .stroke(isSelected ? ClubRalleyTheme.Colors.darkGreen : Color(.systemGray4), lineWidth: 2)
                        .frame(width: 22, height: 22)

                    if isSelected {
                        Circle()
                            .fill(ClubRalleyTheme.Colors.darkGreen)
                            .frame(width: 14, height: 14)
                    }
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? ClubRalleyTheme.Colors.darkGreen : Color(.systemGray5), lineWidth: isSelected ? 2 : 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Day Circle Button

struct DayCircleButton: View {
    let label: String
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            Text(label)
                .font(.system(size: 14, weight: .semibold))
                .frame(width: 40, height: 40)
                .background(
                    Circle()
                        .fill(isSelected ? ClubRalleyTheme.Colors.darkGreen : Color(.systemGray6))
                )
                .foregroundColor(isSelected ? .white : .primary)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Time Preference Card

struct TimePreferenceCard: View {
    let preference: TimePreference
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                Image(systemName: preference.icon)
                    .font(.system(size: 24))
                    .foregroundColor(isSelected ? ClubRalleyTheme.Colors.darkGreen : .secondary)

                Text(preference.displayName)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.primary)

                Text(preference.timeRange)
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? ClubRalleyTheme.Colors.darkGreen.opacity(0.1) : Color(.systemGray6))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? ClubRalleyTheme.Colors.darkGreen : Color.clear, lineWidth: 2)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isSelected ? 1.02 : 1.0)
        .animation(.easeInOut(duration: 0.15), value: isSelected)
    }
}

// MARK: - Preview

struct AvailabilityStep_Previews: PreviewProvider {
    static var previews: some View {
        AvailabilityStep()
            .environmentObject(PowerUpProfileViewModel())
    }
}
