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
    
    var body: some View {
        NavigationView {
            ZStack {
                Theme.lightGray.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: Theme.largePadding) {
                        // Header
                        VStack(spacing: 12) {
                            Text("Today's Practice")
                                .font(.system(size: 32, weight: .bold))
                                .foregroundColor(Theme.textPrimary)
                            
                            Text(formattedDate)
                                .font(.system(size: 16))
                                .foregroundColor(Theme.textSecondary)
                        }
                        .padding(.top, Theme.largePadding)
                        
                        // Streak Cards
                        VStack(spacing: Theme.spacing) {
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
                        }
                        .padding(.horizontal, Theme.spacing)
                        
                        // Exercise Cards
                        VStack(spacing: Theme.spacing) {
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
                            
                            ExerciseCardView(
                                exerciseType: .coherentBreathing,
                                isCompleted: viewModel.todayCoherentBreathingCompleted,
                                onTap: {
                                    showingVideoPlayer = .coherentBreathing
                                }
                            )
                            
                            ExerciseCardView(
                                exerciseType: .bodyScan,
                                isCompleted: viewModel.todayBodyScanCompleted,
                                onTap: {
                                    showingVideoPlayer = .bodyScan
                                }
                            )
                        }
                        .padding(.horizontal, Theme.spacing)
                        
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
            .onAppear {
                viewModel.loadTodayStatus()
            }
        }
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
