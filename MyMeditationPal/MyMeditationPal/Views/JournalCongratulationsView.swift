//
//  JournalCongratulationsView.swift
//  MyMeditationPal
//
//  Created by Aaron Van Doren on 1/20/26.
//

import SwiftUI

enum JournalType {
    case morning
    case night
    
    var title: String {
        switch self {
        case .morning:
            return "Morning Journal"
        case .night:
            return "Night Journal"
        }
    }
    
    var icon: String {
        switch self {
        case .morning:
            return "sunrise.fill"
        case .night:
            return "moon.stars.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .morning:
            return Theme.primaryOrange
        case .night:
            return Color(red: 0.5, green: 0.4, blue: 0.7)
        }
    }
}

struct JournalCongratulationsView: View {
    let journalType: JournalType
    let streak: Int
    let onDismiss: () -> Void
    
    @State private var scale: CGFloat = 0.5
    @State private var opacity: Double = 0
    @State private var confettiOpacity: Double = 0
    @State private var confettiPositions: [(x: CGFloat, y: CGFloat)] = []
    
    var body: some View {
        ZStack {
            // Gradient background
            LinearGradient(
                gradient: Gradient(colors: [
                    journalType.color.opacity(0.3),
                    journalType.color.opacity(0.1),
                    Color.white
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            ZStack(alignment: .topLeading) {
                ForEach(0..<confettiPositions.count, id: \.self) { index in
                    ConfettiPiece(color: confettiColors[index % confettiColors.count])
                        .offset(x: confettiPositions[index].x, y: confettiPositions[index].y)
                        .opacity(confettiOpacity)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .drawingGroup()
            .allowsHitTesting(false)
            .accessibilityHidden(true)
            
            VStack(spacing: 32) {
                Spacer()
                
                // Celebration icon
                ZStack {
                    Circle()
                        .fill(journalType.color.opacity(0.15))
                        .frame(width: 140, height: 140)
                    
                    Circle()
                        .fill(journalType.color.opacity(0.1))
                        .frame(width: 180, height: 180)
                    
                    Image(systemName: celebrationIcon)
                        .font(.system(size: 70, weight: .medium))
                        .foregroundColor(journalType.color)
                }
                .scaleEffect(scale)
                .opacity(opacity)
                
                // Congratulations text
                VStack(spacing: 12) {
                    Text(streakMessage)
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(Theme.textPrimary)
                        .multilineTextAlignment(.center)
                    
                    Text(journalType.title)
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(Theme.textSecondary)
                }
                .opacity(opacity)
                
                // Streak display
                VStack(spacing: 8) {
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Text("\(streak)")
                            .font(.system(size: 72, weight: .bold))
                            .foregroundColor(journalType.color)
                        
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
                        .background(journalType.color)
                        .cornerRadius(16)
                }
                .padding(.horizontal, Theme.largePadding)
                .padding(.bottom, 32)
                .opacity(opacity)
            }
        }
        .onAppear {
            let bounds = UIScreen.main.bounds
            confettiPositions = (0..<20).map { _ in
                (x: CGFloat.random(in: 0...bounds.width),
                 y: CGFloat.random(in: -100...bounds.height * 0.6))
            }
            
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                scale = 1.0
            }
            
            withAnimation(.easeOut(duration: 0.5)) {
                opacity = 1.0
            }
            
            withAnimation(.easeOut(duration: 1.0).delay(0.2)) {
                confettiOpacity = 1.0
            }
        }
    }
    
    private var celebrationIcon: String {
        if streak == 1 {
            return journalType.icon
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
        switch journalType {
        case .morning:
            if streak == 1 {
                return "You've started your morning with intention. Keep it up!"
            } else if streak < 7 {
                return "Your morning routine is taking shape. Great work!"
            } else if streak < 30 {
                return "Your mornings are transformed by this practice!"
            } else {
                return "You're a journaling master! Amazing dedication!"
            }
        case .night:
            if streak == 1 {
                return "Reflecting on your day is a powerful practice!"
            } else if streak < 7 {
                return "Your evening reflections are building wisdom!"
            } else if streak < 30 {
                return "Your nightly practice shows incredible commitment!"
            } else {
                return "You're a reflection master! Outstanding dedication!"
            }
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
    JournalCongratulationsView(
        journalType: .morning,
        streak: 7,
        onDismiss: {}
    )
}
