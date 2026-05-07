//
//  CalendarHistoryView.swift
//  MyMeditationPal
//
//  Created by Aaron Van Doren on 1/18/26.
//

import SwiftUI

// MARK: - Identifiable Date Wrapper

struct IdentifiableDate: Identifiable {
    let id = UUID()
    let date: Date
}

// MARK: - Calendar History View

struct CalendarHistoryView: View {
    @ObservedObject var viewModel: MeditationViewModel
    @Environment(\.dismiss) var dismiss
    
    @State private var currentMonth = Date()
    @State private var selectedDate: IdentifiableDate?
    
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
                                    let isFuture = date > Date()
                                    DayCell(
                                        date: date,
                                        boxBreathingCompleted: isCompleted(date: date, type: .boxBreathing),
                                        meditationCompleted: isCompleted(date: date, type: .meditation(duration: 10)),
                                        coherentBreathingCompleted: isCompleted(date: date, type: .coherentBreathing(duration: 5)),
                                        bodyScanCompleted: isCompleted(date: date, type: .bodyScan),
                                        kegelExerciseCompleted: isCompleted(date: date, type: .kegelExercise),
                                        morningJournalCompleted: isMorningJournalCompleted(date: date),
                                        nightJournalCompleted: isNightJournalCompleted(date: date),
                                        dailyHabitsCompleted: isDailyHabitsCompleted(date: date),
                                        isToday: Calendar.current.isDateInToday(date),
                                        onTap: isFuture ? nil : { selectedDate = IdentifiableDate(date: date) }
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
                            LegendItem(color: Color(red: 0.8, green: 0.5, blue: 0.6), text: "Kegel")
                            LegendItem(color: Color(red: 0.95, green: 0.75, blue: 0.3), text: "Morning")
                        }
                        HStack(spacing: 16) {
                            LegendItem(color: Color(red: 0.5, green: 0.4, blue: 0.7), text: "Night")
                            LegendItem(color: Color(red: 0.3, green: 0.7, blue: 0.9), text: "Habits")
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
            .sheet(item: $selectedDate) { identifiableDate in
                DayDetailView(viewModel: viewModel, date: identifiableDate.date)
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
                case .meditation(_):
                    return completion.meditationCompleted
                case .coherentBreathing(_):
                    return completion.coherentBreathingCompleted
                case .bodyScan:
                    return completion.bodyScanCompleted
                case .kegelExercise:
                    return completion.kegelExerciseCompleted
                }
            }
        }
        return false
    }
    
    private func isMorningJournalCompleted(date: Date) -> Bool {
        let calendar = Calendar.current
        for completion in completions {
            if let completionDate = completion.date,
               calendar.isDate(completionDate, inSameDayAs: date) {
                let gratitudeComplete = completion.value(forKey: "gratitudeCompleted") as? Bool ?? false
                let affirmationComplete = completion.value(forKey: "affirmationCompleted") as? Bool ?? false
                let greatDayComplete = completion.value(forKey: "greatDayCompleted") as? Bool ?? false
                return gratitudeComplete && affirmationComplete && greatDayComplete
            }
        }
        return false
    }
    
    private func isNightJournalCompleted(date: Date) -> Bool {
        let calendar = Calendar.current
        for completion in completions {
            if let completionDate = completion.date,
               calendar.isDate(completionDate, inSameDayAs: date) {
                let highlightComplete = completion.value(forKey: "highlightCompleted") as? Bool ?? false
                let learningComplete = completion.value(forKey: "learningCompleted") as? Bool ?? false
                let excitementComplete = completion.value(forKey: "excitementCompleted") as? Bool ?? false
                return highlightComplete && learningComplete && excitementComplete
            }
        }
        return false
    }
    
    private func isDailyHabitsCompleted(date: Date) -> Bool {
        let calendar = Calendar.current
        for completion in completions {
            if let completionDate = completion.date,
               calendar.isDate(completionDate, inSameDayAs: date) {
                return completion.value(forKey: "dailyHabitsCompleted") as? Bool ?? false
            }
        }
        return false
    }
}

