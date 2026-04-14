//
//  BirthdayWidget.swift
//  BirthdayWidgetExtension
//

import SwiftUI
import WidgetKit

private let suiteName = "group.Self.birthdayapp"

struct BirthdayEntry: TimelineEntry {
    let date: Date
    let name: String
    let days: Int
    let emoji: String
    let isToday: Bool

    static func load() -> BirthdayEntry {
        let now = Date()
        guard let d = UserDefaults(suiteName: suiteName) else {
            return BirthdayEntry(date: now, name: "", days: -1, emoji: "🎂", isToday: false)
        }
        let name = d.string(forKey: "widget_name") ?? ""
        let days = d.object(forKey: "widget_days") as? Int ?? -1
        let emoji = d.string(forKey: "widget_emoji") ?? "🎂"
        let isToday = d.bool(forKey: "widget_is_today")
        return BirthdayEntry(date: now, name: name, days: days, emoji: emoji, isToday: isToday)
    }
}

struct BirthdayWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> BirthdayEntry {
        BirthdayEntry(date: .now, name: "Alex", days: 5, emoji: "🎂", isToday: false)
    }

    func getSnapshot(in context: Context, completion: @escaping (BirthdayEntry) -> Void) {
        completion(BirthdayEntry.load())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<BirthdayEntry>) -> Void) {
        let entry = BirthdayEntry.load()
        let startOfToday = Calendar.current.startOfDay(for: Date())
        let nextRefresh = Calendar.current.date(byAdding: .day, value: 1, to: startOfToday) ?? Date().addingTimeInterval(86_400)
        completion(Timeline(entries: [entry], policy: .after(nextRefresh)))
    }
}

struct BirthdayWidgetEntryView: View {
    @Environment(\.widgetFamily) private var family
    var entry: BirthdayEntry

    var body: some View {
        VStack(spacing: family == .systemSmall ? 4 : 8) {
            Text(entry.emoji)
                .font(family == .systemSmall ? .largeTitle : .system(size: 44))

            if entry.name.isEmpty || entry.days < 0 {
                Text("Birthdays")
                    .font(.headline.weight(.semibold))
                Text("Open the app to add people")
                    .font(.caption2)
                    .multilineTextAlignment(.center)
            } else if entry.isToday {
                Text("Today!")
                    .font(.title2.bold())
                Text(entry.name)
                    .font(.subheadline.weight(.semibold))
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.75)
            } else {
                Text("\(entry.days)")
                    .font(.system(size: family == .systemSmall ? 36 : 44, weight: .bold, design: .rounded))
                Text("days until")
                    .font(.caption.weight(.medium))
                Text(entry.name)
                    .font(.subheadline.weight(.semibold))
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.7)
            }
        }
        .foregroundStyle(.white)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(8)
    }
}

private let birthdayWidgetBackdrop = LinearGradient(
    colors: [
        Color(red: 1, green: 0.35, blue: 0.55),
        Color(red: 0.55, green: 0.2, blue: 0.45),
    ],
    startPoint: .topLeading,
    endPoint: .bottomTrailing
)

struct NextBirthdayWidget: Widget {
    let kind = "NextBirthdayWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: BirthdayWidgetProvider()) { entry in
            BirthdayWidgetEntryView(entry: entry)
                .containerBackground(birthdayWidgetBackdrop, for: .widget)
        }
        .configurationDisplayName("Birthdays")
        .description("Shows the next birthday on your list.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

@main
struct BirthdayWidgetBundle: WidgetBundle {
    var body: some Widget {
        NextBirthdayWidget()
    }
}
