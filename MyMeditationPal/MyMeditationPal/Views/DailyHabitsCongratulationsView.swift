//
//  DailyHabitsCongratulationsView.swift
//  MyMeditationPal
//
//  Created by Aaron Van Doren on 1/20/26.
//

import SwiftUI

struct DailyHabitsCongratulationsView: View {
    let streak: Int
    let onDismiss: () -> Void
    
    @State private var scale: CGFloat = 0.5
    @State private var opacity: Double = 0
    @State private var confettiOpacity: Double = 0
    
    private let habitColor = Color(red: 0.3, green: 0.7, blue: 0.9)
    
    var body: some View {
        ZStack {
            // Gradient background
            LinearGradient(
                gradient: Gradient(colors: [
                    habitColor.opacity(0.3),
                    habitColor.opacity(0.1),
                    Color.white
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            // Confetti effect
            GeometryReader { geometry in
                ForEach(0..<20, id: \.self) { index in
                    ConfettiPiece(color: confettiColors[index % confettiColors.count])
                        .offset(
                            x: CGFloat.random(in: 0...geometry.size.width),
                            y: CGFloat.random(in: -100...geometry.size.height * 0.6)
                        )
                        .opacity(confettiOpacity)
                }
            }
            
            VStack(spacing: 32) {
                Spacer()
                
                // Celebration icon
                ZStack {
                    Circle()
                        .fill(habitColor.opacity(0.15))
                        .frame(width: 140, height: 140)
                    
                    Circle()
                        .fill(habitColor.opacity(0.1))
                        .frame(width: 180, height: 180)
                    
                    Image(systemName: celebrationIcon)
                        .font(.system(size: 70, weight: .medium))
                        .foregroundColor(habitColor)
                }
                .scaleEffect(scale)
                .opacity(opacity)
                
                // Congratulations text
                VStack(spacing: 12) {
                    Text(streakMessage)
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(Theme.textPrimary)
                        .multilineTextAlignment(.center)
                    
                    Text("Daily Habits")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(Theme.textSecondary)
                }
                .opacity(opacity)
                
                // Streak display
                VStack(spacing: 8) {
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Text("\(streak)")
                            .font(.system(size: 72, weight: .bold))
                            .foregroundColor(habitColor)
                        
                        Image(systemName: "flame.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.orange)
                            .offset(y: -10)
                    }
                    
                    Text(streakSubtitle)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(Theme.textSecondary)
                }
                .opacity(opacity)
                
                // Encouraging message
                Text(encouragementMessage)
                    .font(.system(size: 16))
                    .foregroundColor(Theme.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                    .opacity(opacity)
                
                Spacer()
                
                // Continue button
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        onDismiss()
                    }
                }) {
                    Text("Continue")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(habitColor)
                        .cornerRadius(16)
                }
                .padding(.horizontal, Theme.largePadding)
                .padding(.bottom, 32)
                .opacity(opacity)
            }
        }
        .onAppear {
            // Animate entrance
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                scale = 1.0
            }
            
            withAnimation(.easeOut(duration: 0.5)) {
                opacity = 1.0
            }
            
            // Animate confetti with slight delay
            withAnimation(.easeOut(duration: 1.0).delay(0.2)) {
                confettiOpacity = 1.0
            }
        }
    }
    
    private var celebrationIcon: String {
        if streak == 1 {
            return "checkmark.circle.fill"
        } else if streak < 7 {
            return "star.circle.fill"
        } else if streak < 30 {
            return "crown.fill"
        } else {
            return "trophy.fill"
        }
    }
    
    private var streakMessage: String {
        if streak == 1 {
            return "Great Start!"
        } else if streak < 7 {
            return "Well Done!"
        } else if streak < 30 {
            return "Amazing!"
        } else {
            return "Incredible!"
        }
    }
    
    private var streakSubtitle: String {
        if streak == 1 {
            return "Day Streak"
        } else {
            return "Day Streak"
        }
    }
    
    private var encouragementMessage: String {
        if streak == 1 {
            return "You've completed all your daily habits. Keep building!"
        } else if streak < 7 {
            return "Your daily routine is taking shape. Great consistency!"
        } else if streak < 30 {
            return "Your habits are becoming second nature. Impressive!"
        } else {
            return "You're a habit master! Outstanding dedication!"
        }
    }
    
    private var confettiColors: [Color] {
        [
            Theme.primaryOrange,
            Theme.successGreen,
            Color.blue,
            Color.purple,
            Color.pink,
            Color.yellow
        ]
    }
}

#Preview {
    DailyHabitsCongratulationsView(
        streak: 7,
        onDismiss: {}
    )
}
