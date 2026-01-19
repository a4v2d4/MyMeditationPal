//
//  MeditationViewModel.swift
//  MyMeditationPal
//
//  Created by Aaron Van Doren on 1/18/26.
//

import Foundation
import CoreData
import SwiftUI

class MeditationViewModel: ObservableObject {
    let persistenceController: PersistenceController
    
    @Published var todayBoxBreathingCompleted: Bool = false
    @Published var todayMeditationCompleted: Bool = false
    @Published var todayCoherentBreathingCompleted: Bool = false
    @Published var todayBodyScanCompleted: Bool = false
    @Published var todayGratitudeCompleted: Bool = false
    @Published var todayAffirmationCompleted: Bool = false
    @Published var todayGreatDayCompleted: Bool = false
    @Published var boxBreathingStreak: Int = 0
    @Published var meditationStreak: Int = 0
    @Published var coherentBreathingStreak: Int = 0
    @Published var bodyScanStreak: Int = 0
    @Published var gratitudeStreak: Int = 0
    @Published var affirmationStreak: Int = 0
    @Published var greatDayStreak: Int = 0
    
    init(persistenceController: PersistenceController = .shared) {
        self.persistenceController = persistenceController
        loadTodayStatus()
        calculateStreaks()
    }
    
    // MARK: - Date Helpers
    
    private func startOfDay(for date: Date = Date()) -> Date {
        Calendar.current.startOfDay(for: date)
    }
    
    private func isSameDay(_ date1: Date, _ date2: Date) -> Bool {
        Calendar.current.isDate(date1, inSameDayAs: date2)
    }
    
    // MARK: - Fetch Today's Completion
    
    func loadTodayStatus() {
        let context = persistenceController.container.viewContext
        let today = startOfDay()
        
        let fetchRequest: NSFetchRequest<DailyCompletion> = DailyCompletion.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "date >= %@ AND date < %@",
                                            today as NSDate,
                                            Calendar.current.date(byAdding: .day, value: 1, to: today)! as NSDate)
        
