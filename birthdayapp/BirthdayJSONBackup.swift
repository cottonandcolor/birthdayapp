//
//  BirthdayJSONBackup.swift
//  birthdayapp
//

import Foundation
import SwiftData

private struct BirthdayBackupRecord: Codable {
    var name: String
    var date: Date
    var notes: String
    var emoji: String
    var cardMessage: String
    var cardColorHex: String
    var hasParty: Bool
    var groupTag: String
    var giftBudget: Double
}

enum BirthdayJSONBackup {
    private static let encoder: JSONEncoder = {
        let e = JSONEncoder()
        e.outputFormatting = [.prettyPrinted, .sortedKeys]
        e.dateEncodingStrategy = .iso8601
        return e
    }()

    private static let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        return d
    }()

    static func exportData(from birthdays: [Birthday]) throws -> Data {
        let records = birthdays.map {
            BirthdayBackupRecord(
                name: $0.name,
                date: $0.date,
                notes: $0.notes,
                emoji: $0.emoji,
                cardMessage: $0.cardMessage,
                cardColorHex: $0.cardColorHex,
                hasParty: $0.hasParty,
                groupTag: $0.groupTag,
                giftBudget: $0.giftBudget
            )
        }
        return try encoder.encode(records)
    }

    static func importData(_ data: Data, into context: ModelContext) throws {
        let records = try decoder.decode([BirthdayBackupRecord].self, from: data)
        for r in records {
            let b = Birthday(
                name: r.name,
                date: r.date,
                notes: r.notes,
                emoji: r.emoji,
                cardMessage: r.cardMessage,
                cardColorHex: r.cardColorHex,
                hasParty: r.hasParty,
                groupTag: r.groupTag,
                giftBudget: r.giftBudget
            )
            context.insert(b)
        }
        try context.save()
    }
}
