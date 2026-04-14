//
//  ReminderSettingsView.swift
//  birthdayapp
//

import SwiftData
import SwiftUI

struct ReminderSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Birthday.date) private var birthdays: [Birthday]

    @AppStorage(BirthdayNotificationScheduler.morningHourKey) private var morningHour = 9
    @AppStorage(BirthdayNotificationScheduler.eveHourKey) private var eveHour = 18
    @AppStorage(BirthdayNotificationScheduler.weekBeforeEnabledKey) private var weekBeforeEnabled = true
    @AppStorage(BirthdayNotificationScheduler.weekBeforeHourKey) private var weekBeforeHour = 10

    var body: some View {
        NavigationStack {
            Form {
                Section("Day-of birthday") {
                    Picker("Notification hour", selection: $morningHour) {
                        ForEach(0 ..< 24, id: \.self) { h in
                            Text(formattedHour(h)).tag(h)
                        }
                    }
                }

                Section("Day before") {
                    Picker("Notification hour", selection: $eveHour) {
                        ForEach(0 ..< 24, id: \.self) { h in
                            Text(formattedHour(h)).tag(h)
                        }
                    }
                }

                Section("One week before") {
                    Toggle("Enabled", isOn: $weekBeforeEnabled)
                    if weekBeforeEnabled {
                        Picker("Notification hour", selection: $weekBeforeHour) {
                            ForEach(0 ..< 24, id: \.self) { h in
                                Text(formattedHour(h)).tag(h)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Reminder times")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        Task {
                            await BirthdayNotificationScheduler.rescheduleAll(birthdays: birthdays)
                        }
                        dismiss()
                    }
                }
            }
            .onChange(of: morningHour) { _, _ in
                Task { await BirthdayNotificationScheduler.rescheduleAll(birthdays: birthdays) }
            }
            .onChange(of: eveHour) { _, _ in
                Task { await BirthdayNotificationScheduler.rescheduleAll(birthdays: birthdays) }
            }
            .onChange(of: weekBeforeEnabled) { _, _ in
                Task { await BirthdayNotificationScheduler.rescheduleAll(birthdays: birthdays) }
            }
            .onChange(of: weekBeforeHour) { _, _ in
                Task { await BirthdayNotificationScheduler.rescheduleAll(birthdays: birthdays) }
            }
        }
    }

    private func formattedHour(_ h: Int) -> String {
        var c = DateComponents()
        c.hour = h
        c.minute = 0
        let cal = Calendar.current
        let date = cal.date(from: c) ?? Date()
        let f = DateFormatter()
        f.dateStyle = .none
        f.timeStyle = .short
        return f.string(from: date)
    }
}
