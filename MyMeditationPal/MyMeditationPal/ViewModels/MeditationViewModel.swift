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
    
    @Published var todayMeditationCompleted: Bool = false
    @Published var todayBreathingCompleted: Bool = false
    @Published var meditationStreak: Int = 0
    @Published var breathingStreak: Int = 0
    
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
                todayMeditationCompleted = todayCompletion.meditationCompleted
                todayBreathingCompleted = todayCompletion.breathingCompleted
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
        completion.meditationCompleted = false
        completion.breathingCompleted = false
        
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
                completion.meditationCompleted = false
                completion.breathingCompleted = false
                return completion
            }()
            
            switch exerciseType {
            case .meditation:
                todayCompletion.meditationCompleted = true
                todayMeditationCompleted = true
            case .breathing:
                todayCompletion.breathingCompleted = true
                todayBreathingCompleted = true
            }
            
            try context.save()
            calculateStreaks()
        } catch {
            print("Error marking completion: \(error)")
        }
    }
    
    // MARK: - Calculate Streaks
    
    func calculateStreaks() {
        meditationStreak = calculateStreak(for: \.meditationCompleted)
        breathingStreak = calculateStreak(for: \.breathingCompleted)
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
