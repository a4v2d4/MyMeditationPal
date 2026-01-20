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
    @State private var showingCoherentBreathingDurationPicker = false
    
    var body: some View {
        NavigationView {
            mainContent
        }
    }
    
    private var mainContent: some View {
        ZStack {
            Theme.lightGray.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: Theme.largePadding) {
                    headerView
                    streakCardsView
                    exerciseCardsView
                    Spacer(minLength: 40)
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
        VStack(spacing: Theme.spacing) {
            exerciseStreakCards
            journalStreakCards
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
                    title: "Morning",
                    streak: viewModel.morningJournalStreak,
                    color: Color(red: 0.95, green: 0.75, blue: 0.3)
                )
            }
        }
    }
    
    private var journalStreakCards: some View {
        Group {
            HStack(spacing: Theme.spacing) {
                StreakCard(
                    title: "Night",
                    streak: viewModel.nightJournalStreak,
                    color: Color(red: 0.5, green: 0.4, blue: 0.7)
                )
            }
        }
    }
    
    private var exerciseCardsView: some View {
        VStack(spacing: Theme.spacing) {
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
            
            ExerciseCardView(
                exerciseType: .meditation,
                isCompleted: viewModel.todayMeditationCompleted,
                onTap: {
                    showingVideoPlayer = .meditation
                }
            )
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
    
    private var coherentBreathingCard: some View {
        Button(action: {
            showingCoherentBreathingDurationPicker = true
        }) {
            HStack(spacing: Theme.spacing) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Coherent Breath Exercise")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(Theme.textPrimary)
                    
                    Text("Choose 5 or 10 minutes")
                        .font(.system(size: 14))
                        .foregroundColor(Theme.textSecondary)
                }
                
                Spacer()
                
                if viewModel.todayCoherentBreathingCompleted {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 32))
                        .foregroundColor(Theme.successGreen)
                } else {
                    Image(systemName: "play.circle.fill")
                        .font(.system(size: 32))
                        .foregroundColor(Color(red: 0.4, green: 0.6, blue: 0.8))
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
        VStack(spacing: 8) {
            Text("\(streak)")
                .font(.system(size: 40, weight: .bold))
                .foregroundColor(color)
            
            HStack(spacing: 4) {
                Image(systemName: "flame.fill")
                    .font(.system(size: 14))
                    .foregroundColor(color)
                
                Text(title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Theme.textSecondary)
            }
            
            Text(streak == 1 ? "day streak" : "day streak")
                .font(.system(size: 12))
                .foregroundColor(Theme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(Color.white)
        .cornerRadius(Theme.cardCornerRadius)
        .shadow(color: Color.black.opacity(0.06), radius: Theme.cardShadowRadius, x: 0, y: 4)
    }
}

#Preview {
    DashboardView()
}
