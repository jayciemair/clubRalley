//
//  GetOverHimWidget.swift
//  GetOverHimWidget
//

import WidgetKit
import SwiftUI

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date())
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        completion(SimpleEntry(date: Date()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SimpleEntry>) -> ()) {
        let entry = SimpleEntry(date: Date())
        let timeline = Timeline(entries: [entry], policy: .never)
        completion(timeline)
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
}

struct GetOverHimWidgetEntryView: View {
    var entry: Provider.Entry
    @Environment(\.widgetFamily) var family

    private let pinkColor = Color(red: 254/255, green: 156/255, blue: 221/255) // #FE9CDD

    var body: some View {
        Text("THIS IS YOUR REMINDER TO GET OVER HIM")
            .font(.system(size: fontSize, weight: .bold))
            .foregroundColor(.white)
            .multilineTextAlignment(.center)
            .minimumScaleFactor(0.5)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(8)
            .containerBackground(pinkColor, for: .widget)
    }

    var fontSize: CGFloat {
        switch family {
        case .systemSmall:
            return 24
        case .systemMedium:
            return 36
        case .systemLarge:
            return 56
        default:
            return 24
        }
    }
}

struct GetOverHimWidget: Widget {
    let kind: String = "GetOverHimWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            GetOverHimWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Get Over Him")
        .description("Your daily reminder.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

#Preview(as: .systemSmall) {
    GetOverHimWidget()
} timeline: {
    SimpleEntry(date: .now)
}
