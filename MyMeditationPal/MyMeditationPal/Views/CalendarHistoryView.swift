//
//  CalendarHistoryView.swift
//  MyMeditationPal
//
//  Created by Aaron Van Doren on 1/18/26.
//

import SwiftUI

struct CalendarHistoryView: View {
    @ObservedObject var viewModel: MeditationViewModel
    @Environment(\.dismiss) var dismiss
    
    @State private var currentMonth = Date()
    
    private var completions: [DailyCompletion] {
        viewModel.fetchAllCompletions()
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Theme.lightGray.ignoresSafeArea()
                
                VStack(spacing: Theme.largePadding) {
                    // Month Navigation
                    HStack {
                        Button(action: previousMonth) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(Theme.primaryOrange)
                        }
                        
                        Spacer()
                        
                        Text(monthYearString)
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(Theme.textPrimary)
                        
                        Spacer()
                        
                        Button(action: nextMonth) {
                            Image(systemName: "chevron.right")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(Theme.primaryOrange)
                        }
                        .disabled(isCurrentMonth)
                        .opacity(isCurrentMonth ? 0.3 : 1.0)
                    }
                    .padding(.horizontal, Theme.largePadding)
                    .padding(.top, Theme.spacing)
                    
                    // Calendar Grid
                    VStack(spacing: Theme.spacing) {
                        // Day headers
                        HStack(spacing: 0) {
                            ForEach(["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"], id: \.self) { day in
                                Text(day)
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(Theme.textSecondary)
                                    .frame(maxWidth: .infinity)
                            }
                        }
                        .padding(.horizontal, Theme.spacing)
                        
                        // Calendar days
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 7), spacing: 12) {
                            ForEach(daysInMonth, id: \.self) { date in
                                if let date = date {
                                    DayCell(
                                        date: date,
                                        boxBreathingCompleted: isCompleted(date: date, type: .boxBreathing),
                                        meditationCompleted: isCompleted(date: date, type: .meditation),
                                        coherentBreathingCompleted: isCompleted(date: date, type: .coherentBreathing),
                                        bodyScanCompleted: isCompleted(date: date, type: .bodyScan),
                                        gratitudeCompleted: isGratitudeCompleted(date: date),
                                        affirmationCompleted: isAffirmationCompleted(date: date),
                                        greatDayCompleted: isGreatDayCompleted(date: date),
                                        highlightCompleted: isHighlightCompleted(date: date),
                                        learningCompleted: isLearningCompleted(date: date),
                                        excitementCompleted: isExcitementCompleted(date: date),
                                        isToday: Calendar.current.isDateInToday(date)
                                    )
                                } else {
                                    Color.clear
                                        .frame(height: 60)
                                }
                            }
                        }
                        .padding(.horizontal, Theme.spacing)
                    }
                    
                    // Legend
                    VStack(spacing: 8) {
                        HStack(spacing: 16) {
                            LegendItem(color: Theme.deepBlue, text: "Box Breath")
                            LegendItem(color: Theme.primaryOrange, text: "Meditation")
                        }
                        HStack(spacing: 16) {
                            LegendItem(color: Color(red: 0.4, green: 0.6, blue: 0.8), text: "Coherent")
                            LegendItem(color: Color(red: 0.6, green: 0.4, blue: 0.8), text: "Body Scan")
                        }
                        HStack(spacing: 16) {
                            LegendItem(color: Color(red: 0.85, green: 0.65, blue: 0.75), text: "Gratitude")
                            LegendItem(color: Color(red: 0.3, green: 0.7, blue: 0.6), text: "Affirmation")
                        }
                        HStack(spacing: 16) {
                            LegendItem(color: Color(red: 0.95, green: 0.75, blue: 0.3), text: "Great Day")
                            LegendItem(color: Color(red: 1.0, green: 0.6, blue: 0.4), text: "Highlights")
                        }
                        HStack(spacing: 16) {
                            LegendItem(color: Color(red: 0.5, green: 0.4, blue: 0.7), text: "Learning")
                            LegendItem(color: Color(red: 0.4, green: 0.75, blue: 0.95), text: "Excitement")
                        }
                    }
                    .padding(.top, Theme.spacing)
                    
                    Spacer()
                }
            }
            .navigationTitle("History")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(Theme.primaryOrange)
                }
            }
        }
    }
    
    // MARK: - Helpers
    
    private var monthYearString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: currentMonth)
    }
    
    private var isCurrentMonth: Bool {
        let calendar = Calendar.current
        return calendar.isDate(currentMonth, equalTo: Date(), toGranularity: .month)
    }
    
    private func previousMonth() {
        if let newMonth = Calendar.current.date(byAdding: .month, value: -1, to: currentMonth) {
            currentMonth = newMonth
        }
    }
    
    private func nextMonth() {
        if let newMonth = Calendar.current.date(byAdding: .month, value: 1, to: currentMonth) {
            if newMonth <= Date() {
                currentMonth = newMonth
            }
        }
    }
    
    private var daysInMonth: [Date?] {
        let calendar = Calendar.current
        let interval = calendar.dateInterval(of: .month, for: currentMonth)!
        let firstWeekday = calendar.component(.weekday, from: interval.start)
        let daysCount = calendar.range(of: .day, in: .month, for: currentMonth)!.count
        
        var days: [Date?] = Array(repeating: nil, count: firstWeekday - 1)
        
        for day in 0..<daysCount {
            if let date = calendar.date(byAdding: .day, value: day, to: interval.start) {
                days.append(date)
            }
        }
        
        return days
    }
    
    private func isCompleted(date: Date, type: ExerciseType) -> Bool {
        let calendar = Calendar.current
        for completion in completions {
            if let completionDate = completion.date,
               calendar.isDate(completionDate, inSameDayAs: date) {
                switch type {
                case .boxBreathing:
                    return completion.boxBreathingCompleted
                case .meditation:
                    return completion.meditationCompleted
                case .coherentBreathing:
                    return completion.coherentBreathingCompleted
                case .bodyScan:
                    return completion.bodyScanCompleted
                }
            }
        }
        return false
    }
    
    private func isGratitudeCompleted(date: Date) -> Bool {
        let calendar = Calendar.current
        for completion in completions {
            if let completionDate = completion.date,
               calendar.isDate(completionDate, inSameDayAs: date) {
                return completion.value(forKey: "gratitudeCompleted") as? Bool ?? false
            }
        }
        return false
    }
    
    private func isAffirmationCompleted(date: Date) -> Bool {
        let calendar = Calendar.current
        for completion in completions {
            if let completionDate = completion.date,
               calendar.isDate(completionDate, inSameDayAs: date) {
                return completion.value(forKey: "affirmationCompleted") as? Bool ?? false
            }
        }
        return false
    }
    
    private func isGreatDayCompleted(date: Date) -> Bool {
        let calendar = Calendar.current
        for completion in completions {
            if let completionDate = completion.date,
               calendar.isDate(completionDate, inSameDayAs: date) {
                return completion.value(forKey: "greatDayCompleted") as? Bool ?? false
            }
        }
        return false
    }
    
    private func isHighlightCompleted(date: Date) -> Bool {
        let calendar = Calendar.current
        for completion in completions {
            if let completionDate = completion.date,
               calendar.isDate(completionDate, inSameDayAs: date) {
                return completion.value(forKey: "highlightCompleted") as? Bool ?? false
            }
        }
        return false
    }
    
    private func isLearningCompleted(date: Date) -> Bool {
        let calendar = Calendar.current
        for completion in completions {
            if let completionDate = completion.date,
               calendar.isDate(completionDate, inSameDayAs: date) {
                return completion.value(forKey: "learningCompleted") as? Bool ?? false
            }
        }
        return false
    }
    
    private func isExcitementCompleted(date: Date) -> Bool {
        let calendar = Calendar.current
        for completion in completions {
            if let completionDate = completion.date,
               calendar.isDate(completionDate, inSameDayAs: date) {
                return completion.value(forKey: "excitementCompleted") as? Bool ?? false
            }
        }
        return false
    }
}

