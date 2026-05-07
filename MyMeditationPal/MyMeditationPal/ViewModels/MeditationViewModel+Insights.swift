//
//  MeditationViewModel+Insights.swift
//  MyMeditationPal
//
//  Scoring, weekly/monthly aggregation, and trend-data helpers used by InsightsView.
//

import Foundation
import CoreData

// MARK: - Public Result Types

struct DailyScorePoint: Identifiable {
    let id = UUID()
    let date: Date
    /// 0.0 - 1.0
    let score: Double
}

struct WeeklyCompletionPoint: Identifiable {
    let id = UUID()
    /// Date representing the start of the week.
    let weekStart: Date
    /// 0.0 - 1.0
    let completion: Double
}

struct ActivityScore {
    let activity: TrackedActivity
    /// 0.0 - 1.0
    let weekly: Double
    /// 0.0 - 1.0
    let monthly: Double
}

// MARK: - MeditationViewModel Extension

extension MeditationViewModel {
    
    // MARK: - Activity Registry
    
    /// All currently-tracked activities: exercises + journals + each daily habit.
    func currentActivities() -> [TrackedActivity] {
        var result = TrackedActivity.exercises + TrackedActivity.journals
        
        // Use today's saved habits when available; otherwise fall back to defaults.
        let habits = loadTodayDailyHabits() ?? DailyHabitsView.defaultHabits
        for habit in habits {
            result.append(.forHabit(id: habit.id, name: habit.name))
        }
        return result
    }
    
    // MARK: - Per-day Completion Lookup
    
    /// Returns whether the given activity was completed on the date represented by `completion`.
    /// Pass `nil` for `completion` to indicate no record for the day (always false).
    func isCompleted(activity: TrackedActivity, on completion: DailyCompletion?) -> Bool {
        guard let completion = completion else { return false }
        
        switch activity.id {
        case TrackedActivity.boxBreathing.id:
            return completion.boxBreathingCompleted
        case TrackedActivity.meditation.id:
            return completion.meditationCompleted
        case TrackedActivity.coherentBreathing.id:
            return completion.coherentBreathingCompleted
        case TrackedActivity.bodyScan.id:
            return completion.bodyScanCompleted
        case TrackedActivity.kegelExercise.id:
            return completion.kegelExerciseCompleted
        case TrackedActivity.morningJournal.id:
            let g = completion.value(forKey: "gratitudeCompleted") as? Bool ?? false
            let a = completion.value(forKey: "affirmationCompleted") as? Bool ?? false
            let gd = completion.value(forKey: "greatDayCompleted") as? Bool ?? false
            return g && a && gd
        case TrackedActivity.nightJournal.id:
            let h = completion.value(forKey: "highlightCompleted") as? Bool ?? false
            let l = completion.value(forKey: "learningCompleted") as? Bool ?? false
            let e = completion.value(forKey: "excitementCompleted") as? Bool ?? false
            return h && l && e
        default:
            // Daily habit lookup
            guard let habitID = activity.habitID else { return false }
            guard let json = completion.value(forKey: "dailyHabitsItems") as? String,
                  let data = json.data(using: .utf8),
                  let habits = try? JSONDecoder().decode([DailyHabit].self, from: data) else {
                return false
            }
            return habits.first(where: { $0.id == habitID })?.isCompleted ?? false
        }
    }
    
    // MARK: - Daily Score
    
    /// Daily score as the proportion of `activities` completed on `date`. Range 0.0 - 1.0.
    func dailyScore(for date: Date, activities: [TrackedActivity]? = nil) -> Double {
        let activities = activities ?? currentActivities()
        guard !activities.isEmpty else { return 0 }
        
        let completion = fetchCompletion(for: date)
        let completed = activities.reduce(0) { acc, activity in
            acc + (isCompleted(activity: activity, on: completion) ? 1 : 0)
        }
        return Double(completed) / Double(activities.count)
    }
    
    /// Daily score for "today".
    func todayScore(activities: [TrackedActivity]? = nil) -> Double {
        dailyScore(for: Date(), activities: activities)
    }
    
    // MARK: - Daily Score Trend
    
