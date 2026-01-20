//
//  ExerciseCardView.swift
//  MyMeditationPal
//
//  Created by Aaron Van Doren on 1/18/26.
//

import SwiftUI
import AVFoundation

struct ExerciseCardView: View {
    let exerciseType: ExerciseType
    let isCompleted: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: Theme.spacing) {
                // Icon
                ZStack {
                    Circle()
                        .fill(exerciseColor.opacity(0.15))
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: exerciseIcon)
                        .font(.system(size: 20))
                        .foregroundColor(exerciseColor)
                }
                
                // Title and duration
                VStack(alignment: .leading, spacing: 4) {
                    Text(exerciseType.title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(Theme.textPrimary)
                    
                    Text(exerciseType.duration)
                        .font(.system(size: 13))
                        .foregroundColor(Theme.textSecondary)
                }
                
                Spacer()
                
                // Status indicators
                HStack(spacing: 12) {
                    if isCompleted {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(Theme.successGreen)
                    }
                    
                    Image(systemName: "play.circle.fill")
                        .font(.system(size: 28))
                        .foregroundColor(isCompleted ? Theme.successGreen : exerciseColor)
                }
            }
            .padding(Theme.spacing)
            .background(Color.white)
            .cornerRadius(Theme.cardCornerRadius)
            .shadow(color: Color.black.opacity(0.06), radius: Theme.cardShadowRadius, x: 0, y: 4)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var exerciseIcon: String {
        switch exerciseType {
        case .boxBreathing:
            return "wind"
        case .meditation(_):
            return "mic.fill"
        case .coherentBreathing(_):
            return "waveform.path.ecg"
        case .bodyScan:
            return "figure.mind.and.body"
        case .kegelExercise:
            return "heart.fill"
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
}

struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}
