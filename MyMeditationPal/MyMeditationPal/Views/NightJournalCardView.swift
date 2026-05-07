//
//  NightJournalCardView.swift
//  MyMeditationPal
//
//  Created by Aaron Van Doren on 1/20/26.
//

import SwiftUI

struct NightJournalCardView: View {
    let isCompleted: Bool
    var streak: Int = 0
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: Theme.spacing) {
                // Icon
                ZStack {
                    Circle()
                        .fill(Color(red: 0.5, green: 0.4, blue: 0.7).opacity(0.15))
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: "moon.stars.fill")
                        .font(.system(size: 20))
                        .foregroundColor(Color(red: 0.5, green: 0.4, blue: 0.7))
                }
                
                // Title and description
                VStack(alignment: .leading, spacing: 4) {
                    Text("Night Journal")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(Theme.textPrimary)
                    
                    Text("Highlights, Learnings & Tomorrow")
                        .font(.system(size: 13))
                        .foregroundColor(Theme.textSecondary)
                    
                    StreakBadge(streak: streak)
                        .padding(.top, 2)
                }
                
                Spacer()
                
                // Status indicators
                HStack(spacing: 12) {
                    if isCompleted {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(Theme.successGreen)
                    }
                    
                    Image(systemName: "pencil.circle.fill")
                        .font(.system(size: 28))
                        .foregroundColor(isCompleted ? Theme.successGreen : Color(red: 0.5, green: 0.4, blue: 0.7))
                }
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
    VStack {
        NightJournalCardView(isCompleted: false, streak: 0, onTap: {})
            .padding()
        
        NightJournalCardView(isCompleted: true, streak: 12, onTap: {})
            .padding()
    }
    .background(Theme.lightGray)
}
