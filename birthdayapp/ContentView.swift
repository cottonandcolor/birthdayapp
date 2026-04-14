//
//  ContentView.swift
//  birthdayapp
//
//  Created by Preeti Dave on 4/12/26.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase
    @Query(sort: \Birthday.date) private var birthdays: [Birthday]
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    /// Own presentation state avoids an inverted `Binding` on `fullScreenCover`, which can stick out of sync with `AppStorage` on some OS versions.
    @State private var showOnboarding = !UserDefaults.standard.bool(forKey: "hasSeenOnboarding")

    var body: some View {
        TabView {
            BirthdayListView()
                .tabItem {
                    Label("Birthdays", systemImage: "gift.fill")
                }

            CountdownView()
                .tabItem {
                    Label("Countdown", systemImage: "timer")
                }

            CardCreatorView()
                .tabItem {
                    Label("Cards", systemImage: "envelope.fill")
                }

            PartyPlannerView()
                .tabItem {
                    Label("Party", systemImage: "party.popper.fill")
                }
        }
        .tint(.pink)
        .onAppear {
            if hasSeenOnboarding { showOnboarding = false }
        }
        .onChange(of: hasSeenOnboarding) { _, completed in
            if completed { showOnboarding = false }
        }
        .fullScreenCover(isPresented: $showOnboarding) {
            OnboardingView()
        }
        .task {
            await BirthdayNotificationScheduler.rescheduleAll(birthdays: birthdays)
            BirthdayWidgetWriter.update(from: birthdays)
        }
        .onChange(of: scenePhase) { _, newPhase in
            guard newPhase == .active else { return }
            Task {
                await BirthdayNotificationScheduler.rescheduleAll(birthdays: birthdays)
            }
            BirthdayWidgetWriter.update(from: birthdays)
        }
        .onChange(of: birthdays.count) { _, _ in
            Task {
                await BirthdayNotificationScheduler.rescheduleAll(birthdays: birthdays)
            }
            BirthdayWidgetWriter.update(from: birthdays)
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Birthday.self, PartyGuest.self, PartyTodo.self], inMemory: true)
}
