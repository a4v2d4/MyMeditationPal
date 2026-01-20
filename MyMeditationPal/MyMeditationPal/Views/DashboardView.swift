//
//  DashboardView.swift
//  MyMeditationPal
//
//  Created by Aaron Van Doren on 1/18/26.
//

import SwiftUI

struct DashboardView: View {
    @StateObject private var viewModel = MeditationViewModel()
    @State private var showingVideoPlayer: ExerciseType?
    @State private var showingCalendar = false
    @State private var showingMorningJournal = false
    @State private var showingNightJournal = false
    @State private var showingDailyHabits = false
    @State private var showingCoherentBreathingDurationPicker = false
    @State private var showingMeditationDurationPicker = false
    @State private var isStreaksExpanded = false
    
    var body: some View {
        NavigationView {
            mainContent
        }
    }
    
    private var mainContent: some View {
        ZStack {
            Theme.lightGray.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: Theme.spacing) {
                    headerView
                    streakCardsView
                    exerciseCardsView
                    Spacer(minLength: 20)
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showingCalendar = true }) {
                    Image(systemName: "calendar")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(Theme.primaryOrange)
                }
            }
        }
        .fullScreenCover(item: $showingVideoPlayer) { exerciseType in
            VideoPlayerView(exerciseType: exerciseType, viewModel: viewModel)
        }
        .sheet(isPresented: $showingCalendar) {
            CalendarHistoryView(viewModel: viewModel)
        }
        .sheet(isPresented: $showingMorningJournal) {
            MorningJournalView(viewModel: viewModel)
        }
        .sheet(isPresented: $showingNightJournal) {
            NightJournalView(viewModel: viewModel)
        }
        .sheet(isPresented: $showingDailyHabits) {
            DailyHabitsView(viewModel: viewModel)
        }
        .onChange(of: showingDailyHabits) { _, newValue in
            if !newValue {
                // Refresh the view when the sheet is dismissed
                viewModel.loadTodayStatus()
            }
        }
        .confirmationDialog("Choose Duration", isPresented: $showingCoherentBreathingDurationPicker, titleVisibility: .visible) {
            Button("5 Minutes") {
                showingVideoPlayer = .coherentBreathing(duration: 5)
            }
            
            Button("10 Minutes") {
                showingVideoPlayer = .coherentBreathing(duration: 10)
            }
            
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Select the duration for your coherent breathing exercise")
        }
        .confirmationDialog("Choose Duration", isPresented: $showingMeditationDurationPicker, titleVisibility: .visible) {
            Button("5 Minutes") {
                showingVideoPlayer = .meditation(duration: 5)
            }
            
            Button("10 Minutes") {
                showingVideoPlayer = .meditation(duration: 10)
            }
            
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Select the duration for your daily meditation")
        }
        .onAppear {
            viewModel.loadTodayStatus()
        }
    }
    
    private var headerView: some View {
        VStack(spacing: 12) {
            Text("Today's Practice")
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(Theme.textPrimary)
            
            Text(formattedDate)
                .font(.system(size: 16))
                .foregroundColor(Theme.textSecondary)
        }
        .padding(.top, Theme.largePadding)
    }
    
    private var streakCardsView: some View {
        VStack(spacing: 0) {
            // Collapsible header
            Button(action: {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    isStreaksExpanded.toggle()
                }
            }) {
                HStack {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 16))
                        .foregroundColor(Theme.primaryOrange)
                    
                    Text("Streaks & Progress")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(Theme.textPrimary)
                    
                    Spacer()
                    
                    Image(systemName: isStreaksExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Theme.textSecondary)
                }
                .padding(Theme.spacing)
                .background(Color.white)
                .cornerRadius(Theme.cardCornerRadius)
                .shadow(color: Color.black.opacity(0.06), radius: Theme.cardShadowRadius, x: 0, y: 4)
            }
            .buttonStyle(PlainButtonStyle())
            
            // Expandable content
            if isStreaksExpanded {
                VStack(spacing: Theme.spacing) {
                    exerciseStreakCards
                    journalStreakCards
                }
                .padding(.top, Theme.spacing)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(.horizontal, Theme.spacing)
    }
    
    private var exerciseStreakCards: some View {
        Group {
            HStack(spacing: Theme.spacing) {
                StreakCard(
                    title: "Box Breath",
                    streak: viewModel.boxBreathingStreak,
                    color: Theme.deepBlue
                )
                
                StreakCard(
                    title: "Meditation",
                    streak: viewModel.meditationStreak,
                    color: Theme.primaryOrange
                )
            }
            
            HStack(spacing: Theme.spacing) {
                StreakCard(
                    title: "Coherent",
                    streak: viewModel.coherentBreathingStreak,
                    color: Color(red: 0.4, green: 0.6, blue: 0.8)
                )
                
                StreakCard(
                    title: "Body Scan",
                    streak: viewModel.bodyScanStreak,
                    color: Color(red: 0.6, green: 0.4, blue: 0.8)
                )
            }
            
            HStack(spacing: Theme.spacing) {
                StreakCard(
                    title: "Kegel",
                    streak: viewModel.kegelExerciseStreak,
                    color: Color(red: 0.8, green: 0.5, blue: 0.6)
                )
                
                StreakCard(
                    title: "Daily Habits",
                    streak: viewModel.dailyHabitsStreak,
                    color: Color(red: 0.3, green: 0.7, blue: 0.9)
                )
            }
            
            HStack(spacing: Theme.spacing) {
                StreakCard(
                    title: "AM Journal",
                    streak: viewModel.morningJournalStreak,
                    color: Color(red: 0.95, green: 0.75, blue: 0.3)
                )
                
                // Empty space for balance
                StreakCard(
                    title: "",
                    streak: 0,
                    color: Color.clear
                )
                .opacity(0)
            }
        }
    }
    
    private var journalStreakCards: some View {
        Group {
            HStack(spacing: Theme.spacing) {
                StreakCard(
                    title: "PM Journal",
                    streak: viewModel.nightJournalStreak,
                    color: Color(red: 0.5, green: 0.4, blue: 0.7)
                )
            }
        }
    }
    
    private var exerciseCardsView: some View {
        VStack(spacing: 10) {
            topExerciseCards
            journalCards
            bottomExerciseCards
        }
        .padding(.horizontal, Theme.spacing)
    }
    
    private var topExerciseCards: some View {
        Group {
            ExerciseCardView(
                exerciseType: .boxBreathing,
                isCompleted: viewModel.todayBoxBreathingCompleted,
                onTap: {
                    showingVideoPlayer = .boxBreathing
                }
            )
            
            meditationCard
        }
    }
    
    private var journalCards: some View {
        Group {
            MorningJournalCardView(
                isCompleted: viewModel.todayMorningJournalCompleted,
                onTap: {
                    showingMorningJournal = true
                }
            )
            
            DailyHabitsCardView(
                isCompleted: viewModel.todayDailyHabitsCompleted,
                progress: viewModel.getTodayDailyHabitsProgress(),
                onTap: {
                    showingDailyHabits = true
                }
            )
            
            ExerciseCardView(
                exerciseType: .kegelExercise,
                isCompleted: viewModel.todayKegelExerciseCompleted,
                onTap: {
                    showingVideoPlayer = .kegelExercise
                }
            )
            
            NightJournalCardView(
                isCompleted: viewModel.todayNightJournalCompleted,
                onTap: {
                    showingNightJournal = true
                }
            )
        }
    }
    
    private var bottomExerciseCards: some View {
        Group {
            coherentBreathingCard
            
            ExerciseCardView(
                exerciseType: .bodyScan,
                isCompleted: viewModel.todayBodyScanCompleted,
                onTap: {
                    showingVideoPlayer = .bodyScan
                }
            )
        }
    }
    
    private var meditationCard: some View {
        Button(action: {
            showingMeditationDurationPicker = true
        }) {
            HStack(spacing: Theme.spacing) {
                // Icon
                ZStack {
                    Circle()
                        .fill(Theme.primaryOrange.opacity(0.15))
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: "figure.mind.and.body")
                        .font(.system(size: 20))
                        .foregroundColor(Theme.primaryOrange)
                }
                
                // Title and duration
                VStack(alignment: .leading, spacing: 4) {
                    Text("Daily Meditation")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(Theme.textPrimary)
                    
                    Text("Choose 5 or 10 minutes")
                        .font(.system(size: 13))
                        .foregroundColor(Theme.textSecondary)
                }
                
                Spacer()
                
                HStack(spacing: 12) {
                    if viewModel.todayMeditationCompleted {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(Theme.successGreen)
                    }
                    
                    Image(systemName: "play.circle.fill")
                        .font(.system(size: 28))
                        .foregroundColor(viewModel.todayMeditationCompleted ? Theme.successGreen : Theme.primaryOrange)
                }
            }
            .padding(Theme.spacing)
            .background(Color.white)
            .cornerRadius(Theme.cardCornerRadius)
            .shadow(color: Color.black.opacity(0.06), radius: Theme.cardShadowRadius, x: 0, y: 4)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var coherentBreathingCard: some View {
        Button(action: {
            showingCoherentBreathingDurationPicker = true
        }) {
            HStack(spacing: Theme.spacing) {
                // Icon
                ZStack {
                    Circle()
                        .fill(Color(red: 0.4, green: 0.6, blue: 0.8).opacity(0.15))
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: "waveform.path.ecg")
                        .font(.system(size: 20))
                        .foregroundColor(Color(red: 0.4, green: 0.6, blue: 0.8))
                }
                
                // Title and duration
                VStack(alignment: .leading, spacing: 4) {
                    Text("Coherent Breath Exercise")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(Theme.textPrimary)
                    
                    Text("Choose 5 or 10 minutes")
                        .font(.system(size: 13))
                        .foregroundColor(Theme.textSecondary)
                }
                
                Spacer()
                
                HStack(spacing: 12) {
                    if viewModel.todayCoherentBreathingCompleted {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(Theme.successGreen)
                    }
                    
                    Image(systemName: "play.circle.fill")
                        .font(.system(size: 28))
                        .foregroundColor(viewModel.todayCoherentBreathingCompleted ? Theme.successGreen : Color(red: 0.4, green: 0.6, blue: 0.8))
                }
            }
            .padding(Theme.spacing)
            .background(Color.white)
            .cornerRadius(Theme.cardCornerRadius)
            .shadow(color: Color.black.opacity(0.06), radius: Theme.cardShadowRadius, x: 0, y: 4)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d"
        return formatter.string(from: Date())
    }
}

struct StreakCard: View {
    let title: String
    let streak: Int
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text("\(streak)")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(color)
            
            HStack(spacing: 3) {
                Image(systemName: "flame.fill")
                    .font(.system(size: 11))
                    .foregroundColor(color)
                
                Text(title)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(Theme.textSecondary)
            }
            
            Text(streak == 1 ? "day" : "days")
                .font(.system(size: 10))
                .foregroundColor(Theme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color.white)
        .cornerRadius(Theme.cardCornerRadius)
        .shadow(color: Color.black.opacity(0.06), radius: Theme.cardShadowRadius, x: 0, y: 4)
    }
}

#Preview {
    DashboardView()
}
