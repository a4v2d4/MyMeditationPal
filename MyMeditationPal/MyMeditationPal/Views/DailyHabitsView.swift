//
//  DailyHabitsView.swift
//  MyMeditationPal
//
//  Created by Aaron Van Doren on 1/20/26.
//

import SwiftUI

struct DailyHabitsView: View {
    @ObservedObject var viewModel: MeditationViewModel
    @EnvironmentObject var settings: AppSettings
    @Environment(\.dismiss) private var dismiss
    
    @State private var habits: [DailyHabit] = DailyHabitsView.defaultHabits
    
    // Fixed UUIDs ensure streak tracking works correctly across days.
    static let defaultHabits: [DailyHabit] = [
        DailyHabit(id: UUID(uuidString: "A1B2C3D4-0001-0000-0000-000000000001")!, name: "Morning electrolytes", isCompleted: false),
        DailyHabit(id: UUID(uuidString: "A1B2C3D4-0001-0000-0000-000000000002")!, name: "Brush Teeth", isCompleted: false),
        DailyHabit(id: UUID(uuidString: "A1B2C3D4-0001-0000-0000-000000000003")!, name: "Cold Shower", isCompleted: false),
        DailyHabit(id: UUID(uuidString: "A1B2C3D4-0001-0000-0000-000000000004")!, name: "Direct Sunlight Walk", isCompleted: false),
        DailyHabit(id: UUID(uuidString: "A1B2C3D4-0001-0000-0000-000000000005")!, name: "Non-fiction book/audiobook for 15+ min", isCompleted: false),
        DailyHabit(id: UUID(uuidString: "A1B2C3D4-0001-0000-0000-000000000006")!, name: "30+ min. exercise (lifting, running, etc.)", isCompleted: false),
        DailyHabit(id: UUID(uuidString: "A1B2C3D4-0001-0000-0000-000000000007")!, name: "Relax Psoas w/ feet elevated for 15+ min", isCompleted: false),
        DailyHabit(id: UUID(uuidString: "A1B2C3D4-0001-0000-0000-000000000008")!, name: "Creatine Supplement", isCompleted: false),
        DailyHabit(id: UUID(uuidString: "A1B2C3D4-0001-0000-0000-000000000009")!, name: "Magnesium Supplement", isCompleted: false)
    ]
    
    @State private var habitStreaks: [UUID: Int] = [:]
    @State private var showingCongratulations = false

    private var enabledHabits: [DailyHabit] {
        habits.filter { settings.isHabitEnabled($0.id) }
    }