        do {
            let results = try context.fetch(fetchRequest)
            if let todayCompletion = results.first {
                todayBoxBreathingCompleted = todayCompletion.boxBreathingCompleted
                todayMeditationCompleted = todayCompletion.meditationCompleted
                todayCoherentBreathingCompleted = todayCompletion.coherentBreathingCompleted
                todayBodyScanCompleted = todayCompletion.bodyScanCompleted
                todayGratitudeCompleted = todayCompletion.value(forKey: "gratitudeCompleted") as? Bool ?? false
                todayAffirmationCompleted = todayCompletion.value(forKey: "affirmationCompleted") as? Bool ?? false
                todayGreatDayCompleted = todayCompletion.value(forKey: "greatDayCompleted") as? Bool ?? false
            } else {
                // Create today's entry
                createTodayEntry()
            }
        } catch {
            print("Error fetching today's completion: \(error)")
        }
    }
    
    private func createTodayEntry() {
        let context = persistenceController.container.viewContext
        let completion = DailyCompletion(context: context)
        completion.date = startOfDay()
        completion.boxBreathingCompleted = false
        completion.meditationCompleted = false
        completion.coherentBreathingCompleted = false
        completion.bodyScanCompleted = false
        completion.setValue(false, forKey: "gratitudeCompleted")
        completion.setValue(nil, forKey: "gratitudeItems")
        completion.setValue(false, forKey: "affirmationCompleted")
        completion.setValue(nil, forKey: "affirmationItems")
        completion.setValue(false, forKey: "greatDayCompleted")
        completion.setValue(nil, forKey: "greatDayItems")
        
        do {
            try context.save()
        } catch {
            print("Error creating today's entry: \(error)")
        }
    }
    
    // MARK: - Mark Completion
    
    func markCompleted(exerciseType: ExerciseType) {
        let context = persistenceController.container.viewContext
        let today = startOfDay()
        
        let fetchRequest: NSFetchRequest<DailyCompletion> = DailyCompletion.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "date >= %@ AND date < %@",
                                            today as NSDate,
                                            Calendar.current.date(byAdding: .day, value: 1, to: today)! as NSDate)
        
        do {
            let results = try context.fetch(fetchRequest)
            let todayCompletion = results.first ?? {
                let completion = DailyCompletion(context: context)
                completion.date = today
                completion.boxBreathingCompleted = false
                completion.meditationCompleted = false
                completion.coherentBreathingCompleted = false
                completion.bodyScanCompleted = false
                completion.setValue(false, forKey: "gratitudeCompleted")
                completion.setValue(nil, forKey: "gratitudeItems")
                completion.setValue(false, forKey: "affirmationCompleted")
                completion.setValue(nil, forKey: "affirmationItems")
                completion.setValue(false, forKey: "greatDayCompleted")
                completion.setValue(nil, forKey: "greatDayItems")
                return completion
            }()
            
            switch exerciseType {
            case .boxBreathing:
                todayCompletion.boxBreathingCompleted = true
                todayBoxBreathingCompleted = true
            case .meditation:
                todayCompletion.meditationCompleted = true
                todayMeditationCompleted = true
            case .coherentBreathing:
                todayCompletion.coherentBreathingCompleted = true
                todayCoherentBreathingCompleted = true
            case .bodyScan:
                todayCompletion.bodyScanCompleted = true
                todayBodyScanCompleted = true
            }
            
            try context.save()
            calculateStreaks()
        } catch {
            print("Error marking completion: \(error)")
        }
    }
    
    // MARK: - Calculate Streaks
    
    func calculateStreaks() {
        boxBreathingStreak = calculateStreak(for: \.boxBreathingCompleted)
        meditationStreak = calculateStreak(for: \.meditationCompleted)
        coherentBreathingStreak = calculateStreak(for: \.coherentBreathingCompleted)
        bodyScanStreak = calculateStreak(for: \.bodyScanCompleted)
        gratitudeStreak = calculateGratitudeStreak()
        affirmationStreak = calculateAffirmationStreak()
        greatDayStreak = calculateGreatDayStreak()
    }
    
    private func calculateStreak(for keyPath: KeyPath<DailyCompletion, Bool>) -> Int {
        let context = persistenceController.container.viewContext
        let fetchRequest: NSFetchRequest<DailyCompletion> = DailyCompletion.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \DailyCompletion.date, ascending: false)]
        
        do {
            let completions = try context.fetch(fetchRequest)
            var streak = 0
            var currentDate = startOfDay()
            
            for completion in completions {
                guard let completionDate = completion.date else { continue }
                
                // Check if this completion is for the current streak day
                if isSameDay(completionDate, currentDate) {
                    if completion[keyPath: keyPath] {
                        streak += 1
                        // Move to previous day
                        currentDate = Calendar.current.date(byAdding: .day, value: -1, to: currentDate)!
                    } else {
                        break
                    }
                } else if completionDate < currentDate {
                    // Gap in streak
                    break
                }
            }
            
            return streak
        } catch {
            print("Error calculating streak: \(error)")
            return 0
        }
    }
    
    private func calculateGratitudeStreak() -> Int {
        let context = persistenceController.container.viewContext
        let fetchRequest: NSFetchRequest<DailyCompletion> = DailyCompletion.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \DailyCompletion.date, ascending: false)]
        
        do {
            let completions = try context.fetch(fetchRequest)
            var streak = 0
            var currentDate = startOfDay()
            
            for completion in completions {
                guard let completionDate = completion.date else { continue }
                
                // Check if this completion is for the current streak day
                if isSameDay(completionDate, currentDate) {
                    if completion.value(forKey: "gratitudeCompleted") as? Bool ?? false {
                        streak += 1
                        // Move to previous day
                        currentDate = Calendar.current.date(byAdding: .day, value: -1, to: currentDate)!
                    } else {
                        break
                    }
                } else if completionDate < currentDate {
                    // Gap in streak
                    break
                }
            }
            
            return streak
        } catch {
            print("Error calculating gratitude streak: \(error)")
            return 0
        }
    }
    
    // MARK: - Gratitude Journal Methods
    
    func markGratitudeCompleted() {
        let context = persistenceController.container.viewContext
        let today = startOfDay()
        
        let fetchRequest: NSFetchRequest<DailyCompletion> = DailyCompletion.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "date >= %@ AND date < %@",
                                            today as NSDate,
                                            Calendar.current.date(byAdding: .day, value: 1, to: today)! as NSDate)
        
        do {
            let results = try context.fetch(fetchRequest)
            let todayCompletion = results.first ?? {
                let completion = DailyCompletion(context: context)
                completion.date = today
                completion.boxBreathingCompleted = false
                completion.meditationCompleted = false
                completion.coherentBreathingCompleted = false
                completion.bodyScanCompleted = false
                completion.setValue(false, forKey: "gratitudeCompleted")
                completion.setValue(nil, forKey: "gratitudeItems")
                return completion
            }()
            
            todayCompletion.setValue(true, forKey: "gratitudeCompleted")
            todayGratitudeCompleted = true
            
            try context.save()
            calculateStreaks()
        } catch {
            print("Error marking gratitude completion: \(error)")
        }
    }
    
    func saveGratitudeItems(_ items: [String]) {
        let context = persistenceController.container.viewContext
        let today = startOfDay()
        
        let fetchRequest: NSFetchRequest<DailyCompletion> = DailyCompletion.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "date >= %@ AND date < %@",
                                            today as NSDate,
                                            Calendar.current.date(byAdding: .day, value: 1, to: today)! as NSDate)
        
        do {
            let results = try context.fetch(fetchRequest)
            let todayCompletion = results.first ?? {
                let completion = DailyCompletion(context: context)
                completion.date = today
                completion.boxBreathingCompleted = false
                completion.meditationCompleted = false
                completion.coherentBreathingCompleted = false
                completion.bodyScanCompleted = false
                completion.setValue(false, forKey: "gratitudeCompleted")
                completion.setValue(nil, forKey: "gratitudeItems")
                return completion
            }()
            
            // Convert items array to JSON string
            if let jsonData = try? JSONEncoder().encode(items),
               let jsonString = String(data: jsonData, encoding: .utf8) {
                todayCompletion.setValue(jsonString, forKey: "gratitudeItems")
            }
            
            try context.save()
        } catch {
            print("Error saving gratitude items: \(error)")
        }
    }
    
    func loadTodayGratitudeItems() -> [String]? {
        let context = persistenceController.container.viewContext
        let today = startOfDay()
        
        let fetchRequest: NSFetchRequest<DailyCompletion> = DailyCompletion.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "date >= %@ AND date < %@",
                                            today as NSDate,
                                            Calendar.current.date(byAdding: .day, value: 1, to: today)! as NSDate)
        
        do {
            let results = try context.fetch(fetchRequest)
            if let todayCompletion = results.first,
               let jsonString = todayCompletion.value(forKey: "gratitudeItems") as? String,
               let jsonData = jsonString.data(using: .utf8),
               let items = try? JSONDecoder().decode([String].self, from: jsonData) {
                return items
            }
        } catch {
            print("Error loading gratitude items: \(error)")
        }
        
        return nil
    }
    
    private func calculateAffirmationStreak() -> Int {
        let context = persistenceController.container.viewContext
        let fetchRequest: NSFetchRequest<DailyCompletion> = DailyCompletion.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \DailyCompletion.date, ascending: false)]
        
        do {
            let completions = try context.fetch(fetchRequest)
            var streak = 0
            var currentDate = startOfDay()
            
            for completion in completions {
                guard let completionDate = completion.date else { continue }
                
                if isSameDay(completionDate, currentDate) {
                    if completion.value(forKey: "affirmationCompleted") as? Bool ?? false {
                        streak += 1
                        currentDate = Calendar.current.date(byAdding: .day, value: -1, to: currentDate)!
                    } else {
                        break
                    }
                } else if completionDate < currentDate {
                    break
                }
            }
            
            return streak
        } catch {
            print("Error calculating affirmation streak: \(error)")
            return 0
        }
    }
    
    private func calculateGreatDayStreak() -> Int {
        let context = persistenceController.container.viewContext
        let fetchRequest: NSFetchRequest<DailyCompletion> = DailyCompletion.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \DailyCompletion.date, ascending: false)]
        
        do {
            let completions = try context.fetch(fetchRequest)
            var streak = 0
            var currentDate = startOfDay()
            
            for completion in completions {
                guard let completionDate = completion.date else { continue }
                
                if isSameDay(completionDate, currentDate) {
                    if completion.value(forKey: "greatDayCompleted") as? Bool ?? false {
                        streak += 1
                        currentDate = Calendar.current.date(byAdding: .day, value: -1, to: currentDate)!
                    } else {
                        break
                    }
                } else if completionDate < currentDate {
                    break
                }
            }
            
            return streak
        } catch {
            print("Error calculating great day streak: \(error)")
            return 0
        }
    }
    
    // MARK: - Affirmation Methods
    
    func markAffirmationCompleted() {
        let context = persistenceController.container.viewContext
        let today = startOfDay()
        
        let fetchRequest: NSFetchRequest<DailyCompletion> = DailyCompletion.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "date >= %@ AND date < %@",
                                            today as NSDate,
                                            Calendar.current.date(byAdding: .day, value: 1, to: today)! as NSDate)
        
        do {
            let results = try context.fetch(fetchRequest)
            let todayCompletion = results.first ?? {
                let completion = DailyCompletion(context: context)
                completion.date = today
                completion.boxBreathingCompleted = false
                completion.meditationCompleted = false
                completion.coherentBreathingCompleted = false
                completion.bodyScanCompleted = false
                completion.setValue(false, forKey: "gratitudeCompleted")
                completion.setValue(nil, forKey: "gratitudeItems")
                completion.setValue(false, forKey: "affirmationCompleted")
                completion.setValue(nil, forKey: "affirmationItems")
                completion.setValue(false, forKey: "greatDayCompleted")
                completion.setValue(nil, forKey: "greatDayItems")
                return completion
            }()
            
            todayCompletion.setValue(true, forKey: "affirmationCompleted")
            todayAffirmationCompleted = true
            
            try context.save()
            calculateStreaks()
        } catch {
            print("Error marking affirmation completion: \(error)")
        }
    }
    
    func saveAffirmationItems(_ items: [String]) {
        let context = persistenceController.container.viewContext
        let today = startOfDay()
        
        let fetchRequest: NSFetchRequest<DailyCompletion> = DailyCompletion.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "date >= %@ AND date < %@",
                                            today as NSDate,
                                            Calendar.current.date(byAdding: .day, value: 1, to: today)! as NSDate)
        
        do {
            let results = try context.fetch(fetchRequest)
            let todayCompletion = results.first ?? {
                let completion = DailyCompletion(context: context)
                completion.date = today
                completion.boxBreathingCompleted = false
                completion.meditationCompleted = false
                completion.coherentBreathingCompleted = false
                completion.bodyScanCompleted = false
                completion.setValue(false, forKey: "gratitudeCompleted")
                completion.setValue(nil, forKey: "gratitudeItems")
                completion.setValue(false, forKey: "affirmationCompleted")
                completion.setValue(nil, forKey: "affirmationItems")
                completion.setValue(false, forKey: "greatDayCompleted")
                completion.setValue(nil, forKey: "greatDayItems")
                return completion
            }()
            
            if let jsonData = try? JSONEncoder().encode(items),
               let jsonString = String(data: jsonData, encoding: .utf8) {
                todayCompletion.setValue(jsonString, forKey: "affirmationItems")
            }
            
            try context.save()
        } catch {
            print("Error saving affirmation items: \(error)")
        }
    }
    
    func loadTodayAffirmationItems() -> [String]? {
        let context = persistenceController.container.viewContext
        let today = startOfDay()
        
        let fetchRequest: NSFetchRequest<DailyCompletion> = DailyCompletion.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "date >= %@ AND date < %@",
                                            today as NSDate,
                                            Calendar.current.date(byAdding: .day, value: 1, to: today)! as NSDate)
        
        do {
            let results = try context.fetch(fetchRequest)
            if let todayCompletion = results.first,
               let jsonString = todayCompletion.value(forKey: "affirmationItems") as? String,
               let jsonData = jsonString.data(using: .utf8),
               let items = try? JSONDecoder().decode([String].self, from: jsonData) {
                return items
            }
        } catch {
            print("Error loading affirmation items: \(error)")
        }
        
        return nil
    }
    
    // MARK: - Great Day Methods
    
    func markGreatDayCompleted() {
        let context = persistenceController.container.viewContext
        let today = startOfDay()
        
        let fetchRequest: NSFetchRequest<DailyCompletion> = DailyCompletion.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "date >= %@ AND date < %@",
                                            today as NSDate,
                                            Calendar.current.date(byAdding: .day, value: 1, to: today)! as NSDate)
        
        do {
            let results = try context.fetch(fetchRequest)
            let todayCompletion = results.first ?? {
                let completion = DailyCompletion(context: context)
                completion.date = today
                completion.boxBreathingCompleted = false
                completion.meditationCompleted = false
                completion.coherentBreathingCompleted = false
                completion.bodyScanCompleted = false
                completion.setValue(false, forKey: "gratitudeCompleted")
                completion.setValue(nil, forKey: "gratitudeItems")
                completion.setValue(false, forKey: "affirmationCompleted")
                completion.setValue(nil, forKey: "affirmationItems")
                completion.setValue(false, forKey: "greatDayCompleted")
                completion.setValue(nil, forKey: "greatDayItems")
                return completion
            }()
            
            todayCompletion.setValue(true, forKey: "greatDayCompleted")
            todayGreatDayCompleted = true
            
            try context.save()
            calculateStreaks()
        } catch {
            print("Error marking great day completion: \(error)")
        }
    }
    
    func saveGreatDayItems(_ items: [String]) {
        let context = persistenceController.container.viewContext
        let today = startOfDay()
        
        let fetchRequest: NSFetchRequest<DailyCompletion> = DailyCompletion.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "date >= %@ AND date < %@",
                                            today as NSDate,
                                            Calendar.current.date(byAdding: .day, value: 1, to: today)! as NSDate)
        
        do {
            let results = try context.fetch(fetchRequest)
            let todayCompletion = results.first ?? {
                let completion = DailyCompletion(context: context)
                completion.date = today
                completion.boxBreathingCompleted = false
                completion.meditationCompleted = false
                completion.coherentBreathingCompleted = false
                completion.bodyScanCompleted = false
                completion.setValue(false, forKey: "gratitudeCompleted")
                completion.setValue(nil, forKey: "gratitudeItems")
                completion.setValue(false, forKey: "affirmationCompleted")
                completion.setValue(nil, forKey: "affirmationItems")
                completion.setValue(false, forKey: "greatDayCompleted")
                completion.setValue(nil, forKey: "greatDayItems")
                return completion
            }()
            
            if let jsonData = try? JSONEncoder().encode(items),
               let jsonString = String(data: jsonData, encoding: .utf8) {
                todayCompletion.setValue(jsonString, forKey: "greatDayItems")
            }
            
            try context.save()
        } catch {
            print("Error saving great day items: \(error)")
        }
    }
    
    func loadTodayGreatDayItems() -> [String]? {
        let context = persistenceController.container.viewContext
        let today = startOfDay()
        
        let fetchRequest: NSFetchRequest<DailyCompletion> = DailyCompletion.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "date >= %@ AND date < %@",
                                            today as NSDate,
                                            Calendar.current.date(byAdding: .day, value: 1, to: today)! as NSDate)
        
        do {
            let results = try context.fetch(fetchRequest)
            if let todayCompletion = results.first,
               let jsonString = todayCompletion.value(forKey: "greatDayItems") as? String,
               let jsonData = jsonString.data(using: .utf8),
               let items = try? JSONDecoder().decode([String].self, from: jsonData) {
                return items
            }
        } catch {
            print("Error loading great day items: \(error)")
        }
        
        return nil
    }
    
    // MARK: - Fetch All Completions for Calendar
    
    func fetchAllCompletions() -> [DailyCompletion] {
        let context = persistenceController.container.viewContext
        let fetchRequest: NSFetchRequest<DailyCompletion> = DailyCompletion.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \DailyCompletion.date, ascending: false)]
        
        do {
            return try context.fetch(fetchRequest)
        } catch {
            print("Error fetching completions: \(error)")
            return []
        }
    }
}
