//
//  PartyTemplateSeeder.swift
//  birthdayapp
//

import Foundation

enum PartyTemplateSeeder {
    static let defaultTodoTitles = [
        "Send invitations",
        "Order cake or desserts",
        "Decorations and theme",
        "Music or playlist",
        "Party favors",
    ]

    /// Adds starter todos when a party is enabled and the list is empty.
    static func seedIfNeeded(birthday: Birthday) {
        guard birthday.hasParty, birthday.partyTodos.isEmpty else { return }
        for title in defaultTodoTitles {
            birthday.partyTodos.append(PartyTodo(title: title))
        }
    }
}