    var allHabitsCompleted: Bool {
        enabledHabits.allSatisfy { $0.isCompleted }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Theme.lightGray.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header
                    headerView
                    
                    ScrollView {
                        VStack(spacing: Theme.spacing) {
                            // Progress card
                            progressCard
                            
                            // Habits list
                            VStack(spacing: 12) {
                                ForEach($habits) { $habit in
                                    if settings.isHabitEnabled(habit.id) {
                                        HabitCheckboxView(
                                            habit: $habit,
                                            streak: habitStreaks[habit.id] ?? 0,
                                            onToggle: {
                                                handleHabitToggle()
                                            }
                                        )
                                    }
                                }
                            }
                            .padding(.horizontal, Theme.spacing)
                            .padding(.bottom, 100)
                        }
                        .padding(.top, Theme.spacing)
                    }
                    
                    // Bottom action button
                    if allHabitsCompleted {
                        completeButton
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                    .foregroundColor(Theme.primaryOrange)
                }
            }
            .fullScreenCover(isPresented: $showingCongratulations) {
                DailyHabitsCongratulationsView(
                    streak: viewModel.dailyHabitsStreak,
                    onDismiss: {
                        showingCongratulations = false
                        dismiss()
                    }
                )
            }
            .onAppear {
                loadHabits()
                loadStreaks()
            }
        }
    }
    
    private var headerView: some View {
        VStack(spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 40))
                .foregroundColor(Theme.primaryOrange)
            
            Text("Daily Habits")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(Theme.textPrimary)
            
            Text("Build your daily routine")
                .font(.system(size: 16))
                .foregroundColor(Theme.textSecondary)
        }
        .padding(.vertical, Theme.largePadding)
        .frame(maxWidth: .infinity)
        .background(Color.white)
    }
    
    private var progressCard: some View {
        let completedCount = enabledHabits.filter { $0.isCompleted }.count
        let totalCount = enabledHabits.count
        let progress = Double(completedCount) / Double(totalCount)
        
        return VStack(spacing: 12) {
            HStack {
                Text("Progress")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(Theme.textPrimary)
                
                Spacer()
                
                Text("\(completedCount) / \(totalCount)")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(Theme.textSecondary)
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Theme.mediumGray)
                        .frame(height: 12)
                    
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Theme.successGreen)
                        .frame(width: geometry.size.width * progress, height: 12)
                        .animation(.spring(response: 0.3), value: progress)
                }
            }
            .frame(height: 12)
        }
        .padding(Theme.spacing)
        .background(Color.white)
        .cornerRadius(Theme.cardCornerRadius)
        .shadow(color: Color.black.opacity(0.06), radius: Theme.cardShadowRadius, x: 0, y: 4)
        .padding(.horizontal, Theme.spacing)
    }
    
    private var completeButton: some View {
        VStack(spacing: 0) {
            Divider()
            
            Button(action: {
                saveAndComplete()
            }) {
                Text("Complete Daily Habits")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Theme.successGreen)
                    .cornerRadius(Theme.cardCornerRadius)
                    .padding(.horizontal, Theme.spacing)
                    .padding(.vertical, Theme.spacing)
            }
        }
        .background(Color.white)
    }
    
    private func handleHabitToggle() {
        saveHabits()
    }
    
    private func loadHabits() {
        if let savedHabits = viewModel.loadTodayDailyHabits() {
            habits = savedHabits
        }
    }
    
    private func loadStreaks() {
        habitStreaks = viewModel.calculateAllIndividualHabitStreaks(for: habits)
    }
    
    private func saveHabits() {
        viewModel.saveDailyHabits(habits)
        // Update streaks after saving
        loadStreaks()
    }
    
    private func saveAndComplete() {
        saveHabits()
        viewModel.markDailyHabitsCompleted()
        showingCongratulations = true
    }
}

struct DailyHabit: Identifiable, Codable {
    let id: UUID
    var name: String
    var isCompleted: Bool
    
    init(id: UUID = UUID(), name: String, isCompleted: Bool) {
        self.id = id
        self.name = name
        self.isCompleted = isCompleted
    }
}

struct HabitCheckboxView: View {
    @Binding var habit: DailyHabit
    let streak: Int
    let onToggle: () -> Void
    
    private var streakColor: Color {
        switch streak {
        case 0: return Color.gray.opacity(0.5)
        case 1...6: return .orange
        case 7...29: return Color(red: 1.0, green: 0.6, blue: 0.0)
        default: return Color(red: 0.9, green: 0.3, blue: 0.0)
        }
    }
    
    private var streakLabel: String {
        streak == 0 ? "Start streak" : "\(streak) day\(streak == 1 ? "" : "s")"
    }
    
    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.3)) {
                habit.isCompleted.toggle()
                onToggle()
            }
        }) {
            HStack(spacing: Theme.spacing) {
                // Checkbox
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(habit.isCompleted ? Theme.successGreen : Theme.mediumGray, lineWidth: 2)
                        .frame(width: 28, height: 28)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(habit.isCompleted ? Theme.successGreen : Color.clear)
                        )
                    
                    if habit.isCompleted {
                        Image(systemName: "checkmark")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
                
                // Habit name
                VStack(alignment: .leading, spacing: 4) {
                    Text(habit.name)
                        .font(.system(size: 16))
                        .foregroundColor(habit.isCompleted ? Theme.textSecondary : Theme.textPrimary)
                        .strikethrough(habit.isCompleted, color: Theme.textSecondary)
                }
                
                Spacer()
                
                // Streak badge
                HStack(spacing: 3) {
                    Image(systemName: streak == 0 ? "flame" : "flame.fill")
                        .font(.system(size: 12))
                        .foregroundColor(streakColor)
                    
                    Text(streakLabel)
                        .font(.system(size: 12, weight: streak == 0 ? .regular : .semibold))
                        .foregroundColor(streakColor)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(streakColor.opacity(0.1))
                .cornerRadius(10)
            }
            .padding(Theme.spacing)
            .background(Color.white)
            .cornerRadius(Theme.cardCornerRadius)
            .shadow(color: Color.black.opacity(0.06), radius: Theme.cardShadowRadius, x: 0, y: 4)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    DailyHabitsView(viewModel: MeditationViewModel(persistenceController: .preview))
        .environmentObject(AppSettings())
}
