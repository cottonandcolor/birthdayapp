//
//  BirthdayListView.swift
//  birthdayapp
//
//  Created by Preeti Dave on 4/12/26.
//

import MessageUI
import SwiftData
import SwiftUI
import UIKit
import UniformTypeIdentifiers

/// Holds in-progress “new birthday” fields in the list so they survive SwiftUI view recreation (e.g. sheet lifecycle).
struct AddBirthdayDraft {
    var name = ""
    var date = Date()
    var notes = ""
    var groupTag = ""
    var giftBudget: Double = 0
    var selectedEmoji = "🎂"
}

struct BirthdayListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Birthday.date) private var birthdays: [Birthday]
    @State private var showingAddSheet = false
    @State private var addBirthdayDraft = AddBirthdayDraft()
    @State private var searchText = ""
    @State private var tagFilter = ""
    @State private var showingReminderSettings = false
    @State private var showingExportShare = false
    @State private var exportFileURL: URL?
    @State private var showingImportPicker = false
    @State private var importAlertMessage: String?
    @State private var showingImportAlert = false
    @AppStorage(BirthdayNotificationScheduler.remindersPreferenceKey) private var remindersEnabled = true

    private var uniqueTags: [String] {
        let tags = birthdays.map { $0.groupTag.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
        return Array(Set(tags)).sorted()
    }

    private var sortedBirthdays: [Birthday] {
        let bySearch = searchText.isEmpty ? birthdays : birthdays.filter {
            $0.name.localizedCaseInsensitiveContains(searchText)
        }
        let filtered = tagFilter.isEmpty
            ? bySearch
            : bySearch.filter { $0.groupTag.trimmingCharacters(in: .whitespacesAndNewlines) == tagFilter }
        return filtered.sorted { $0.daysUntilBirthday < $1.daysUntilBirthday }
    }

    private var todayBirthdays: [Birthday] {
        sortedBirthdays.filter { $0.isBirthdayToday }
    }

    private var upcomingBirthdays: [Birthday] {
        sortedBirthdays.filter { !$0.isBirthdayToday }
    }

    var body: some View {
        NavigationStack {
            Group {
                if birthdays.isEmpty {
                    emptyState
                } else {
                    birthdayList
                }
            }
            .navigationTitle("Birthdays 🎂")
            .searchable(text: $searchText, prompt: "Search by name")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Menu {
                        Toggle("Birthday reminders", isOn: $remindersEnabled)
                        Button("Reminder times…") { showingReminderSettings = true }
                        if !uniqueTags.isEmpty {
                            Menu("Filter by group") {
                                Button("All groups") { tagFilter = "" }
                                ForEach(uniqueTags, id: \.self) { tag in
                                    Button(tag) { tagFilter = tag }
                                }
                            }
                        }
                        Button("Export birthdays (JSON)") { exportBirthdays() }
                        Button("Import birthdays (JSON)…") { showingImportPicker = true }
                    } label: {
                        Image(systemName: "bell.badge")
                            .font(.title3)
                    }
                    .accessibilityLabel("Reminders and data options")
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        addBirthdayDraft = AddBirthdayDraft()
                        showingAddSheet = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                    }
                }
            }
            .onChange(of: remindersEnabled) { _, _ in
                Task {
                    await BirthdayNotificationScheduler.rescheduleAll(birthdays: birthdays)
                }
            }
            .sheet(isPresented: $showingAddSheet) {
                AddBirthdayView(draft: $addBirthdayDraft)
            }
            .sheet(isPresented: $showingReminderSettings) {
                ReminderSettingsView()
            }
            .sheet(isPresented: $showingExportShare) {
                if let exportFileURL {
                    ActivityView(items: [exportFileURL])
                }
            }
            .fileImporter(
                isPresented: $showingImportPicker,
                allowedContentTypes: [.json],
                allowsMultipleSelection: false
            ) { result in
                switch result {
                case .success(let urls):
                    guard let url = urls.first else { return }
                    let got = url.startAccessingSecurityScopedResource()
                    defer {
                        if got { url.stopAccessingSecurityScopedResource() }
                    }
                    do {
                        let data = try Data(contentsOf: url)
                        try BirthdayJSONBackup.importData(data, into: modelContext)
                        importAlertMessage = "Imported birthdays from file."
                        Task {
                            await BirthdayNotificationScheduler.rescheduleAll(birthdays: birthdays)
                        }
                    } catch {
                        importAlertMessage = "Could not import: \(error.localizedDescription)"
                    }
                    showingImportAlert = true
                case .failure(let error):
                    importAlertMessage = error.localizedDescription
                    showingImportAlert = true
                }
            }
            .alert("Import", isPresented: $showingImportAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(importAlertMessage ?? "")
            }
        }
    }

    private func exportBirthdays() {
        do {
            let data = try BirthdayJSONBackup.exportData(from: birthdays)
            let url = FileManager.default.temporaryDirectory.appendingPathComponent("birthdays-export.json")
            try data.write(to: url, options: .atomic)
            exportFileURL = url
            showingExportShare = true
        } catch {
            importAlertMessage = "Export failed: \(error.localizedDescription)"
            showingImportAlert = true
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Text("🎈")
                .font(.system(size: 80))
            Text("No Birthdays Yet")
                .font(.title2.bold())
            Text("Tap + to add your first birthday")
                .foregroundStyle(.secondary)
            Button("Add Birthday") {
                addBirthdayDraft = AddBirthdayDraft()
                showingAddSheet = true
            }
            .buttonStyle(.borderedProminent)
            .tint(.pink)
        }
        .padding()
    }

    private var birthdayList: some View {
        List {
            if !todayBirthdays.isEmpty {
                Section("🎉 Today!") {
                    ForEach(todayBirthdays) { birthday in
                        BirthdayRow(birthday: birthday, isToday: true)
                    }
                }
            }

            if !upcomingBirthdays.isEmpty {
                Section("Upcoming") {
                    ForEach(upcomingBirthdays) { birthday in
                        BirthdayRow(birthday: birthday, isToday: false)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
    }
}

// MARK: - Birthday Row

struct BirthdayRow: View {
    let birthday: Birthday
    let isToday: Bool
    @State private var showingDetail = false

    var body: some View {
        Button {
            showingDetail = true
        } label: {
            HStack(spacing: 14) {
                Text(birthday.emoji)
                    .font(.system(size: 36))
                    .frame(width: 50, height: 50)
                    .background(
                        Circle()
                            .fill(isToday ? Color.pink.opacity(0.2) : Color.gray.opacity(0.1))
                    )

                VStack(alignment: .leading, spacing: 4) {
                    Text(birthday.name)
                        .font(.headline)
                        .foregroundStyle(.primary)
                    Text(birthday.date, format: .dateTime.month(.wide).day())
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    if !birthday.groupTag.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        Text(birthday.groupTag)
                            .font(.caption2)
                            .foregroundStyle(.pink)
                    }
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    if isToday {
                        Text("TODAY!")
                            .font(.caption.bold())
                            .foregroundStyle(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Capsule().fill(.pink))
                    } else {
                        Text("\(birthday.daysUntilBirthday)")
                            .font(.title3.bold())
                            .foregroundStyle(.pink)
                        Text("days")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(.vertical, 4)
        }
        .sheet(isPresented: $showingDetail) {
            BirthdayDetailView(birthday: birthday)
        }
    }
}

// MARK: - Add Birthday View

struct AddBirthdayView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @Binding var draft: AddBirthdayDraft

    @StateObject private var voiceCapture = VoiceBirthdayCapture()

    var body: some View {
        NavigationStack {
            Form {
                Section("Add with voice") {
                    Text("Say a name (e.g. “add Sonia” or “Alex on July fourth”). Tap Stop to fill the form, then Save.")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    HStack(spacing: 16) {
                        Button {
                            Task {
                                if voiceCapture.isRecording {
                                    await voiceCapture.stopRecordingAndFinalizeTranscript()
                                    applyVoiceTranscript()
                                } else {
                                    await voiceCapture.startRecording()
                                }
                            }
                        } label: {
                            Label(
                                voiceCapture.isRecording ? "Stop" : "Speak",
                                systemImage: voiceCapture.isRecording ? "stop.circle.fill" : "mic.circle.fill"
                            )
                        }
                        .tint(voiceCapture.isRecording ? .red : .pink)
                        .accessibilityLabel(voiceCapture.isRecording ? "Stop recording" : "Start voice entry")

                        if !voiceCapture.transcript.isEmpty {
                            Button("Apply text") {
                                applyVoiceTranscript()
                            }
                            .font(.subheadline.weight(.semibold))
                        }
                    }

                    if !voiceCapture.transcript.isEmpty {
                        Text(voiceCapture.transcript)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    if let err = voiceCapture.errorMessage {
                        Text(err)
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                }

                Section("Who's Birthday?") {
                    TextField("Name", text: $draft.name)
                        .font(.title3)

                    DatePicker("Birthday", selection: $draft.date, displayedComponents: .date)
                }

                Section("Pick an Emoji") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 12) {
                        ForEach(BirthdayEmojiPalette.options, id: \.self) { emoji in
                            Text(emoji)
                                .font(.system(size: 32))
                                .padding(6)
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(draft.selectedEmoji == emoji ? Color.pink.opacity(0.2) : Color.clear)
                                )
                                .accessibilityLabel("Emoji \(emoji)")
                                .onTapGesture {
                                    draft.selectedEmoji = emoji
                                }
                        }
                    }
                    .padding(.vertical, 4)
                }

                Section("Group tag") {
                    TextField("e.g. Family, Work", text: $draft.groupTag)
                }

                Section("Gift budget") {
                    TextField("Amount (optional)", value: $draft.giftBudget, format: .number)
                        .keyboardType(.decimalPad)
                }

                Section("Notes (Optional)") {
                    TextField("Gift ideas, preferences...", text: $draft.notes, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle("New Birthday")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let birthday = Birthday(
                            name: draft.name,
                            date: draft.date,
                            notes: draft.notes,
                            emoji: draft.selectedEmoji,
                            groupTag: draft.groupTag,
                            giftBudget: draft.giftBudget
                        )
                        modelContext.insert(birthday)
                        try? modelContext.save()
                        Task {
                            _ = await BirthdayNotificationScheduler.requestAuthorizationIfNeeded()
                            await BirthdayNotificationScheduler.schedule(for: birthday)
                        }
                        dismiss()
                    }
                    .disabled(draft.name.trimmingCharacters(in: .whitespaces).isEmpty)
                    .bold()
                }
            }
        }
    }

    private func applyVoiceTranscript() {
        let p = BirthdaySpeechParser.parseVoiceFields(voiceCapture.transcript)
        if let parsedName = p.name {
            draft.name = parsedName
        }
        if let parsedDate = p.date {
            draft.date = parsedDate
        }
        if let tag = p.groupTag {
            draft.groupTag = tag
        }
        if let budget = p.giftBudget {
            draft.giftBudget = budget
        }
        if let note = p.notes {
            draft.notes = note
        }
    }
}

// MARK: - Birthday Detail View

struct BirthdayDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Bindable var birthday: Birthday

    @State private var showingEdit = false
    @State private var showingMessageComposer = false
    @State private var calendarBanner: String?

    private var birthdayWishText: String {
        "Happy birthday, \(birthday.name)! Hope you have an amazing day."
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    VStack(spacing: 12) {
                        Text(birthday.emoji)
                            .font(.system(size: 80))
                            .accessibilityHidden(true)
                        Text(birthday.name)
                            .font(.largeTitle.bold())
                        Text(birthday.date, format: .dateTime.month(.wide).day().year())
                            .foregroundStyle(.secondary)
                        Text("Turning \(birthday.nextAgeToTurn)")
                            .font(.title3)
                            .foregroundStyle(.pink)
                        Text("Western zodiac: \(birthday.zodiacSign)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        if let milestone = birthday.milestoneMessage {
                            Text(milestone)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.pink)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                        if !birthday.groupTag.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            Text(birthday.groupTag)
                                .font(.caption)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(Capsule().fill(Color.pink.opacity(0.15)))
                        }
                        if let budget = birthday.formattedGiftBudget {
                            Text("Gift budget: \(budget)")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.top, 20)

                    VStack(spacing: 8) {
                        if birthday.isBirthdayToday {
                            Text("🎉 Happy Birthday! 🎉")
                                .font(.title2.bold())
                                .foregroundStyle(.pink)
                        } else {
                            Text("\(birthday.daysUntilBirthday)")
                                .font(.system(size: 60, weight: .bold, design: .rounded))
                                .foregroundStyle(.pink)
                            Text("days until their birthday")
                                .foregroundStyle(.secondary)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 24)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(.pink.opacity(0.08))
                    )
                    .padding(.horizontal)

                    VStack(spacing: 12) {
                        ShareLink(item: birthdayWishText, subject: Text("Happy Birthday")) {
                            Label("Share birthday wish", systemImage: "square.and.arrow.up")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.pink)

                        if MFMessageComposeViewController.canSendText() {
                            Button {
                                showingMessageComposer = true
                            } label: {
                                Label("Send as text", systemImage: "message.fill")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.bordered)
                        }

                        Button {
                            Task {
                                let ok = await BirthdayCalendarExporter.addYearlyBirthdayEvent(for: birthday)
                                calendarBanner = ok ? "Added to your default calendar." : "Calendar access denied or save failed."
                            }
                        } label: {
                            Label("Add yearly event to Calendar", systemImage: "calendar.badge.plus")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                    }
                    .padding(.horizontal)

                    if let calendarBanner {
                        Text(calendarBanner)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }

                    if !birthday.notes.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Notes")
                                .font(.headline)
                            Text(birthday.notes)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color(.systemGray6))
                        )
                        .padding(.horizontal)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                if birthday.isBirthdayToday {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                }
            }
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button("Edit") { showingEdit = true }
                }
                ToolbarItem(placement: .destructiveAction) {
                    Button(role: .destructive) {
                        BirthdayNotificationScheduler.cancel(for: birthday)
                        modelContext.delete(birthday)
                        dismiss()
                    } label: {
                        Image(systemName: "trash")
                    }
                }
            }
            .sheet(isPresented: $showingEdit) {
                EditBirthdayView(birthday: birthday)
            }
            .sheet(isPresented: $showingMessageComposer) {
                MessageComposeView(isPresented: $showingMessageComposer, body: birthdayWishText)
            }
        }
    }
}

#Preview {
    BirthdayListView()
        .modelContainer(for: [Birthday.self, PartyGuest.self, PartyTodo.self], inMemory: true)
}
