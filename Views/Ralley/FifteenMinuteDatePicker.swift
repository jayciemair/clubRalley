//
//  FifteenMinuteDatePicker.swift
//  Club Ralley
//
//  UIKit-backed date picker that only shows 15-minute intervals
//

import SwiftUI
import UIKit

struct FifteenMinuteDatePicker: UIViewRepresentable {
    @Binding var selection: Date
    var minimumDate: Date?

    func makeUIView(context: Context) -> UIDatePicker {
        let picker = UIDatePicker()
        picker.datePickerMode = .dateAndTime
        picker.preferredDatePickerStyle = .compact
        picker.minuteInterval = 15
        picker.minimumDate = minimumDate
        picker.overrideUserInterfaceStyle = .light
        // Use UIColor directly to avoid SwiftUI Color conversion issues
        picker.tintColor = UIColor(red: 44/255.0, green: 79/255.0, blue: 64/255.0, alpha: 1)
        picker.setContentCompressionResistancePriority(.required, for: .horizontal)
        picker.setContentCompressionResistancePriority(.required, for: .vertical)
        picker.setContentHuggingPriority(.defaultLow, for: .horizontal)
        picker.addTarget(context.coordinator, action: #selector(Coordinator.dateChanged(_:)), for: .valueChanged)

        // Snap initial value to nearest 15 minutes
        let snapped = selection.roundedToNearest15Minutes()
        picker.date = snapped
        if snapped != selection {
            DispatchQueue.main.async { selection = snapped }
        }

        return picker
    }

    func updateUIView(_ picker: UIDatePicker, context: Context) {
        picker.minimumDate = minimumDate
        if picker.date != selection {
            picker.date = selection
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(selection: $selection)
    }

    class Coordinator: NSObject {
        var selection: Binding<Date>

        init(selection: Binding<Date>) {
            self.selection = selection
        }

        @objc func dateChanged(_ picker: UIDatePicker) {
            selection.wrappedValue = picker.date
        }
    }
}
