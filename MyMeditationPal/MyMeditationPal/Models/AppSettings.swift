//
//  AppSettings.swift
//  MyMeditationPal
//

import Foundation
import Combine

class AppSettings: ObservableObject {
    private let defaults = UserDefaults.standard

    // MARK: - Exercises
    @Published var boxBreathingEnabled: Bool { didSet { save("exerciseEnabled_boxBreathing", value: boxBreathingEnabled) } }
    @Published var meditationEnabled: Bool   { didSet { save("exerciseEnabled_meditation", value: meditationEnabled) } }
    @Published var coherentBreathingEnabled: Bool { didSet { save("exerciseEnabled_coherentBreathing", value: coherentBreathingEnabled) } }
    @Published var bodyScanEnabled: Bool     { didSet { save("exerciseEnabled_bodyScan", value: bodyScanEnabled) } }
    @Published var kegelEnabled: Bool        { didSet { save("exerciseEnabled_kegel", value: kegelEnabled) } }

    // MARK: - Journals
    @Published var morningJournalEnabled: Bool { didSet { save("journalEnabled_morning", value: morningJournalEnabled) } }
    @Published var nightJournalEnabled: Bool   { didSet { save("journalEnabled_night", value: nightJournalEnabled) } }

    // MARK: - Daily Habits
    @Published var dailyHabitsEnabled: Bool { didSet { save("habitsEnabled", value: dailyHabitsEnabled) } }

    /// IDs of habits the user has turned off in settings.
    @Published var disabledHabitIDs: Set<UUID> {
        didSet {
            if let data = try? JSONEncoder().encode(disabledHabitIDs.map { $0.uuidString }) {
                defaults.set(data, forKey: "disabledHabitIDs")
            }
        }
    }

    init() {
        self.boxBreathingEnabled     = Self.loadBool("exerciseEnabled_boxBreathing")
        self.meditationEnabled       = Self.loadBool("exerciseEnabled_meditation")
        self.coherentBreathingEnabled = Self.loadBool("exerciseEnabled_coherentBreathing")
        self.bodyScanEnabled         = Self.loadBool("exerciseEnabled_bodyScan")
        self.kegelEnabled            = Self.loadBool("exerciseEnabled_kegel")
        self.morningJournalEnabled   = Self.loadBool("journalEnabled_morning")
        self.nightJournalEnabled     = Self.loadBool("journalEnabled_night")
        self.dailyHabitsEnabled      = Self.loadBool("habitsEnabled")

        if let data = UserDefaults.standard.data(forKey: "disabledHabitIDs"),
           let strings = try? JSONDecoder().decode([String].self, from: data) {
            self.disabledHabitIDs = Set(strings.compactMap { UUID(uuidString: $0) })
        } else {
            self.disabledHabitIDs = []
        }
    }

    func isHabitEnabled(_ id: UUID) -> Bool {
        !disabledHabitIDs.contains(id)
    }

    func toggleHabit(_ id: UUID) {
        if disabledHabitIDs.contains(id) {
            disabledHabitIDs.remove(id)
        } else {
            disabledHabitIDs.insert(id)
        }
    }

    // MARK: - Helpers

    private func save(_ key: String, value: Bool) {
        defaults.set(value, forKey: key)
    }

    /// Returns true if no value has ever been stored (default on = true).
    private static func loadBool(_ key: String) -> Bool {
        guard UserDefaults.standard.object(forKey: key) != nil else { return true }
        return UserDefaults.standard.bool(forKey: key)
    }
}
