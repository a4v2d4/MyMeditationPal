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
    @Published var todayKegelExerciseCompleted: Bool = false
    @Published var todayGratitudeCompleted: Bool = false
    @Published var todayAffirmationCompleted: Bool = false
    @Published var todayGreatDayCompleted: Bool = false
    @Published var todayHighlightCompleted: Bool = false
    @Published var todayLearningCompleted: Bool = false
    @Published var todayExcitementCompleted: Bool = false
    @Published var boxBreathingStreak: Int = 0
    @Published var meditationStreak: Int = 0
    @Published var coherentBreathingStreak: Int = 0
    @Published var bodyScanStreak: Int = 0
    @Published var kegelExerciseStreak: Int = 0
    @Published var gratitudeStreak: Int = 0
    @Published var affirmationStreak: Int = 0
    @Published var greatDayStreak: Int = 0
    @Published var highlightStreak: Int = 0
    @Published var learningStreak: Int = 0
    @Published var excitementStreak: Int = 0
    
    // Composite streaks
    @Published var morningJournalStreak: Int = 0
    @Published var nightJournalStreak: Int = 0
    
    // Composite completion
    var todayMorningJournalCompleted: Bool {
        todayGratitudeCompleted && todayAffirmationCompleted && todayGreatDayCompleted
    }
    
    var todayNightJournalCompleted: Bool {
        todayHighlightCompleted && todayLearningCompleted && todayExcitementCompleted
    }
    
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
                todayKegelExerciseCompleted = todayCompletion.kegelExerciseCompleted
                todayGratitudeCompleted = todayCompletion.value(forKey: "gratitudeCompleted") as? Bool ?? false
                todayAffirmationCompleted = todayCompletion.value(forKey: "affirmationCompleted") as? Bool ?? false
                todayGreatDayCompleted = todayCompletion.value(forKey: "greatDayCompleted") as? Bool ?? false
                todayHighlightCompleted = todayCompletion.value(forKey: "highlightCompleted") as? Bool ?? false
                todayLearningCompleted = todayCompletion.value(forKey: "learningCompleted") as? Bool ?? false
                todayExcitementCompleted = todayCompletion.value(forKey: "excitementCompleted") as? Bool ?? false
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
        completion.kegelExerciseCompleted = false
        completion.gratitudeCompleted = false
        completion.setValue(nil, forKey: "gratitudeItems")
        completion.setValue(false, forKey: "affirmationCompleted")
        completion.setValue(nil, forKey: "affirmationItems")
        completion.setValue(false, forKey: "greatDayCompleted")
        completion.setValue(nil, forKey: "greatDayItems")
        completion.setValue(false, forKey: "highlightCompleted")
        completion.setValue(nil, forKey: "highlightItems")
        completion.setValue(false, forKey: "learningCompleted")
        completion.setValue(nil, forKey: "learningItems")
        completion.setValue(false, forKey: "excitementCompleted")
        completion.setValue(nil, forKey: "excitementItems")
        
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
            case .meditation(_):
                todayCompletion.meditationCompleted = true
                todayMeditationCompleted = true
            case .coherentBreathing(_):
                todayCompletion.coherentBreathingCompleted = true
                todayCoherentBreathingCompleted = true
            case .bodyScan:
                todayCompletion.bodyScanCompleted = true
                todayBodyScanCompleted = true
            case .kegelExercise:
                todayCompletion.kegelExerciseCompleted = true
                todayKegelExerciseCompleted = true
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
        kegelExerciseStreak = calculateKegelExerciseStreak()
        gratitudeStreak = calculateGratitudeStreak()
        affirmationStreak = calculateAffirmationStreak()
        greatDayStreak = calculateGreatDayStreak()
        highlightStreak = calculateHighlightStreak()
        learningStreak = calculateLearningStreak()
        excitementStreak = calculateExcitementStreak()
        morningJournalStreak = calculateMorningJournalStreak()
        nightJournalStreak = calculateNightJournalStreak()
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
    
    private func calculateKegelExerciseStreak() -> Int {
        calculateStreak(for: \.kegelExerciseCompleted)
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
            let todayCompletion = results.first ?? createDefaultCompletion(context: context, date: today)
            
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
            let todayCompletion = results.first ?? createDefaultCompletion(context: context, date: today)
            
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
    
    private func calculateHighlightStreak() -> Int {
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
                    if completion.value(forKey: "highlightCompleted") as? Bool ?? false {
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
            print("Error calculating highlight streak: \(error)")
            return 0
        }
    }
    
    private func calculateLearningStreak() -> Int {
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
                    if completion.value(forKey: "learningCompleted") as? Bool ?? false {
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
            print("Error calculating learning streak: \(error)")
            return 0
        }
    }
    
    private func calculateExcitementStreak() -> Int {
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
                    if completion.value(forKey: "excitementCompleted") as? Bool ?? false {
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
            print("Error calculating excitement streak: \(error)")
            return 0
        }
    }
    
    // MARK: - Highlight Methods
    
    func markHighlightCompleted() {
        let context = persistenceController.container.viewContext
        let today = startOfDay()
        
        let fetchRequest: NSFetchRequest<DailyCompletion> = DailyCompletion.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "date >= %@ AND date < %@",
                                            today as NSDate,
                                            Calendar.current.date(byAdding: .day, value: 1, to: today)! as NSDate)
        
        do {
            let results = try context.fetch(fetchRequest)
            let todayCompletion = results.first ?? createDefaultCompletion(context: context, date: today)
            
            todayCompletion.setValue(true, forKey: "highlightCompleted")
            todayHighlightCompleted = true
            
            try context.save()
            calculateStreaks()
        } catch {
            print("Error marking highlight completion: \(error)")
        }
    }
    
    func saveHighlightItems(_ items: [String]) {
        let context = persistenceController.container.viewContext
        let today = startOfDay()
        
        let fetchRequest: NSFetchRequest<DailyCompletion> = DailyCompletion.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "date >= %@ AND date < %@",
                                            today as NSDate,
                                            Calendar.current.date(byAdding: .day, value: 1, to: today)! as NSDate)
        
        do {
            let results = try context.fetch(fetchRequest)
            let todayCompletion = results.first ?? createDefaultCompletion(context: context, date: today)
            
            if let jsonData = try? JSONEncoder().encode(items),
               let jsonString = String(data: jsonData, encoding: .utf8) {
                todayCompletion.setValue(jsonString, forKey: "highlightItems")
            }
            
            try context.save()
        } catch {
            print("Error saving highlight items: \(error)")
        }
    }
    
    func loadTodayHighlightItems() -> [String]? {
        let context = persistenceController.container.viewContext
        let today = startOfDay()
        
        let fetchRequest: NSFetchRequest<DailyCompletion> = DailyCompletion.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "date >= %@ AND date < %@",
                                            today as NSDate,
                                            Calendar.current.date(byAdding: .day, value: 1, to: today)! as NSDate)
        
        do {
            let results = try context.fetch(fetchRequest)
            if let todayCompletion = results.first,
               let jsonString = todayCompletion.value(forKey: "highlightItems") as? String,
               let jsonData = jsonString.data(using: .utf8),
               let items = try? JSONDecoder().decode([String].self, from: jsonData) {
                return items
            }
        } catch {
            print("Error loading highlight items: \(error)")
        }
        
        return nil
    }
    
    // MARK: - Learning Methods
    
    func markLearningCompleted() {
        let context = persistenceController.container.viewContext
        let today = startOfDay()
        
        let fetchRequest: NSFetchRequest<DailyCompletion> = DailyCompletion.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "date >= %@ AND date < %@",
                                            today as NSDate,
                                            Calendar.current.date(byAdding: .day, value: 1, to: today)! as NSDate)
        
        do {
            let results = try context.fetch(fetchRequest)
            let todayCompletion = results.first ?? createDefaultCompletion(context: context, date: today)
            
            todayCompletion.setValue(true, forKey: "learningCompleted")
            todayLearningCompleted = true
            
            try context.save()
            calculateStreaks()
        } catch {
            print("Error marking learning completion: \(error)")
        }
    }
    
    func saveLearningItems(_ items: [String]) {
        let context = persistenceController.container.viewContext
        let today = startOfDay()
        
        let fetchRequest: NSFetchRequest<DailyCompletion> = DailyCompletion.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "date >= %@ AND date < %@",
                                            today as NSDate,
                                            Calendar.current.date(byAdding: .day, value: 1, to: today)! as NSDate)
        
        do {
            let results = try context.fetch(fetchRequest)
            let todayCompletion = results.first ?? createDefaultCompletion(context: context, date: today)
            
            if let jsonData = try? JSONEncoder().encode(items),
               let jsonString = String(data: jsonData, encoding: .utf8) {
                todayCompletion.setValue(jsonString, forKey: "learningItems")
            }
            
            try context.save()
        } catch {
            print("Error saving learning items: \(error)")
        }
    }
    
    func loadTodayLearningItems() -> [String]? {
        let context = persistenceController.container.viewContext
        let today = startOfDay()
        
        let fetchRequest: NSFetchRequest<DailyCompletion> = DailyCompletion.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "date >= %@ AND date < %@",
                                            today as NSDate,
                                            Calendar.current.date(byAdding: .day, value: 1, to: today)! as NSDate)
        
        do {
            let results = try context.fetch(fetchRequest)
            if let todayCompletion = results.first,
               let jsonString = todayCompletion.value(forKey: "learningItems") as? String,
               let jsonData = jsonString.data(using: .utf8),
               let items = try? JSONDecoder().decode([String].self, from: jsonData) {
                return items
            }
        } catch {
            print("Error loading learning items: \(error)")
        }
        
        return nil
    }
    
    // MARK: - Excitement Methods
    
    func markExcitementCompleted() {
        let context = persistenceController.container.viewContext
        let today = startOfDay()
        
        let fetchRequest: NSFetchRequest<DailyCompletion> = DailyCompletion.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "date >= %@ AND date < %@",
                                            today as NSDate,
                                            Calendar.current.date(byAdding: .day, value: 1, to: today)! as NSDate)
        
        do {
            let results = try context.fetch(fetchRequest)
            let todayCompletion = results.first ?? createDefaultCompletion(context: context, date: today)
            
            todayCompletion.setValue(true, forKey: "excitementCompleted")
            todayExcitementCompleted = true
            
            try context.save()
            calculateStreaks()
        } catch {
            print("Error marking excitement completion: \(error)")
        }
    }
    
    func saveExcitementItems(_ items: [String]) {
        let context = persistenceController.container.viewContext
        let today = startOfDay()
        
        let fetchRequest: NSFetchRequest<DailyCompletion> = DailyCompletion.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "date >= %@ AND date < %@",
                                            today as NSDate,
                                            Calendar.current.date(byAdding: .day, value: 1, to: today)! as NSDate)
        
        do {
            let results = try context.fetch(fetchRequest)
            let todayCompletion = results.first ?? createDefaultCompletion(context: context, date: today)
            
            if let jsonData = try? JSONEncoder().encode(items),
               let jsonString = String(data: jsonData, encoding: .utf8) {
                todayCompletion.setValue(jsonString, forKey: "excitementItems")
            }
            
            try context.save()
        } catch {
            print("Error saving excitement items: \(error)")
        }
    }
    
    func loadTodayExcitementItems() -> [String]? {
        let context = persistenceController.container.viewContext
        let today = startOfDay()
        
        let fetchRequest: NSFetchRequest<DailyCompletion> = DailyCompletion.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "date >= %@ AND date < %@",
                                            today as NSDate,
                                            Calendar.current.date(byAdding: .day, value: 1, to: today)! as NSDate)
        
        do {
            let results = try context.fetch(fetchRequest)
            if let todayCompletion = results.first,
               let jsonString = todayCompletion.value(forKey: "excitementItems") as? String,
               let jsonData = jsonString.data(using: .utf8),
               let items = try? JSONDecoder().decode([String].self, from: jsonData) {
                return items
            }
        } catch {
            print("Error loading excitement items: \(error)")
        }
        
        return nil
    }
    
    // MARK: - Helper Method
    
    private func createDefaultCompletion(context: NSManagedObjectContext, date: Date) -> DailyCompletion {
        let completion = DailyCompletion(context: context)
        completion.date = date
        completion.boxBreathingCompleted = false
        completion.meditationCompleted = false
        completion.coherentBreathingCompleted = false
        completion.bodyScanCompleted = false
        completion.kegelExerciseCompleted = false
        completion.gratitudeCompleted = false
        completion.setValue(nil, forKey: "gratitudeItems")
        completion.setValue(false, forKey: "affirmationCompleted")
        completion.setValue(nil, forKey: "affirmationItems")
        completion.setValue(false, forKey: "greatDayCompleted")
        completion.setValue(nil, forKey: "greatDayItems")
        completion.setValue(false, forKey: "highlightCompleted")
        completion.setValue(nil, forKey: "highlightItems")
        completion.setValue(false, forKey: "learningCompleted")
        completion.setValue(nil, forKey: "learningItems")
        completion.setValue(false, forKey: "excitementCompleted")
        completion.setValue(nil, forKey: "excitementItems")
        return completion
    }
    
    // MARK: - Composite Journal Streaks
    
    private func calculateMorningJournalStreak() -> Int {
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
                    let gratitudeComplete = completion.value(forKey: "gratitudeCompleted") as? Bool ?? false
                    let affirmationComplete = completion.value(forKey: "affirmationCompleted") as? Bool ?? false
                    let greatDayComplete = completion.value(forKey: "greatDayCompleted") as? Bool ?? false
                    
                    if gratitudeComplete && affirmationComplete && greatDayComplete {
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
            print("Error calculating morning journal streak: \(error)")
            return 0
        }
    }
    
    private func calculateNightJournalStreak() -> Int {
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
                    let highlightComplete = completion.value(forKey: "highlightCompleted") as? Bool ?? false
                    let learningComplete = completion.value(forKey: "learningCompleted") as? Bool ?? false
                    let excitementComplete = completion.value(forKey: "excitementCompleted") as? Bool ?? false
                    
                    if highlightComplete && learningComplete && excitementComplete {
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
            print("Error calculating night journal streak: \(error)")
            return 0
        }
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
