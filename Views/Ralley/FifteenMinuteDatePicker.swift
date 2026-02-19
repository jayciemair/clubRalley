//
//  FifteenMinuteDatePicker.swift
//  Club Ralley
//
//  Date picker with time restricted to 15-minute intervals
//

import SwiftUI

struct FifteenMinuteDatePicker: View {
    @Binding var selection: Date
    var minimumDate: Date?

    /// Minutes from midnight, snapped to nearest 15
    private var currentSlot: Int {
        let cal = Calendar.current
        let hour = cal.component(.hour, from: selection)
        let minute = cal.component(.minute, from: selection)
        return hour * 60 + ((minute / 15) * 15)
    }

    /// All 96 fifteen-minute slots in a day (0, 15, 30, ... 1425)
    private let timeSlots: [Int] = Array(stride(from: 0, to: 1440, by: 15))

    var body: some View {
        HStack {
            // Date — native SwiftUI picker (renders correctly)
            DatePicker(
                "",
                selection: $selection,
                in: (minimumDate ?? .distantPast)...,
                displayedComponents: .date
            )
            .labelsHidden()
            .tint(Color(hex: "#2C4F40"))

            // Time — menu picker showing only 15-min intervals
            Picker("Time", selection: slotBinding) {
                ForEach(timeSlots, id: \.self) { slot in
                    Text(formatSlot(slot)).tag(slot)
                }
            }
            .tint(Color(hex: "#2C4F40"))
        }
    }

    /// Two-way binding between the Date and the selected time slot
    private var slotBinding: Binding<Int> {
        Binding(
            get: { currentSlot },
            set: { newSlot in
                let cal = Calendar.current
                var components = cal.dateComponents([.year, .month, .day], from: selection)
                components.hour = newSlot / 60
                components.minute = newSlot % 60
                if let newDate = cal.date(from: components) {
                    selection = newDate
                }
            }
        )
    }

    private func formatSlot(_ minutesFromMidnight: Int) -> String {
        let hour = minutesFromMidnight / 60
        let minute = minutesFromMidnight % 60
        let period = hour >= 12 ? "PM" : "AM"
        let displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour)
        return String(format: "%d:%02d %@", displayHour, minute, period)
    }
}
