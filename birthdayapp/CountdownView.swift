//
//  CountdownView.swift
//  birthdayapp
//
//  Created by Preeti Dave on 4/12/26.
//

import SwiftUI
import SwiftData

struct CountdownView: View {
    @Query(sort: \Birthday.date) private var birthdays: [Birthday]
    @State private var selectedBirthday: Birthday?
    @State private var animateConfetti = false

    private var sortedByCountdown: [Birthday] {
        birthdays.sorted { $0.daysUntilBirthday < $1.daysUntilBirthday }
    }

    var body: some View {
        NavigationStack {
            Group {
                if birthdays.isEmpty {
                    emptyState
                } else {
                    countdownContent
                }
            }
            .navigationTitle("Countdown ⏳")
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Text("⏰")
                .font(.system(size: 80))
            Text("No Birthdays to Count Down")
                .font(.title2.bold())
            Text("Add birthdays in the Birthdays tab first")
                .foregroundStyle(.secondary)
        }
    }

    private var countdownContent: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Featured countdown (next upcoming)
                if let next = sortedByCountdown.first {
                    featuredCountdown(for: next)
                }

                // All countdowns
                if sortedByCountdown.count > 1 {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("All Countdowns")
                            .font(.headline)
                            .padding(.horizontal)

                        ForEach(sortedByCountdown) { birthday in
                            CountdownCard(birthday: birthday)
                                .padding(.horizontal)
                        }
                    }
                }
            }
            .padding(.vertical)
        }
    }

    private func featuredCountdown(for birthday: Birthday) -> some View {
        VStack(spacing: 16) {
            Text(birthday.emoji)
                .font(.system(size: 60))
                .scaleEffect(animateConfetti ? 1.1 : 1.0)
                .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: animateConfetti)

            Text(birthday.name)
                .font(.title.bold())

            if birthday.isBirthdayToday {
                Text("🎉 TODAY IS THE DAY! 🎉")
                    .font(.title2.bold())
                    .foregroundStyle(.pink)
            } else {
                HStack(spacing: 20) {
                    CountdownUnit(value: birthday.daysUntilBirthday / 30, label: "Months")
                    CountdownUnit(value: birthday.daysUntilBirthday % 30, label: "Days")
                }

                Text("until \(birthday.name)'s birthday")
                    .foregroundStyle(.secondary)
            }

            // Progress ring
            ZStack {
                Circle()
                    .stroke(Color.pink.opacity(0.2), lineWidth: 12)
                Circle()
                    .trim(from: 0, to: CGFloat(max(0, 365 - birthday.daysUntilBirthday)) / 365.0)
                    .stroke(
                        LinearGradient(colors: [.pink, .purple], startPoint: .topLeading, endPoint: .bottomTrailing),
                        style: StrokeStyle(lineWidth: 12, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))

                VStack {
                    Text("\(Int((Double(max(0, 365 - birthday.daysUntilBirthday)) / 365.0) * 100))%")
                        .font(.title.bold())
                        .foregroundStyle(.pink)
                    Text("of the year")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(width: 150, height: 150)
            .padding(.top, 8)
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(
                    LinearGradient(
                        colors: [.pink.opacity(0.05), .purple.opacity(0.05)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .padding(.horizontal)
        .onAppear { animateConfetti = true }
    }
}

// MARK: - Countdown Unit

struct CountdownUnit: View {
    let value: Int
    let label: String

    var body: some View {
        VStack(spacing: 4) {
            Text("\(value)")
                .font(.system(size: 48, weight: .bold, design: .rounded))
                .foregroundStyle(.pink)
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
        }
        .frame(width: 90)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemGray6))
        )
    }
}

// MARK: - Countdown Card

struct CountdownCard: View {
    let birthday: Birthday

    var body: some View {
        HStack(spacing: 14) {
            Text(birthday.emoji)
                .font(.system(size: 32))

            VStack(alignment: .leading, spacing: 2) {
                Text(birthday.name)
                    .font(.headline)
                Text(birthday.date, format: .dateTime.month(.abbreviated).day())
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if birthday.isBirthdayToday {
                Text("🎉 Today!")
                    .font(.subheadline.bold())
                    .foregroundStyle(.pink)
            } else {
                VStack(alignment: .trailing) {
                    Text("\(birthday.daysUntilBirthday)")
                        .font(.title2.bold())
                        .foregroundStyle(.pink)
                    Text("days")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemGray6))
        )
    }
}

#Preview {
    CountdownView()
        .modelContainer(for: [Birthday.self, PartyGuest.self, PartyTodo.self], inMemory: true)
}
