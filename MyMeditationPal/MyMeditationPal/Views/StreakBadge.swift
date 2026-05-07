//
//  StreakBadge.swift
//  MyMeditationPal
//
//  Small reusable streak indicator (flame icon + day count) used on dashboard cards.
//

import SwiftUI

struct StreakBadge: View {
    let streak: Int
    
    private var streakColor: Color {
        switch streak {
        case 0: return Theme.textSecondary.opacity(0.7)
        case 1...6: return Color(red: 0.96, green: 0.55, blue: 0.30)
        case 7...29: return Color(red: 1.0, green: 0.45, blue: 0.10)
        default: return Color(red: 0.90, green: 0.25, blue: 0.05)
        }
    }
    
    private var label: String {
        if streak == 0 {
            return "Start streak"
        }
        return "\(streak) day\(streak == 1 ? "" : "s")"
    }
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: streak == 0 ? "flame" : "flame.fill")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(streakColor)
            
            Text(label)
                .font(.system(size: 12, weight: streak == 0 ? .medium : .semibold))
                .foregroundColor(streakColor)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 3)
        .background(streakColor.opacity(0.12))
        .clipShape(Capsule())
    }
}

#Preview {
    VStack(spacing: 12) {
        StreakBadge(streak: 0)
        StreakBadge(streak: 1)
        StreakBadge(streak: 5)
        StreakBadge(streak: 14)
        StreakBadge(streak: 60)
    }
    .padding()
    .background(Color.white)
}
