//
//  MorningJournalView.swift
//  MyMeditationPal
//
//  Created by Aaron Van Doren on 1/20/26.
//

import SwiftUI

struct MorningJournalView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var viewModel: MeditationViewModel
    
    @State private var selectedSection: MorningSection = .gratitude
    @State private var gratitudeItems: [String] = ["", "", ""]
    @State private var affirmationItems: [String] = [""]
    @State private var greatDayItems: [String] = [""]
    @State private var isSaving = false
    
    enum MorningSection: String, CaseIterable {
        case gratitude = "Gratitude"
        case affirmation = "Affirmations"
        case greatDay = "Intentions"
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Theme.lightGray.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header
                    VStack(spacing: 12) {
                        Text("Morning Journal")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(Theme.textPrimary)
                        
                        // Progress indicator
                        HStack(spacing: 16) {
                            ProgressCircle(isCompleted: gratitudeCompleted, color: Theme.primaryOrange, label: "1")
                            ProgressCircle(isCompleted: affirmationCompleted, color: Color(red: 0.3, green: 0.7, blue: 0.6), label: "2")
                            ProgressCircle(isCompleted: greatDayCompleted, color: Color(red: 0.95, green: 0.75, blue: 0.3), label: "3")
                        }
                    }
                    .padding(.top, Theme.largePadding)
                    .padding(.bottom, Theme.spacing)
                    
                    // Section picker
                    Picker("Section", selection: $selectedSection) {
                        ForEach(MorningSection.allCases, id: \.self) { section in
                            Text(section.rawValue).tag(section)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding(.horizontal, Theme.spacing)
                    .padding(.bottom, Theme.spacing)
                    
                    // Content
                    ScrollView {
                        VStack(spacing: Theme.largePadding) {
                            switch selectedSection {
                            case .gratitude:
                                gratitudeSection
                            case .affirmation:
                                affirmationSection
                            case .greatDay:
                                greatDaySection
                            }
                            
                            Spacer(minLength: 40)
                        }
                    }
                    
                    // Bottom save button
                    VStack(spacing: 12) {
                        Button(action: saveAll) {
                            HStack {
                                if isSaving {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                } else {
                                    Text(allCompleted ? "Complete & Save" : "Save Progress")
                                        .font(.system(size: 18, weight: .semibold))
                                }
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(allCompleted ? Theme.successGreen : Theme.primaryOrange)
                            .cornerRadius(Theme.cardCornerRadius)
                            .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
                        }
                        .disabled(isSaving || !hasAnyContent)
                        .opacity(hasAnyContent ? 1.0 : 0.5)
                        .padding(.horizontal, Theme.spacing)
                        
                        if allCompleted {
                            HStack(spacing: 6) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 16))
                                    .foregroundColor(Theme.successGreen)
                                
                                Text("All sections complete!")
                                    .font(.system(size: 14))
                                    .foregroundColor(Theme.textSecondary)
                            }
                        }
                    }
                    .padding(.bottom, Theme.spacing)
                    .background(Theme.lightGray)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                    .foregroundColor(Theme.textSecondary)
                }
            }
        }
        .onAppear {
            loadExistingData()
        }
    }
    
    private var gratitudeSection: some View {
        VStack(spacing: Theme.spacing) {
            // Prompt header
            VStack(spacing: 12) {
                Text("Today, I am grateful for:")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(Theme.textPrimary)
                    .multilineTextAlignment(.center)
                
                Text("(Moments, People, Feelings, Small Wins, Memories, Material Possessions, Circumstances, etc.)")
                    .font(.system(size: 14))
                    .foregroundColor(Theme.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Theme.spacing)
            }
            .padding(.top, Theme.spacing)
            
            // Gratitude text fields
            VStack(spacing: Theme.spacing) {
                ForEach(0..<gratitudeItems.count, id: \.self) { index in
                    GratitudeTextField(
                        number: index + 1,
                        text: $gratitudeItems[index]
                    )
                }
            }
            .padding(.horizontal, Theme.spacing)
            
            // Add more button
            Button(action: { gratitudeItems.append("") }) {
                HStack(spacing: 8) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 20))
                    Text("Add Another")
                        .font(.system(size: 16, weight: .medium))
                }
                .foregroundColor(Theme.primaryOrange)
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity)
                .background(Color.white)
                .cornerRadius(Theme.cardCornerRadius)
                .shadow(color: Color.black.opacity(0.06), radius: Theme.cardShadowRadius, x: 0, y: 4)
            }
            .padding(.horizontal, Theme.spacing)
            
            // Progress indicator
            if gratitudeCompletedCount > 0 {
                HStack(spacing: 6) {
                    Image(systemName: gratitudeCompleted ? "checkmark.circle.fill" : "circle.inset.filled")
                        .font(.system(size: 16))
                        .foregroundColor(gratitudeCompleted ? Theme.successGreen : Theme.primaryOrange)
                    
                    Text("\(gratitudeCompletedCount) of 3 completed")
                        .font(.system(size: 14))
                        .foregroundColor(Theme.textSecondary)
                }
            }
        }
    }
    
    private var affirmationSection: some View {
        VStack(spacing: Theme.spacing) {
            // Prompt header
            VStack(spacing: 12) {
                Text("Daily Affirmation(s)")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(Theme.textPrimary)
                
                Text("Positive statements to empower and encourage yourself")
                    .font(.system(size: 16))
                    .foregroundColor(Theme.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Theme.spacing)
            }
            .padding(.top, Theme.spacing)
            
            // Affirmation text fields
            VStack(spacing: Theme.spacing) {
                ForEach(0..<affirmationItems.count, id: \.self) { index in
                    AffirmationTextField(
                        number: index + 1,
                        text: $affirmationItems[index]
                    )
                }
            }
            .padding(.horizontal, Theme.spacing)
            
            // Add more button
            Button(action: { affirmationItems.append("") }) {
                HStack(spacing: 8) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 20))
                    Text("Add Another")
                        .font(.system(size: 16, weight: .medium))
                }
                .foregroundColor(Color(red: 0.3, green: 0.7, blue: 0.6))
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity)
                .background(Color.white)
                .cornerRadius(Theme.cardCornerRadius)
                .shadow(color: Color.black.opacity(0.06), radius: Theme.cardShadowRadius, x: 0, y: 4)
            }
            .padding(.horizontal, Theme.spacing)
            
            // Progress indicator
            if affirmationCompletedCount > 0 {
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundColor(Theme.successGreen)
                    
                    Text("\(affirmationCompletedCount) affirmation\(affirmationCompletedCount == 1 ? "" : "s")")
                        .font(.system(size: 14))
                        .foregroundColor(Theme.textSecondary)
                }
            }
        }
    }
    
    private var greatDaySection: some View {
        VStack(spacing: Theme.spacing) {
            // Prompt header
            VStack(spacing: 12) {
                Text("What Would Make")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(Theme.textPrimary)
                
                Text("Today Great?")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(Theme.textPrimary)
                
                Text("Set intentions for a meaningful day")
                    .font(.system(size: 16))
                    .foregroundColor(Theme.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Theme.spacing)
            }
            .padding(.top, Theme.spacing)
            
            // Great day text fields
            VStack(spacing: Theme.spacing) {
                ForEach(0..<greatDayItems.count, id: \.self) { index in
                    GreatDayTextField(
                        number: index + 1,
                        text: $greatDayItems[index]
                    )
                }
            }
            .padding(.horizontal, Theme.spacing)
            
            // Add more button
            Button(action: { greatDayItems.append("") }) {
                HStack(spacing: 8) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 20))
                    Text("Add Another")
                        .font(.system(size: 16, weight: .medium))
                }
                .foregroundColor(Color(red: 0.95, green: 0.75, blue: 0.3))
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity)
                .background(Color.white)
                .cornerRadius(Theme.cardCornerRadius)
                .shadow(color: Color.black.opacity(0.06), radius: Theme.cardShadowRadius, x: 0, y: 4)
            }
            .padding(.horizontal, Theme.spacing)
            
            // Progress indicator
            if greatDayCompletedCount > 0 {
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundColor(Theme.successGreen)
                    
                    Text("\(greatDayCompletedCount) intention\(greatDayCompletedCount == 1 ? "" : "s")")
                        .font(.system(size: 14))
                        .foregroundColor(Theme.textSecondary)
                }
            }
        }
    }
    
    // Computed properties
    private var gratitudeCompletedCount: Int {
        gratitudeItems.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }.count
    }
    
    private var affirmationCompletedCount: Int {
        affirmationItems.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }.count
    }
    
    private var greatDayCompletedCount: Int {
        greatDayItems.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }.count
    }
    
    private var gratitudeCompleted: Bool {
        gratitudeCompletedCount >= 3
    }
    
    private var affirmationCompleted: Bool {
        affirmationCompletedCount >= 1
    }
    
    private var greatDayCompleted: Bool {
        greatDayCompletedCount >= 1
    }
    
    private var allCompleted: Bool {
        gratitudeCompleted && affirmationCompleted && greatDayCompleted
    }
    
    private var hasAnyContent: Bool {
        gratitudeCompletedCount > 0 || affirmationCompletedCount > 0 || greatDayCompletedCount > 0
    }
    
    // Functions
    private func loadExistingData() {
        if let items = viewModel.loadTodayGratitudeItems(), !items.isEmpty {
            gratitudeItems = items
        }
        if let items = viewModel.loadTodayAffirmationItems(), !items.isEmpty {
            affirmationItems = items
        }
        if let items = viewModel.loadTodayGreatDayItems(), !items.isEmpty {
            greatDayItems = items
        }
    }
    
    private func saveAll() {
        isSaving = true
        
        // Save gratitude
        let nonEmptyGratitude = gratitudeItems.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        if !nonEmptyGratitude.isEmpty {
            viewModel.saveGratitudeItems(nonEmptyGratitude)
            if nonEmptyGratitude.count >= 3 {
                viewModel.markGratitudeCompleted()
            }
        }
        
        // Save affirmation
        let nonEmptyAffirmation = affirmationItems.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        if !nonEmptyAffirmation.isEmpty {
            viewModel.saveAffirmationItems(nonEmptyAffirmation)
            if nonEmptyAffirmation.count >= 1 {
                viewModel.markAffirmationCompleted()
            }
        }
        
        // Save great day
        let nonEmptyGreatDay = greatDayItems.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        if !nonEmptyGreatDay.isEmpty {
            viewModel.saveGreatDayItems(nonEmptyGreatDay)
            if nonEmptyGreatDay.count >= 1 {
                viewModel.markGreatDayCompleted()
            }
        }
        
        // Small delay for visual feedback
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            isSaving = false
            dismiss()
        }
    }
}

struct ProgressCircle: View {
    let isCompleted: Bool
    let color: Color
    let label: String
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(color.opacity(0.3), lineWidth: 3)
                .frame(width: 40, height: 40)
            
            if isCompleted {
                Circle()
                    .fill(color)
                    .frame(width: 40, height: 40)
                
                Image(systemName: "checkmark")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
            } else {
                Text(label)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(color)
            }
        }
    }
}

#Preview {
    MorningJournalView(viewModel: MeditationViewModel())
}
