//
//  BirthdayCalendarExporter.swift
//  birthdayapp
//

import EventKit
import Foundation

enum BirthdayCalendarExporter {
    static func requestAccess() async -> Bool {
        let store = EKEventStore()
        do {
            return try await store.requestFullAccessToEvents()
        } catch {
            return false
        }
    }

    /// Adds a yearly all-day birthday event. Returns false if access denied or save failed.
    @discardableResult
    static func addYearlyBirthdayEvent(for birthday: Birthday) async -> Bool {
        guard await requestAccess() else { return false }
        let store = EKEventStore()
        let event = EKEvent(eventStore: store)
        event.title = "\(birthday.name)'s Birthday"
        event.calendar = store.defaultCalendarForNewEvents
        event.isAllDay = true
        event.notes = "From Birthday App"

        let cal = Calendar.current
        var comps = DateComponents()
        comps.month = cal.component(.month, from: birthday.date)
        comps.day = cal.component(.day, from: birthday.date)
        comps.year = cal.component(.year, from: Date())
        guard let start = cal.date(from: comps) else { return false }
        event.startDate = start
        event.endDate = start

        let rule = EKRecurrenceRule(
            recurrenceWith: .yearly,
            interval: 1,
            end: nil
        )
        event.addRecurrenceRule(rule)

        do {
            try store.save(event, span: .futureEvents)
            return true
        } catch {
            return false
        }
    }
}