// MARK: - Day Cell

struct DayCell: View {
    let date: Date
    let boxBreathingCompleted: Bool
    let meditationCompleted: Bool
    let coherentBreathingCompleted: Bool
    let bodyScanCompleted: Bool
    let kegelExerciseCompleted: Bool
    let morningJournalCompleted: Bool
    let nightJournalCompleted: Bool
    let dailyHabitsCompleted: Bool
    let isToday: Bool
    var onTap: (() -> Void)? = nil
    
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
                            .fill(kegelExerciseCompleted ? Color(red: 0.8, green: 0.5, blue: 0.6) : Theme.mediumGray.opacity(0.5))
                            .frame(width: 6, height: 6)
                        
                        Circle()
                            .fill(morningJournalCompleted ? Color(red: 0.95, green: 0.75, blue: 0.3) : Theme.mediumGray.opacity(0.5))
                            .frame(width: 6, height: 6)
                    }
                    
                    HStack(spacing: 2) {
                        Circle()
                            .fill(nightJournalCompleted ? Color(red: 0.5, green: 0.4, blue: 0.7) : Theme.mediumGray.opacity(0.5))
                            .frame(width: 6, height: 6)
                        
                        Circle()
                            .fill(dailyHabitsCompleted ? Color(red: 0.3, green: 0.7, blue: 0.9) : Theme.mediumGray.opacity(0.5))
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
        .onTapGesture {
            onTap?()
        }
    }
}

// MARK: - Legend Item

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

// MARK: - Day Detail View

struct DayDetailView: View {
    @ObservedObject var viewModel: MeditationViewModel
    let date: Date
    @Environment(\.dismiss) var dismiss
    
    @State private var completion: DailyCompletion?
    
    // MARK: - Computed booleans
    
    private var boxBreathingCompleted: Bool { completion?.boxBreathingCompleted ?? false }
    private var meditationCompleted: Bool { completion?.meditationCompleted ?? false }
    private var coherentBreathingCompleted: Bool { completion?.coherentBreathingCompleted ?? false }
    private var bodyScanCompleted: Bool { completion?.bodyScanCompleted ?? false }
    private var kegelCompleted: Bool { completion?.kegelExerciseCompleted ?? false }
    private var gratitudeCompleted: Bool { completion?.value(forKey: "gratitudeCompleted") as? Bool ?? false }
    private var affirmationCompleted: Bool { completion?.value(forKey: "affirmationCompleted") as? Bool ?? false }
    private var greatDayCompleted: Bool { completion?.value(forKey: "greatDayCompleted") as? Bool ?? false }
    private var highlightCompleted: Bool { completion?.value(forKey: "highlightCompleted") as? Bool ?? false }
    private var learningCompleted: Bool { completion?.value(forKey: "learningCompleted") as? Bool ?? false }
    private var excitementCompleted: Bool { completion?.value(forKey: "excitementCompleted") as? Bool ?? false }
    
    // MARK: - Item loading
    
    private func loadStringItems(key: String) -> [String] {
        guard let completion = completion,
              let jsonString = completion.value(forKey: key) as? String,
              let jsonData = jsonString.data(using: .utf8),
              let items = try? JSONDecoder().decode([String].self, from: jsonData) else {
            return []
        }
        return items
    }
    
    private var gratitudeItems: [String] { loadStringItems(key: "gratitudeItems") }
    private var affirmationItems: [String] { loadStringItems(key: "affirmationItems") }
    private var greatDayItems: [String] { loadStringItems(key: "greatDayItems") }
    private var highlightItems: [String] { loadStringItems(key: "highlightItems") }
    private var learningItems: [String] { loadStringItems(key: "learningItems") }
    private var excitementItems: [String] { loadStringItems(key: "excitementItems") }
    
    private var habits: [DailyHabit] {
        guard let completion = completion,
              let jsonString = completion.value(forKey: "dailyHabitsItems") as? String,
              let jsonData = jsonString.data(using: .utf8),
              let habits = try? JSONDecoder().decode([DailyHabit].self, from: jsonData) else {
            return []
        }
        return habits
    }
    
