//
//  birthdayappTests.swift
//  birthdayappTests
//
//  Created by Preeti Dave on 4/12/26.
//

import Foundation
import SwiftData
import Testing

@testable import birthdayapp

struct birthdayappTests {

    @Test func speechParserExtractsNameAndDate() {
        let (name, date) = BirthdaySpeechParser.parse("Alex on July 4")
        #expect(name == "Alex")
        #expect(date != nil)
        if let date {
            let cal = Calendar.current
            #expect(cal.component(.month, from: date) == 7)
            #expect(cal.component(.day, from: date) == 4)
        }
    }

    @Test func speechParserEmptyReturnsNil() {
        let (name, date) = BirthdaySpeechParser.parse("   ")
        #expect(name == nil)
        #expect(date == nil)
    }

    @Test func speechParserStripsAddPrefix() {
        let (name, date) = BirthdaySpeechParser.parse("add Sonia")
        #expect(name == "Sonia")
        #expect(date == nil)
    }

    @Test func speechParserStripsCommandsKeepsDate() {
        let (name, date) = BirthdaySpeechParser.parse("remember Alex on July 4")
        #expect(name == "Alex")
        #expect(date != nil)
        if let date {
            let cal = Calendar.current
            #expect(cal.component(.month, from: date) == 7)
            #expect(cal.component(.day, from: date) == 4)
        }
    }

    @Test func notificationStableIdUsesPersistentModelDescription() throws {
        let schema = Schema([Birthday.self, PartyGuest.self, PartyTodo.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true, cloudKitDatabase: .none)
        let container = try ModelContainer(for: schema, configurations: [config])
        let context = ModelContext(container)
        let b = Birthday(name: "Test", date: Date())
        context.insert(b)
        try context.save()
        let id = BirthdayNotificationScheduler.stableId(b)
        #expect(id != "fallback")
        #expect(!id.isEmpty)
    }
}
