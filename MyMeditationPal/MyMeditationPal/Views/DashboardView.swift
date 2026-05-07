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
    @State private var showingDataManagement = false
    @State private var showingInsights = false
    
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
                    exerciseCardsView
                    Spacer(minLength: 20)
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { showingDataManagement = true }) {
                    Image(systemName: "externaldrive")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(Theme.primaryOrange)
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack(spacing: 16) {
                    Button(action: { showingInsights = true }) {
                        Image(systemName: "chart.line.uptrend.xyaxis")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(Theme.primaryOrange)
                    }
                    
                    Button(action: { showingCalendar = true }) {
                        Image(systemName: "calendar")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(Theme.primaryOrange)
                    }
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
        .sheet(isPresented: $showingDataManagement) {
            DataManagementView(viewModel: viewModel)
        }
        .sheet(isPresented: $showingInsights) {
            InsightsView(viewModel: viewModel)
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
                streak: viewModel.boxBreathingStreak,
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
                streak: viewModel.morningJournalStreak,
                onTap: {
                    showingMorningJournal = true
                }
            )
            
            DailyHabitsCardView(
                isCompleted: viewModel.todayDailyHabitsCompleted,
                progress: viewModel.getTodayDailyHabitsProgress(),
                streak: viewModel.dailyHabitsStreak,
                onTap: {
                    showingDailyHabits = true
                }
            )
            
            ExerciseCardView(
                exerciseType: .kegelExercise,
                isCompleted: viewModel.todayKegelExerciseCompleted,
                streak: viewModel.kegelExerciseStreak,
                onTap: {
                    showingVideoPlayer = .kegelExercise
                }
            )
            
            NightJournalCardView(
                isCompleted: viewModel.todayNightJournalCompleted,
                streak: viewModel.nightJournalStreak,
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
                streak: viewModel.bodyScanStreak,
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
                    
                    HStack(spacing: 8) {
                        Text("Choose 5 or 10 minutes")
                            .font(.system(size: 13))
                            .foregroundColor(Theme.textSecondary)
                        
                        StreakBadge(streak: viewModel.meditationStreak)
                    }
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
                    
                    HStack(spacing: 8) {
                        Text("Choose 5 or 10 minutes")
                            .font(.system(size: 13))
                            .foregroundColor(Theme.textSecondary)
                        
                        StreakBadge(streak: viewModel.coherentBreathingStreak)
                    }
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

#Preview {
    DashboardView()
}