    // MARK: - Section visibility
    
    private var hasMorningJournal: Bool {
        gratitudeCompleted || affirmationCompleted || greatDayCompleted
    }
    
    private var hasNightJournal: Bool {
        highlightCompleted || learningCompleted || excitementCompleted
    }
    
    private var hasAnyActivity: Bool {
        boxBreathingCompleted || meditationCompleted || coherentBreathingCompleted ||
        bodyScanCompleted || kegelCompleted || hasMorningJournal || hasNightJournal ||
        !habits.isEmpty
    }
    
    private var dateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d"
        return formatter.string(from: date)
    }
    
    private var completedExercisesCount: Int {
        [boxBreathingCompleted, meditationCompleted, coherentBreathingCompleted,
         bodyScanCompleted, kegelCompleted].filter { $0 }.count
    }
    
    // MARK: - Body
    
    var body: some View {
        NavigationView {
            ZStack {
                Theme.lightGray.ignoresSafeArea()
                
                if hasAnyActivity {
                    ScrollView {
                        VStack(spacing: 16) {
                            exercisesCard
                            if hasMorningJournal { morningJournalCard }
                            if hasNightJournal { nightJournalCard }
                            if !habits.isEmpty { dailyHabitsCard }
                        }
                        .padding()
                    }
                } else {
                    VStack(spacing: 12) {
                        Image(systemName: "moon.stars")
                            .font(.system(size: 52))
                            .foregroundColor(Theme.textSecondary.opacity(0.3))
                        Text("Nothing logged this day")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(Theme.textSecondary)
                    }
                }
            }
            .navigationTitle(dateString)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(Theme.primaryOrange)
                }
            }
        }
        .onAppear {
            completion = viewModel.fetchCompletion(for: date)
        }
    }
    
    // MARK: - Exercises Card
    
    private var exercisesCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Image(systemName: "figure.mind.and.body")
                    .foregroundColor(Theme.primaryOrange)
                Text("Exercises")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(Theme.textPrimary)
                Spacer()
                Text("\(completedExercisesCount)/5")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(completedExercisesCount > 0 ? Theme.primaryOrange : Theme.textSecondary)
            }
            .padding(.bottom, 14)
            
            VStack(spacing: 0) {
                ExerciseRow(name: "Box Breathing", duration: "1 min", completed: boxBreathingCompleted, color: Theme.deepBlue)
                Divider().padding(.vertical, 10)
                ExerciseRow(name: "Meditation", duration: "5 or 10 min", completed: meditationCompleted, color: Theme.primaryOrange)
                Divider().padding(.vertical, 10)
                ExerciseRow(name: "Coherent Breathing", duration: "5 or 10 min", completed: coherentBreathingCompleted, color: Color(red: 0.4, green: 0.6, blue: 0.8))
                Divider().padding(.vertical, 10)
                ExerciseRow(name: "Body Scan", duration: "10 min", completed: bodyScanCompleted, color: Color(red: 0.6, green: 0.4, blue: 0.8))
                Divider().padding(.vertical, 10)
                ExerciseRow(name: "Kegel Exercise", duration: "2 min", completed: kegelCompleted, color: Color(red: 0.8, green: 0.5, blue: 0.6))
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 4)
    }
    
    // MARK: - Morning Journal Card
    
    private var morningJournalCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Image(systemName: "sun.horizon.fill")
                    .foregroundColor(Color(red: 0.95, green: 0.75, blue: 0.3))
                Text("Morning Journal")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(Theme.textPrimary)
            }
            
            if gratitudeCompleted {
                DetailJournalSection(
                    title: "Gratitude",
                    items: gratitudeItems,
                    color: Color(red: 0.95, green: 0.75, blue: 0.3)
                )
            }
            
            if affirmationCompleted {
                if gratitudeCompleted { Divider() }
                DetailJournalSection(
                    title: "Affirmations",
                    items: affirmationItems,
                    color: Color(red: 0.95, green: 0.75, blue: 0.3)
                )
            }
            
            if greatDayCompleted {
                if gratitudeCompleted || affirmationCompleted { Divider() }
                DetailJournalSection(
                    title: "What Would Make Today Great",
                    items: greatDayItems,
                    color: Color(red: 0.95, green: 0.75, blue: 0.3)
                )
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 4)
    }
    
    // MARK: - Night Journal Card
    
    private var nightJournalCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Image(systemName: "moon.stars.fill")
                    .foregroundColor(Color(red: 0.5, green: 0.4, blue: 0.7))
                Text("Night Journal")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(Theme.textPrimary)
            }
            
            if highlightCompleted {
                DetailJournalSection(
                    title: "Today's Highlights",
                    items: highlightItems,
                    color: Color(red: 0.5, green: 0.4, blue: 0.7)
                )
            }
            
            if learningCompleted {
                if highlightCompleted { Divider() }
                DetailJournalSection(
                    title: "What I Learned",
                    items: learningItems,
                    color: Color(red: 0.5, green: 0.4, blue: 0.7)
                )
            }
            
            if excitementCompleted {
                if highlightCompleted || learningCompleted { Divider() }
                DetailJournalSection(
                    title: "Tomorrow I'm Excited For",
                    items: excitementItems,
                    color: Color(red: 0.5, green: 0.4, blue: 0.7)
                )
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 4)
    }
    
    // MARK: - Daily Habits Card
    
    private var dailyHabitsCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Image(systemName: "checklist")
                    .foregroundColor(Color(red: 0.3, green: 0.7, blue: 0.9))
                Text("Daily Habits")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(Theme.textPrimary)
                Spacer()
                let done = habits.filter { $0.isCompleted }.count
                Text("\(done)/\(habits.count)")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Color(red: 0.3, green: 0.7, blue: 0.9))
            }
            
            VStack(spacing: 10) {
                ForEach(habits) { habit in
                    HStack(spacing: 12) {
                        Image(systemName: habit.isCompleted ? "checkmark.circle.fill" : "circle")
                            .font(.system(size: 20))
                            .foregroundColor(habit.isCompleted ? Theme.successGreen : Theme.mediumGray)
                        Text(habit.name)
                            .font(.system(size: 15))
                            .foregroundColor(habit.isCompleted ? Theme.textSecondary : Theme.textPrimary)
                            .strikethrough(habit.isCompleted, color: Theme.textSecondary)
                        Spacer()
                    }
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 4)
    }
}

