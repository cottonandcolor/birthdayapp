//
//  PartyPlannerView.swift
//  birthdayapp
//
//  Created by Preeti Dave on 4/12/26.
//

import SwiftUI
import SwiftData

struct PartyPlannerView: View {
    @Query(sort: \Birthday.date) private var birthdays: [Birthday]
    @State private var selectedBirthday: Birthday?

    private var partiedBirthdays: [Birthday] {
        birthdays.filter { $0.hasParty }
    }

    var body: some View {
        NavigationStack {
            Group {
                if birthdays.isEmpty {
                    emptyState
                } else if let birthday = selectedBirthday {
                    PartyDetailView(birthday: birthday)
                } else {
                    partyList
                }
            }
            .navigationTitle("Party Planner 🎊")
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Text("🎊")
                .font(.system(size: 80))
            Text("No Birthdays Yet")
                .font(.title2.bold())
            Text("Add birthdays first to plan parties")
                .foregroundStyle(.secondary)
        }
    }

    private var partyList: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Existing parties
                if !partiedBirthdays.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Active Parties")
                            .font(.headline)
                            .padding(.horizontal)

                        ForEach(partiedBirthdays.sorted { $0.daysUntilBirthday < $1.daysUntilBirthday }) { birthday in
                            PartyCard(birthday: birthday) {
                                selectedBirthday = birthday
                            }
                            .padding(.horizontal)
                        }
                    }
                    .padding(.top)
                }

                // Start new party
                VStack(alignment: .leading, spacing: 12) {
                    Text(partiedBirthdays.isEmpty ? "Start Planning a Party!" : "Plan Another Party")
                        .font(.headline)
                        .padding(.horizontal)

                    ForEach(birthdays.filter { !$0.hasParty }.sorted { $0.daysUntilBirthday < $1.daysUntilBirthday }) { birthday in
                        Button {
                            birthday.hasParty = true
                            PartyTemplateSeeder.seedIfNeeded(birthday: birthday)
                            selectedBirthday = birthday
                        } label: {
                            HStack(spacing: 14) {
                                Text(birthday.emoji)
                                    .font(.system(size: 32))
                                VStack(alignment: .leading) {
                                    Text(birthday.name)
                                        .font(.headline)
                                    Text("\(birthday.daysUntilBirthday) days away")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                Text("Plan Party")
                                    .font(.subheadline.bold())
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(Capsule().fill(.pink))
                            }
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color(.systemGray6))
                            )
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal)
                    }
                }
                .padding(.top, partiedBirthdays.isEmpty ? 20 : 0)
            }
        }
    }
}

// MARK: - Party Card

struct PartyCard: View {
    let birthday: Birthday
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text(birthday.emoji)
                        .font(.system(size: 32))
                    VStack(alignment: .leading) {
                        Text("\(birthday.name)'s Party")
                            .font(.headline)
                        Text("\(birthday.daysUntilBirthday) days away")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundStyle(.secondary)
                }

                HStack(spacing: 16) {
                    Label("\(birthday.partyGuests.count) guests", systemImage: "person.2.fill")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    let completedTodos = birthday.partyTodos.filter { $0.isCompleted }.count
                    Label("\(completedTodos)/\(birthday.partyTodos.count) tasks", systemImage: "checklist")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(colors: [.pink.opacity(0.08), .purple.opacity(0.08)],
                                       startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Party Detail View

struct PartyDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var birthday: Birthday

    @State private var newGuestName = ""
    @State private var newTodoTitle = ""

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 8) {
                    Text(birthday.emoji)
                        .font(.system(size: 50))
                    Text("\(birthday.name)'s Party")
                        .font(.title2.bold())
                    Text("\(birthday.daysUntilBirthday) days to go!")
                        .foregroundStyle(.secondary)
                }
                .padding(.top)

                // Guest List
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Guest List")
                            .font(.headline)
                        Spacer()
                        Text("\(birthday.partyGuests.filter { $0.rsvpStatus == "accepted" }.count) confirmed")
                            .font(.caption)
                            .foregroundStyle(.green)
                    }

                    // Add guest
                    HStack {
                        TextField("Add guest name", text: $newGuestName)
                            .textFieldStyle(.roundedBorder)
                        Button {
                            guard !newGuestName.trimmingCharacters(in: .whitespaces).isEmpty else { return }
                            let guest = PartyGuest(name: newGuestName)
                            birthday.partyGuests.append(guest)
                            newGuestName = ""
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .font(.title3)
                                .foregroundStyle(.pink)
                        }
                    }

