//
//  MorningJournalCardView.swift
//  MyMeditationPal
//
//  Created by Aaron Van Doren on 1/20/26.
//

import SwiftUI

struct MorningJournalCardView: View {
    let isCompleted: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: Theme.spacing) {
                // Icon
                ZStack {
                    Circle()
                        .fill(Color(red: 0.95, green: 0.75, blue: 0.3).opacity(0.15))
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: "sunrise.fill")
                        .font(.system(size: 20))
                        .foregroundColor(Color(red: 0.95, green: 0.75, blue: 0.3))
                }
                
                // Title and description
                VStack(alignment: .leading, spacing: 4) {
                    Text("Morning Journal")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(Theme.textPrimary)
                    
                    Text("Gratitude, Affirmations & Intentions")
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
                    
                    Image(systemName: "pencil.circle.fill")
                        .font(.system(size: 28))
                        .foregroundColor(isCompleted ? Theme.successGreen : Color(red: 0.95, green: 0.75, blue: 0.3))
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
        MorningJournalCardView(isCompleted: false, onTap: {})
            .padding()
        
        MorningJournalCardView(isCompleted: true, onTap: {})
            .padding()
    }
    .background(Theme.lightGray)
}
