//
//  EditBirthdayView.swift
//  birthdayapp
//

import SwiftData
import SwiftUI

struct EditBirthdayView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @Bindable var birthday: Birthday

    @StateObject private var voiceCapture = VoiceBirthdayCapture()

    var body: some View {
        NavigationStack {
            Form {
                Section("Add with voice") {
                    Text("Speak to update fields, then tap Stop or Apply text.")
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
                    TextField("Name", text: $birthday.name)
                        .font(.title3)

                    DatePicker("Birthday", selection: $birthday.date, displayedComponents: .date)
                }

                Section("Pick an Emoji") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 12) {
                        ForEach(BirthdayEmojiPalette.options, id: \.self) { emoji in
                            Text(emoji)
                                .font(.system(size: 32))
                                .padding(6)
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(birthday.emoji == emoji ? Color.pink.opacity(0.2) : Color.clear)
                                )
                                .accessibilityLabel("Emoji \(emoji)")
                                .onTapGesture {
                                    birthday.emoji = emoji
                                }
                        }
                    }
                    .padding(.vertical, 4)
                }

                Section("Group tag") {
                    TextField("e.g. Family, Work", text: $birthday.groupTag)
                }

                Section("Gift budget") {
                    TextField("Amount (optional)", value: $birthday.giftBudget, format: .number)
                        .keyboardType(.decimalPad)
                }

                Section("Notes") {
                    TextField("Gift ideas, preferences...", text: $birthday.notes, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle("Edit Birthday")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        try? modelContext.save()
                        Task {
                            _ = await BirthdayNotificationScheduler.requestAuthorizationIfNeeded()
                            await BirthdayNotificationScheduler.schedule(for: birthday)
                        }
                        dismiss()
                    }
                    .disabled(birthday.name.trimmingCharacters(in: .whitespaces).isEmpty)
                    .bold()
                }
            }
        }
    }

    private func applyVoiceTranscript() {
        let p = BirthdaySpeechParser.parseVoiceFields(voiceCapture.transcript)
        if let parsedName = p.name {
            birthday.name = parsedName
        }
        if let parsedDate = p.date {
            birthday.date = parsedDate
        }
        if let tag = p.groupTag {
            birthday.groupTag = tag
        }
        if let budget = p.giftBudget {
            birthday.giftBudget = budget
        }
        if let note = p.notes {
            birthday.notes = note
        }
    }
}
