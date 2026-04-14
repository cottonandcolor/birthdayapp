//
//  Item.swift
//  birthdayapp
//
//  Created by Preeti Dave on 4/12/26.
//

import Foundation
import SwiftData

// MARK: - Birthday Model

@Model
final class Birthday {
    var name: String
    var date: Date
    var notes: String
    var emoji: String
    var cardMessage: String
    var cardColorHex: String

    @Relationship(deleteRule: .cascade) var partyGuests: [PartyGuest]
    @Relationship(deleteRule: .cascade) var partyTodos: [PartyTodo]

    var hasParty: Bool
    /// Comma-separated label for filtering (e.g. Family, Work).
    var groupTag: String
    /// Optional gift budget in the user’s local currency; 0 means none.
    var giftBudget: Double

    init(
        name: String,
        date: Date,
        notes: String = "",
        emoji: String = "🎂",
        cardMessage: String = "",
        cardColorHex: String = "FF6B8A",
        hasParty: Bool = false,
        groupTag: String = "",
        giftBudget: Double = 0
    ) {
        self.name = name
        self.date = date
        self.notes = notes
        self.emoji = emoji
        self.cardMessage = cardMessage
        self.cardColorHex = cardColorHex
        self.hasParty = hasParty
        self.groupTag = groupTag
        self.giftBudget = giftBudget
        self.partyGuests = []
        self.partyTodos = []
    }

    var nextBirthday: Date {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let birthdayComponents = calendar.dateComponents([.month, .day], from: date)
        var nextComponents = DateComponents()
        nextComponents.month = birthdayComponents.month
        nextComponents.day = birthdayComponents.day
        nextComponents.year = calendar.component(.year, from: today)

        if let next = calendar.date(from: nextComponents), next >= today {
            return next
        }
        nextComponents.year = calendar.component(.year, from: today) + 1
        return calendar.date(from: nextComponents) ?? today
    }

    var daysUntilBirthday: Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        return calendar.dateComponents([.day], from: today, to: nextBirthday).day ?? 0
    }

    var age: Int {
        let calendar = Calendar.current
        return calendar.dateComponents([.year], from: date, to: Date()).year ?? 0
    }

    var isBirthdayToday: Bool {
        daysUntilBirthday == 0
    }
}

// MARK: - Party Guest Model

@Model
final class PartyGuest {
    var name: String
    var rsvpStatus: String // "pending", "accepted", "declined"

    @Relationship(inverse: \Birthday.partyGuests) var birthday: Birthday?

    init(name: String, rsvpStatus: String = "pending") {
        self.name = name
        self.rsvpStatus = rsvpStatus
    }

    var rsvpEmoji: String {
        switch rsvpStatus {
        case "accepted": return "✅"
        case "declined": return "❌"
        default: return "⏳"
        }
    }
}

// MARK: - Party Todo Model

@Model
final class PartyTodo {
    var title: String
    var isCompleted: Bool

    @Relationship(inverse: \Birthday.partyTodos) var birthday: Birthday?

    init(title: String, isCompleted: Bool = false) {
        self.title = title
        self.isCompleted = isCompleted
    }
}