    /// Daily-score points for the last `daysBack` days (oldest first).
    func dailyScoresTrend(daysBack: Int = 30, activities: [TrackedActivity]? = nil) -> [DailyScorePoint] {
        let activities = activities ?? currentActivities()
        guard !activities.isEmpty else { return [] }
        
        // Build a date->completion map for fast lookups.
        let calendar = Calendar.current
        let allCompletions = fetchAllCompletions()
        var byDay: [Date: DailyCompletion] = [:]
        for c in allCompletions {
            guard let date = c.date else { continue }
            byDay[calendar.startOfDay(for: date)] = c
        }
        
        let today = calendar.startOfDay(for: Date())
        var points: [DailyScorePoint] = []
        for offset in stride(from: daysBack - 1, through: 0, by: -1) {
            guard let day = calendar.date(byAdding: .day, value: -offset, to: today) else { continue }
            let dayStart = calendar.startOfDay(for: day)
            let completion = byDay[dayStart]
            let completed = activities.reduce(0) { acc, activity in
                acc + (isCompleted(activity: activity, on: completion) ? 1 : 0)
            }
            let score = Double(completed) / Double(activities.count)
            points.append(DailyScorePoint(date: dayStart, score: score))
        }
        return points
    }
    
    // MARK: - Per-activity Weekly / Monthly Completion
    
    /// Completion rate of `activity` over the last `days` days. Range 0.0 - 1.0.
    func completionRate(for activity: TrackedActivity, days: Int) -> Double {
        guard days > 0 else { return 0 }
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let allCompletions = fetchAllCompletions()
        var byDay: [Date: DailyCompletion] = [:]
        for c in allCompletions {
            guard let date = c.date else { continue }
            byDay[calendar.startOfDay(for: date)] = c
        }
        
        var completed = 0
        for offset in 0..<days {
            guard let day = calendar.date(byAdding: .day, value: -offset, to: today) else { continue }
            let completion = byDay[calendar.startOfDay(for: day)]
            if isCompleted(activity: activity, on: completion) {
                completed += 1
            }
        }
        return Double(completed) / Double(days)
    }
    
    /// Convenience: completion rate of `activity` over the last 7 days.
    func weeklyCompletion(for activity: TrackedActivity) -> Double {
        completionRate(for: activity, days: 7)
    }
    
    /// Convenience: completion rate of `activity` over the last 30 days.
    func monthlyCompletion(for activity: TrackedActivity) -> Double {
        completionRate(for: activity, days: 30)
    }
    
    /// Computes both weekly and monthly scores for the given activities in one pass.
    func activityScores(for activities: [TrackedActivity]? = nil) -> [ActivityScore] {
        let activities = activities ?? currentActivities()
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let allCompletions = fetchAllCompletions()
        var byDay: [Date: DailyCompletion] = [:]
        for c in allCompletions {
            guard let date = c.date else { continue }
            byDay[calendar.startOfDay(for: date)] = c
        }
        
        return activities.map { activity in
            var weekDone = 0
            var monthDone = 0
            for offset in 0..<30 {
                guard let day = calendar.date(byAdding: .day, value: -offset, to: today) else { continue }
                let completion = byDay[calendar.startOfDay(for: day)]
                if isCompleted(activity: activity, on: completion) {
                    if offset < 7 { weekDone += 1 }
                    monthDone += 1
                }
            }
            return ActivityScore(
                activity: activity,
                weekly: Double(weekDone) / 7.0,
                monthly: Double(monthDone) / 30.0
            )
        }
    }
    
    // MARK: - Per-activity Weekly Trend
    
    /// Weekly completion points for `activity` over the last `weeksBack` rolling weeks.
    /// The most recent point covers the last 7 days; the next covers the 7 days before that, etc.
    /// Returned oldest-first.
    func weeklyCompletionTrend(for activity: TrackedActivity, weeksBack: Int = 12) -> [WeeklyCompletionPoint] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let allCompletions = fetchAllCompletions()
        var byDay: [Date: DailyCompletion] = [:]
        for c in allCompletions {
            guard let date = c.date else { continue }
            byDay[calendar.startOfDay(for: date)] = c
        }
        
        var points: [WeeklyCompletionPoint] = []
        for week in stride(from: weeksBack - 1, through: 0, by: -1) {
            // Week window: [today - (week*7 + 6), today - week*7]
            let endOffset = week * 7
            var done = 0
            for d in 0..<7 {
                let dayOffset = endOffset + d
                guard let day = calendar.date(byAdding: .day, value: -dayOffset, to: today) else { continue }
                let completion = byDay[calendar.startOfDay(for: day)]
                if isCompleted(activity: activity, on: completion) {
                    done += 1
                }
            }
            let weekStart = calendar.date(byAdding: .day, value: -(endOffset + 6), to: today) ?? today
            points.append(WeeklyCompletionPoint(weekStart: calendar.startOfDay(for: weekStart),
                                                completion: Double(done) / 7.0))
        }
        return points
    }
}
