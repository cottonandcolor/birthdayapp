//
//  birthdayappApp.swift
//  birthdayapp
//
//  Created by Preeti Dave on 4/12/26.
//

import SwiftUI
import SwiftData

@main
struct birthdayappApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Birthday.self,
            PartyGuest.self,
            PartyTodo.self,
        ])

        let cloudConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false, cloudKitDatabase: .automatic)
        do {
            return try ModelContainer(for: schema, configurations: [cloudConfiguration])
        } catch {
            // CloudKit often fails on Simulator, without an iCloud sign-in, or until the container/schema is ready.
            let localConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false, cloudKitDatabase: .none)
            do {
                return try ModelContainer(for: schema, configurations: [localConfiguration])
            } catch {
                fatalError("Could not create ModelContainer (CloudKit error: \(error); local fallback also failed)")
            }
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}