struct DayCell: View {
    let date: Date
    let boxBreathingCompleted: Bool
    let meditationCompleted: Bool
    let coherentBreathingCompleted: Bool
    let bodyScanCompleted: Bool
    let gratitudeCompleted: Bool
    let affirmationCompleted: Bool
    let greatDayCompleted: Bool
    let highlightCompleted: Bool
    let learningCompleted: Bool
    let excitementCompleted: Bool
    let isToday: Bool
    
    private var dayNumber: Int {
        Calendar.current.component(.day, from: date)
    }
    
    private var isFuture: Bool {
        date > Date()
    }
    
    var body: some View {
        VStack(spacing: 4) {
            Text("\(dayNumber)")
                .font(.system(size: 16, weight: isToday ? .bold : .medium))
                .foregroundColor(isFuture ? Theme.textSecondary.opacity(0.4) : Theme.textPrimary)
            
            if !isFuture {
                VStack(spacing: 2) {
                    HStack(spacing: 2) {
                        Circle()
                            .fill(boxBreathingCompleted ? Theme.deepBlue : Theme.mediumGray.opacity(0.5))
                            .frame(width: 6, height: 6)
                        
                        Circle()
                            .fill(meditationCompleted ? Theme.primaryOrange : Theme.mediumGray.opacity(0.5))
                            .frame(width: 6, height: 6)
                    }
                    
                    HStack(spacing: 2) {
                        Circle()
                            .fill(coherentBreathingCompleted ? Color(red: 0.4, green: 0.6, blue: 0.8) : Theme.mediumGray.opacity(0.5))
                            .frame(width: 6, height: 6)
                        
                        Circle()
                            .fill(bodyScanCompleted ? Color(red: 0.6, green: 0.4, blue: 0.8) : Theme.mediumGray.opacity(0.5))
                            .frame(width: 6, height: 6)
                    }
                    
                    HStack(spacing: 2) {
                        Circle()
                            .fill(gratitudeCompleted ? Color(red: 0.85, green: 0.65, blue: 0.75) : Theme.mediumGray.opacity(0.5))
                            .frame(width: 6, height: 6)
                        
                        Circle()
                            .fill(affirmationCompleted ? Color(red: 0.3, green: 0.7, blue: 0.6) : Theme.mediumGray.opacity(0.5))
                            .frame(width: 6, height: 6)
                    }
                    
                    HStack(spacing: 2) {
                        Circle()
                            .fill(greatDayCompleted ? Color(red: 0.95, green: 0.75, blue: 0.3) : Theme.mediumGray.opacity(0.5))
                            .frame(width: 6, height: 6)
                        
                        Circle()
                            .fill(highlightCompleted ? Color(red: 1.0, green: 0.6, blue: 0.4) : Theme.mediumGray.opacity(0.5))
                            .frame(width: 6, height: 6)
                    }
                    
                    HStack(spacing: 2) {
                        Circle()
                            .fill(learningCompleted ? Color(red: 0.5, green: 0.4, blue: 0.7) : Theme.mediumGray.opacity(0.5))
                            .frame(width: 6, height: 6)
                        
                        Circle()
                            .fill(excitementCompleted ? Color(red: 0.4, green: 0.75, blue: 0.95) : Theme.mediumGray.opacity(0.5))
                            .frame(width: 6, height: 6)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 60)
        .background(isToday ? Theme.softPeach : Color.white)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isToday ? Theme.primaryOrange : Color.clear, lineWidth: 2)
        )
        .shadow(color: Color.black.opacity(0.04), radius: 4, x: 0, y: 2)
    }
}

struct LegendItem: View {
    let color: Color
    let text: String
    
    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(color)
                .frame(width: 12, height: 12)
            
            Text(text)
                .font(.system(size: 14))
                .foregroundColor(Theme.textSecondary)
        }
    }
}

#Preview {
    CalendarHistoryView(viewModel: MeditationViewModel())
}
