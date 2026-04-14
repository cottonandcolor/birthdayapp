//
//  OnboardingView.swift
//  birthdayapp
//

import SwiftUI

struct OnboardingView: View {
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Welcome")
                        .font(.largeTitle.bold())

                    featureRow(icon: "gift.fill", title: "Birthdays", text: "Track people, notes, groups, and gift budgets.")
                    featureRow(icon: "bell.badge", title: "Reminders", text: "Get notified the day before, a week ahead, and on the day.")
                    featureRow(icon: "mic.fill", title: "Voice", text: "Add birthdays by speaking a name and date.")
                    featureRow(icon: "icloud", title: "iCloud", text: "Your data can sync across devices when iCloud is enabled.")

                    Text("Allow notifications, calendar, and microphone when prompted so everything works.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    Button {
                        finishOnboarding()
                    } label: {
                        Text("Get started")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.pink)
                    .padding(.top, 8)
                }
                .padding()
            }
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Get started") {
                        finishOnboarding()
                    }
                    .bold()
                }
            }
        }
    }

    private func finishOnboarding() {
        hasSeenOnboarding = true
        dismiss()
    }

    private func featureRow(icon: String, title: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(.pink)
                .frame(width: 36)
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                Text(text)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
