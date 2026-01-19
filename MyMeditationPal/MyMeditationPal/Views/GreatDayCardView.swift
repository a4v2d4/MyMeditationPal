//
//  GreatDayCardView.swift
//  MyMeditationPal
//
//  Created by Aaron Van Doren on 1/19/26.
//

import SwiftUI

struct GreatDayCardView: View {
    let isCompleted: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 0) {
                // Icon header
                ZStack {
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color(red: 1.0, green: 0.85, blue: 0.4),
                            Color(red: 0.95, green: 0.75, blue: 0.3)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .frame(height: 180)
                    
                    VStack(spacing: 12) {
                        Image(systemName: "sun.max.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.white.opacity(0.9))
                        
                        Text("Journaling")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white.opacity(0.9))
                    }
                    
                    // Play/Edit overlay
                    if !isCompleted {
                        VStack {
                            Spacer()
                            HStack {
                                Spacer()
                                Circle()
                                    .fill(Color.white.opacity(0.9))
                                    .frame(width: 50, height: 50)
                                
                                Image(systemName: "pencil")
                                    .font(.system(size: 20))
                                    .foregroundColor(Color(red: 0.95, green: 0.75, blue: 0.3))
                                Spacer()
                            }
                            Spacer()
                        }
                    }
                }
                
                // Info section
                HStack {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("What Would Make Today Great?")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(Theme.textPrimary)
                        
                        Text("Set your intentions")
                            .font(.system(size: 15))
                            .foregroundColor(Theme.textSecondary)
                    }
                    
                    Spacer()
                    
                    // Checkbox
                    ZStack {
                        Circle()
                            .stroke(isCompleted ? Theme.successGreen : Theme.mediumGray, lineWidth: 2)
                            .frame(width: 32, height: 32)
                        
                        if isCompleted {
                            Circle()
                                .fill(Theme.successGreen)
                                .frame(width: 32, height: 32)
                            
                            Image(systemName: "checkmark")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.white)
                        }
                    }
                }
                .padding(Theme.spacing)
            }
            .background(Color.white)
            .cornerRadius(Theme.cardCornerRadius)
            .shadow(color: Color.black.opacity(0.06), radius: Theme.cardShadowRadius, x: 0, y: 4)
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

#Preview {
    VStack {
        GreatDayCardView(isCompleted: false, onTap: {})
            .padding()
        
        GreatDayCardView(isCompleted: true, onTap: {})
            .padding()
    }
    .background(Theme.lightGray)
}
