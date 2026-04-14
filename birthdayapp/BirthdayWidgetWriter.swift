//
//  BirthdayWidgetWriter.swift
//  birthdayapp
//

import Foundation
import WidgetKit

/// Pushes the next birthday into the shared App Group so the home screen widget can display it.
enum BirthdayWidgetWriter {
    static let suiteName = "group.Self.birthdayapp"
    static let widgetKind = "NextBirthdayWidget"

    static func update(from birthdays: [Birthday]) {
        guard let defaults = UserDefaults(suiteName: suiteName) else {
            WidgetCenter.shared.reloadTimelines(ofKind: widgetKind)
            return
        }

        let sorted = birthdays.sorted { $0.daysUntilBirthday < $1.daysUntilBirthday }
        if let next = sorted.first {
            defaults.set(next.name, forKey: "widget_name")
            defaults.set(next.daysUntilBirthday, forKey: "widget_days")
            defaults.set(next.emoji, forKey: "widget_emoji")
            defaults.set(next.isBirthdayToday, forKey: "widget_is_today")
        } else {
            defaults.set("", forKey: "widget_name")
            defaults.set(-1, forKey: "widget_days")
            defaults.set("🎂", forKey: "widget_emoji")
            defaults.set(false, forKey: "widget_is_today")
        }
        WidgetCenter.shared.reloadTimelines(ofKind: widgetKind)
    }
}
