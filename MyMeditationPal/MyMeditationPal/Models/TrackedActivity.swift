//
//  TrackedActivity.swift
//  MyMeditationPal
//
//  Represents any item we score per-day: an exercise, a journal, or a daily habit.
//

import SwiftUI

struct TrackedActivity: Identifiable, Hashable {
    enum Category: String, Hashable, CaseIterable {
        case exercise
        case journal
        case habit
        
        var displayName: String {
            switch self {
            case .exercise: return "Exercises"
            case .journal: return "Journals"
            case .habit: return "Daily Habits"
            }
        }
    }
    
    let id: String
    let name: String
    let category: Category
    let color: Color
    
    static func == (lhs: TrackedActivity, rhs: TrackedActivity) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

// MARK: - Built-in Activities

extension TrackedActivity {
    static let boxBreathing = TrackedActivity(
        id: "boxBreathing",
        name: "Box Breathing",
        category: .exercise,
        color: Theme.deepBlue
    )
    
    static let meditation = TrackedActivity(
        id: "meditation",
        name: "Meditation",
        category: .exercise,
        color: Theme.primaryOrange
    )
    
    static let coherentBreathing = TrackedActivity(
        id: "coherentBreathing",
        name: "Coherent Breathing",
        category: .exercise,
        color: Color(red: 0.4, green: 0.6, blue: 0.8)
    )
    
    static let bodyScan = TrackedActivity(
        id: "bodyScan",
        name: "Body Scan",
        category: .exercise,
        color: Color(red: 0.6, green: 0.4, blue: 0.8)
    )
    
    static let kegelExercise = TrackedActivity(
        id: "kegelExercise",
        name: "Kegel Exercise",
        category: .exercise,
        color: Color(red: 0.8, green: 0.5, blue: 0.6)
    )
    
    static let morningJournal = TrackedActivity(
        id: "morningJournal",
        name: "Morning Journal",
        category: .journal,
        color: Color(red: 0.95, green: 0.75, blue: 0.3)
    )
    
    static let nightJournal = TrackedActivity(
        id: "nightJournal",
        name: "Night Journal",
        category: .journal,
        color: Color(red: 0.5, green: 0.4, blue: 0.7)
    )
    
    static let exercises: [TrackedActivity] = [
        .boxBreathing, .meditation, .coherentBreathing, .bodyScan, .kegelExercise
    ]
    
    static let journals: [TrackedActivity] = [.morningJournal, .nightJournal]
    
    /// Build a TrackedActivity for a specific daily habit.
    static func forHabit(id: UUID, name: String) -> TrackedActivity {
        TrackedActivity(
            id: "habit:\(id.uuidString)",
            name: name,
            category: .habit,
            color: Color(red: 0.3, green: 0.7, blue: 0.9)
        )
    }
    
    /// Returns the underlying habit UUID if this activity represents a daily habit.
    var habitID: UUID? {
        guard id.hasPrefix("habit:") else { return nil }
        return UUID(uuidString: String(id.dropFirst("habit:".count)))
    }
}
