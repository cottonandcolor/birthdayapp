//
//  BirthdayNotificationScheduler.swift
//  birthdayapp
//

import Foundation
import SwiftData
import UserNotifications

enum BirthdayNotificationScheduler {
    /// Matches `@AppStorage` in `BirthdayListView`.
    static let remindersPreferenceKey = "birthdayRemindersEnabled"
    static let morningHourKey = "birthdayReminderMorningHour"
    static let eveHourKey = "birthdayReminderEveHour"
    static let weekBeforeEnabledKey = "birthdayReminderWeekBeforeEnabled"
    static let weekBeforeHourKey = "birthdayReminderWeekBeforeHour"

    private static var remindersOn: Bool {
        if UserDefaults.standard.object(forKey: remindersPreferenceKey) == nil { return true }
        return UserDefaults.standard.bool(forKey: remindersPreferenceKey)
    }

    private static var morningHour: Int {
        let d = UserDefaults.standard
        if d.object(forKey: morningHourKey) == nil { return 9 }
        let v = d.integer(forKey: morningHourKey)
        return (0 ... 23).contains(v) ? v : 9
    }

    private static var eveHour: Int {
        let d = UserDefaults.standard
        if d.object(forKey: eveHourKey) == nil { return 18 }
        let v = d.integer(forKey: eveHourKey)
        return (0 ... 23).contains(v) ? v : 18
    }

    private static var weekBeforeOn: Bool {
        if UserDefaults.standard.object(forKey: weekBeforeEnabledKey) == nil { return true }
        return UserDefaults.standard.bool(forKey: weekBeforeEnabledKey)
    }

    private static var weekBeforeHour: Int {
        let d = UserDefaults.standard
        if d.object(forKey: weekBeforeHourKey) == nil { return 10 }
        let v = d.integer(forKey: weekBeforeHourKey)
        return (0 ... 23).contains(v) ? v : 10
    }

    static func requestAuthorizationIfNeeded() async -> Bool {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        switch settings.authorizationStatus {
        case .authorized, .provisional, .ephemeral:
            return true
        case .notDetermined:
            do {
                return try await center.requestAuthorization(options: [.alert, .sound, .badge])
            } catch {
                return false
            }
        default:
            return false
        }
    }

    static func rescheduleAll(birthdays: [Birthday]) async {
        guard remindersOn else {
            await cancelAllScheduledBirthdayNotifications()
            return
        }
        await cancelAllScheduledBirthdayNotifications()
        for birthday in birthdays {
            await schedule(for: birthday)
        }
    }

    static func cancel(for birthday: Birthday) {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [
            identifierDay(for: birthday),
            identifierEve(for: birthday),
            identifierWeek(for: birthday),
        ])
    }

    private static func cancelAllScheduledBirthdayNotifications() async {
        let center = UNUserNotificationCenter.current()
        let pending = await center.pendingNotificationRequests()
        let ids = pending.map(\.identifier).filter { $0.hasPrefix("birthday.") }
        center.removePendingNotificationRequests(withIdentifiers: ids)
    }

    static func schedule(for birthday: Birthday) async {
        guard remindersOn else { return }
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        guard settings.authorizationStatus == .authorized
            || settings.authorizationStatus == .provisional
            || settings.authorizationStatus == .ephemeral
        else { return }

        cancel(for: birthday)

        let calendar = Calendar.current
        let month = calendar.component(.month, from: birthday.date)
        let day = calendar.component(.day, from: birthday.date)

        // Morning of birthday (repeats yearly)
        var morning = DateComponents()
        morning.month = month
        morning.day = day
        morning.hour = morningHour
        morning.minute = 0
        let dayTrigger = UNCalendarNotificationTrigger(dateMatching: morning, repeats: true)
        let dayContent = UNMutableNotificationContent()
        dayContent.title = "Birthday today!"
        dayContent.body = "It's \(birthday.name)'s birthday — time to celebrate."
        dayContent.sound = .default
        let dayRequest = UNNotificationRequest(
            identifier: identifierDay(for: birthday),
            content: dayContent,
            trigger: dayTrigger
        )
        try? await UNUserNotificationCenter.current().add(dayRequest)

        // Evening before (repeats yearly)
        if let eveComponents = offsetMonthDay(fromBirthMonth: month, day: day, calendar: calendar, dayOffset: -1) {
            var eve = DateComponents()
            eve.month = eveComponents.month
            eve.day = eveComponents.day
            eve.hour = eveHour
            eve.minute = 0
            let eveTrigger = UNCalendarNotificationTrigger(dateMatching: eve, repeats: true)
            let eveContent = UNMutableNotificationContent()
            eveContent.title = "Birthday tomorrow"
            eveContent.body = "Reminder: \(birthday.name)'s birthday is tomorrow."
            eveContent.sound = .default
            let eveRequest = UNNotificationRequest(
                identifier: identifierEve(for: birthday),
                content: eveContent,
                trigger: eveTrigger
            )
            try? await UNUserNotificationCenter.current().add(eveRequest)
        }

        // One week before (repeats yearly)
        if weekBeforeOn,
           let weekComponents = offsetMonthDay(fromBirthMonth: month, day: day, calendar: calendar, dayOffset: -7)
        {
            var week = DateComponents()
            week.month = weekComponents.month
            week.day = weekComponents.day
            week.hour = weekBeforeHour
            week.minute = 0
            let weekTrigger = UNCalendarNotificationTrigger(dateMatching: week, repeats: true)
            let weekContent = UNMutableNotificationContent()
            weekContent.title = "Birthday next week"
            weekContent.body = "\(birthday.name)'s birthday is in one week."
            weekContent.sound = .default
            let weekRequest = UNNotificationRequest(
                identifier: identifierWeek(for: birthday),
                content: weekContent,
                trigger: weekTrigger
            )
            try? await UNUserNotificationCenter.current().add(weekRequest)
        }
    }

    private static func offsetMonthDay(fromBirthMonth month: Int, day: Int, calendar: Calendar, dayOffset: Int) -> (month: Int, day: Int)? {
        var comps = DateComponents()
        comps.year = 2024
        comps.month = month
        comps.day = day
        guard let bday = calendar.date(from: comps),
              let shifted = calendar.date(byAdding: .day, value: dayOffset, to: bday)
        else { return nil }
        let m = calendar.component(.month, from: shifted)
        let d = calendar.component(.day, from: shifted)
        return (m, d)
    }

    private static func identifierDay(for birthday: Birthday) -> String {
        "birthday.day.\(stableId(birthday))"
    }

    private static func identifierEve(for birthday: Birthday) -> String {
        "birthday.eve.\(stableId(birthday))"
    }

    private static func identifierWeek(for birthday: Birthday) -> String {
        "birthday.week.\(stableId(birthday))"
    }

    static func stableId(_ birthday: Birthday) -> String {
        let pid = birthday.persistentModelID
        func sanitize(_ raw: String) -> String {
            raw
                .replacingOccurrences(of: "/", with: "_")
                .replacingOccurrences(of: ":", with: "_")
        }
        let fromId = sanitize(String(describing: pid.id))
        if !fromId.isEmpty { return fromId }
        let fromPID = sanitize(String(describing: pid))
        if !fromPID.isEmpty { return fromPID }
        if let data = try? JSONEncoder().encode(pid) {
            return data.base64EncodedString()
                .replacingOccurrences(of: "+", with: "-")
                .replacingOccurrences(of: "/", with: "_")
                .replacingOccurrences(of: "=", with: "")
        }
        return "fallback"
    }
}