                    ForEach(birthday.partyGuests) { guest in
                        GuestRow(guest: guest) {
                            if let index = birthday.partyGuests.firstIndex(where: { $0.id == guest.id }) {
                                let removed = birthday.partyGuests.remove(at: index)
                                modelContext.delete(removed)
                            }
                        }
                    }

                    if birthday.partyGuests.isEmpty {
                        Text("No guests added yet")
                            .foregroundStyle(.secondary)
                            .font(.subheadline)
                            .padding(.vertical, 4)
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color(.systemGray6))
                )
                .padding(.horizontal)

                // Todo List
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("To-Do List")
                            .font(.headline)
                        Spacer()
                        let completed = birthday.partyTodos.filter { $0.isCompleted }.count
                        Text("\(completed)/\(birthday.partyTodos.count) done")
                            .font(.caption)
                            .foregroundStyle(.green)
                    }

                    // Add todo
                    HStack {
                        TextField("Add a task", text: $newTodoTitle)
                            .textFieldStyle(.roundedBorder)
                        Button {
                            guard !newTodoTitle.trimmingCharacters(in: .whitespaces).isEmpty else { return }
                            let todo = PartyTodo(title: newTodoTitle)
                            birthday.partyTodos.append(todo)
                            newTodoTitle = ""
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .font(.title3)
                                .foregroundStyle(.pink)
                        }
                    }

                    ForEach(birthday.partyTodos) { todo in
                        TodoRow(todo: todo) {
                            if let index = birthday.partyTodos.firstIndex(where: { $0.id == todo.id }) {
                                let removed = birthday.partyTodos.remove(at: index)
                                modelContext.delete(removed)
                            }
                        }
                    }

                    if birthday.partyTodos.isEmpty {
                        Text("No tasks added yet")
                            .foregroundStyle(.secondary)
                            .font(.subheadline)
                            .padding(.vertical, 4)
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color(.systemGray6))
                )
                .padding(.horizontal)

                // Quick add suggestions
                VStack(alignment: .leading, spacing: 12) {
                    Text("Quick Add Tasks")
                        .font(.headline)

                    let suggestions = ["Buy cake 🎂", "Send invitations 💌", "Get decorations 🎈", "Order food 🍕", "Plan games 🎮", "Buy party favors 🎁"]

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                        ForEach(suggestions, id: \.self) { suggestion in
                            Button {
                                let todo = PartyTodo(title: suggestion)
                                birthday.partyTodos.append(todo)
                            } label: {
                                Text(suggestion)
                                    .font(.subheadline)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 10)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(.pink.opacity(0.1))
                                    )
                                    .foregroundStyle(.pink)
                            }
                        }
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color(.systemGray6))
                )
                .padding(.horizontal)
            }
            .padding(.bottom, 20)
        }
        .onAppear {
            PartyTemplateSeeder.seedIfNeeded(birthday: birthday)
        }
    }
}

// MARK: - Guest Row

struct GuestRow: View {
    @Bindable var guest: PartyGuest
    let onDelete: () -> Void

    var body: some View {
        HStack {
            Text(guest.rsvpEmoji)
            Text(guest.name)
                .font(.subheadline)

            Spacer()

            Menu {
                Button("✅ Accepted") { guest.rsvpStatus = "accepted" }
                Button("❌ Declined") { guest.rsvpStatus = "declined" }
                Button("⏳ Pending") { guest.rsvpStatus = "pending" }
                Divider()
                Button("Remove", role: .destructive, action: onDelete)
            } label: {
                Text(guest.rsvpStatus.capitalized)
                    .font(.caption)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(
                        Capsule().fill(rsvpColor.opacity(0.15))
                    )
                    .foregroundStyle(rsvpColor)
            }
        }
        .padding(.vertical, 4)
    }

    var rsvpColor: Color {
        switch guest.rsvpStatus {
        case "accepted": return .green
        case "declined": return .red
        default: return .orange
        }
    }
}

// MARK: - Todo Row

struct TodoRow: View {
    @Bindable var todo: PartyTodo
    let onDelete: () -> Void

    var body: some View {
        HStack {
            Button {
                withAnimation {
                    todo.isCompleted.toggle()
                }
            } label: {
                Image(systemName: todo.isCompleted ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(todo.isCompleted ? .green : .secondary)
                    .font(.title3)
            }

            Text(todo.title)
                .font(.subheadline)
                .strikethrough(todo.isCompleted)
                .foregroundStyle(todo.isCompleted ? .secondary : .primary)

            Spacer()

            Button(role: .destructive, action: onDelete) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(.red.opacity(0.5))
                    .font(.caption)
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    PartyPlannerView()
        .modelContainer(for: [Birthday.self, PartyGuest.self, PartyTodo.self], inMemory: true)
}
