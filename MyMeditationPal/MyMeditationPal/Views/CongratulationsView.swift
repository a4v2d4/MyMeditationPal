//
//  CongratulationsView.swift
//  MyMeditationPal
//
//  Created by Aaron Van Doren on 1/20/26.
//

import SwiftUI

struct CongratulationsView: View {
    let exerciseType: ExerciseType
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
                    exerciseColor.opacity(0.3),
                    exerciseColor.opacity(0.1),
                    Color.white
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            // Confetti effect — positions are fixed at onAppear to prevent re-randomization
            // every render frame. drawingGroup() composites all pieces into one Metal layer,
            // which prevents the system image-analysis daemon from trying to inspect each
            // piece individually (the source of the MADService XPC errors).
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
                        .fill(exerciseColor.opacity(0.15))
                        .frame(width: 140, height: 140)
                    
                    Circle()
                        .fill(exerciseColor.opacity(0.1))
                        .frame(width: 180, height: 180)
                    
                    Image(systemName: celebrationIcon)
                        .font(.system(size: 70, weight: .medium))
                        .foregroundColor(exerciseColor)
                }
                .scaleEffect(scale)
                .opacity(opacity)
                
                // Congratulations text
                VStack(spacing: 12) {
                    Text(streakMessage)
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(Theme.textPrimary)
                        .multilineTextAlignment(.center)
                    
                    Text(exerciseType.title)
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(Theme.textSecondary)
                }
                .opacity(opacity)
                
                // Streak display
                VStack(spacing: 8) {
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Text("\(streak)")
                            .font(.system(size: 72, weight: .bold))
                            .foregroundColor(exerciseColor)
                        
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
                        .background(exerciseColor)
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
            return "star.fill"
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
            return "You've taken the first step. Keep going!"
        } else if streak < 7 {
            return "You're building a powerful habit. Keep it up!"
        } else if streak < 30 {
            return "Your dedication is inspiring. Stay consistent!"
        } else {
            return "You're a meditation master! Incredible dedication!"
        }
    }
    
    private var exerciseColor: Color {
        switch exerciseType {
        case .boxBreathing:
            return Theme.deepBlue
        case .meditation(_):
            return Theme.primaryOrange
        case .coherentBreathing(_):
            return Color(red: 0.4, green: 0.6, blue: 0.8)
        case .bodyScan:
            return Color(red: 0.6, green: 0.4, blue: 0.8)
        case .kegelExercise:
            return Color(red: 0.8, green: 0.5, blue: 0.6)
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

// Confetti piece animation
struct ConfettiPiece: View {
    let color: Color
    @State private var animate = false
    
    var body: some View {
        RoundedRectangle(cornerRadius: 2)
            .fill(color)
            .frame(width: 8, height: 12)
            .rotationEffect(.degrees(animate ? 360 : 0))
            .offset(y: animate ? 800 : 0)
            .onAppear {
                withAnimation(
                    .linear(duration: Double.random(in: 2...4))
                    .repeatForever(autoreverses: false)
                ) {
                    animate = true
                }
            }
    }
}

#Preview {
    CongratulationsView(
        exerciseType: .meditation(duration: 10),
        streak: 5,
        onDismiss: {}
    )
}