// MARK: - Exercise Row

struct ExerciseRow: View {
    let name: String
    let duration: String
    let completed: Bool
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(completed ? color : Theme.mediumGray.opacity(0.3))
                .frame(width: 10, height: 10)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(completed ? Theme.textPrimary : Theme.textSecondary)
                Text(duration)
                    .font(.system(size: 12))
                    .foregroundColor(Theme.textSecondary)
            }
            
            Spacer()
            
            Image(systemName: completed ? "checkmark.circle.fill" : "circle")
                .font(.system(size: 22))
                .foregroundColor(completed ? color : Theme.mediumGray.opacity(0.4))
        }
    }
}

// MARK: - Detail Journal Section

struct DetailJournalSection: View {
    let title: String
    let items: [String]
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(color)
                .textCase(.uppercase)
                .tracking(0.5)
            
            if items.isEmpty {
                Text("Completed")
                    .font(.system(size: 14))
                    .foregroundColor(Theme.textSecondary)
                    .italic()
            } else {
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(items, id: \.self) { item in
                        HStack(alignment: .top, spacing: 8) {
                            Circle()
                                .fill(color.opacity(0.6))
                                .frame(width: 5, height: 5)
                                .padding(.top, 6)
                            Text(item)
                                .font(.system(size: 15))
                                .foregroundColor(Theme.textPrimary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
            }
        }
    }
}

#Preview {
    CalendarHistoryView(viewModel: MeditationViewModel())
}
