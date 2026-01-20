//
//  NightJournalView.swift
//  MyMeditationPal
//
//  Created by Aaron Van Doren on 1/20/26.
//

import SwiftUI

struct NightJournalView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var viewModel: MeditationViewModel
    
    @State private var selectedSection: NightSection = .highlights
    @State private var highlightItems: [String] = [""]
    @State private var learningItems: [String] = [""]
    @State private var excitementItems: [String] = [""]
    @State private var isSaving = false
    @State private var showingCongratulations = false
    
    enum NightSection: String, CaseIterable {
        case highlights = "Highlights"
        case learnings = "Learnings"
        case excitement = "Excitement"
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Theme.lightGray.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header
                    VStack(spacing: 12) {
                        Text("Night Journal")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(Theme.textPrimary)
                        
                        // Progress indicator
                        HStack(spacing: 16) {
                            ProgressCircle(isCompleted: highlightsCompleted, color: Color(red: 1.0, green: 0.6, blue: 0.4), label: "1")
                            ProgressCircle(isCompleted: learningsCompleted, color: Color(red: 0.5, green: 0.4, blue: 0.7), label: "2")
                            ProgressCircle(isCompleted: excitementCompleted, color: Color(red: 0.4, green: 0.75, blue: 0.95), label: "3")
                        }
                    }
                    .padding(.top, Theme.largePadding)
                    .padding(.bottom, Theme.spacing)
                    
                    // Section picker
                    Picker("Section", selection: $selectedSection) {
                        ForEach(NightSection.allCases, id: \.self) { section in
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
                            case .highlights:
                                highlightsSection
                            case .learnings:
                                learningsSection
                            case .excitement:
                                excitementSection
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
                            .background(allCompleted ? Theme.successGreen : Color(red: 0.5, green: 0.4, blue: 0.7))
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
        .fullScreenCover(isPresented: $showingCongratulations) {
            JournalCongratulationsView(
                journalType: .night,
                streak: viewModel.nightJournalStreak,
                onDismiss: {
                    showingCongratulations = false
                    dismiss()
                }
            )
        }
    }
    
    private var highlightsSection: some View {
        VStack(spacing: Theme.spacing) {
            // Prompt header
            VStack(spacing: 12) {
                Text("Highlight(s) of the Day")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(Theme.textPrimary)
                
                Text("Celebrate the best moments from today")
                    .font(.system(size: 16))
                    .foregroundColor(Theme.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Theme.spacing)
            }
            .padding(.top, Theme.spacing)
            
            // Highlight text fields
            VStack(spacing: Theme.spacing) {
                ForEach(0..<highlightItems.count, id: \.self) { index in
                    HighlightTextField(
                        number: index + 1,
                        text: $highlightItems[index]
                    )
                }
            }
            .padding(.horizontal, Theme.spacing)
            
            // Add more button
            Button(action: { highlightItems.append("") }) {
                HStack(spacing: 8) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 20))
                    Text("Add Another")
                        .font(.system(size: 16, weight: .medium))
                }
                .foregroundColor(Color(red: 1.0, green: 0.6, blue: 0.4))
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity)
                .background(Color.white)
                .cornerRadius(Theme.cardCornerRadius)
                .shadow(color: Color.black.opacity(0.06), radius: Theme.cardShadowRadius, x: 0, y: 4)
            }
            .padding(.horizontal, Theme.spacing)
            
            // Progress indicator
            if highlightsCompletedCount > 0 {
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundColor(Theme.successGreen)
                    
                    Text("\(highlightsCompletedCount) highlight\(highlightsCompletedCount == 1 ? "" : "s")")
                        .font(.system(size: 14))
                        .foregroundColor(Theme.textSecondary)
                }
            }
        }
    }
    
    private var learningsSection: some View {
        VStack(spacing: Theme.spacing) {
            // Prompt header
            VStack(spacing: 12) {
                Text("What Did I Learn Today?")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(Theme.textPrimary)
                
                Text("Reflect on today's insights and growth")
                    .font(.system(size: 16))
                    .foregroundColor(Theme.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Theme.spacing)
            }
            .padding(.top, Theme.spacing)
            
            // Learning text fields
            VStack(spacing: Theme.spacing) {
                ForEach(0..<learningItems.count, id: \.self) { index in
                    LearningTextField(
                        number: index + 1,
                        text: $learningItems[index]
                    )
                }
            }
            .padding(.horizontal, Theme.spacing)
            
            // Add more button
            Button(action: { learningItems.append("") }) {
                HStack(spacing: 8) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 20))
                    Text("Add Another")
                        .font(.system(size: 16, weight: .medium))
                }
                .foregroundColor(Color(red: 0.5, green: 0.4, blue: 0.7))
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity)
                .background(Color.white)
                .cornerRadius(Theme.cardCornerRadius)
                .shadow(color: Color.black.opacity(0.06), radius: Theme.cardShadowRadius, x: 0, y: 4)
            }
            .padding(.horizontal, Theme.spacing)
            
            // Progress indicator
            if learningsCompletedCount > 0 {
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundColor(Theme.successGreen)
                    
                    Text("\(learningsCompletedCount) learning\(learningsCompletedCount == 1 ? "" : "s")")
                        .font(.system(size: 14))
                        .foregroundColor(Theme.textSecondary)
                }
            }
        }
    }
    
    private var excitementSection: some View {
        VStack(spacing: Theme.spacing) {
            // Prompt header
            VStack(spacing: 12) {
                Text("What Am I Excited")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(Theme.textPrimary)
                
                Text("About for Tomorrow?")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(Theme.textPrimary)
                
                Text("Look forward with anticipation and joy")
                    .font(.system(size: 16))
                    .foregroundColor(Theme.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Theme.spacing)
            }
            .padding(.top, Theme.spacing)
            
            // Excitement text fields
            VStack(spacing: Theme.spacing) {
                ForEach(0..<excitementItems.count, id: \.self) { index in
                    ExcitementTextField(
                        number: index + 1,
                        text: $excitementItems[index]
                    )
                }
            }
            .padding(.horizontal, Theme.spacing)
            
            // Add more button
            Button(action: { excitementItems.append("") }) {
                HStack(spacing: 8) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 20))
                    Text("Add Another")
                        .font(.system(size: 16, weight: .medium))
                }
                .foregroundColor(Color(red: 0.4, green: 0.75, blue: 0.95))
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity)
                .background(Color.white)
                .cornerRadius(Theme.cardCornerRadius)
                .shadow(color: Color.black.opacity(0.06), radius: Theme.cardShadowRadius, x: 0, y: 4)
            }
            .padding(.horizontal, Theme.spacing)
            
            // Progress indicator
            if excitementCompletedCount > 0 {
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundColor(Theme.successGreen)
                    
                    Text("\(excitementCompletedCount) item\(excitementCompletedCount == 1 ? "" : "s")")
                        .font(.system(size: 14))
                        .foregroundColor(Theme.textSecondary)
                }
            }
        }
    }
    
    // Computed properties
    private var highlightsCompletedCount: Int {
        highlightItems.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }.count
    }
    
    private var learningsCompletedCount: Int {
        learningItems.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }.count
    }
    
    private var excitementCompletedCount: Int {
        excitementItems.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }.count
    }
    
    private var highlightsCompleted: Bool {
        highlightsCompletedCount >= 1
    }
    
    private var learningsCompleted: Bool {
        learningsCompletedCount >= 1
    }
    
    private var excitementCompleted: Bool {
        excitementCompletedCount >= 1
    }
    
    private var allCompleted: Bool {
        highlightsCompleted && learningsCompleted && excitementCompleted
    }
    
    private var hasAnyContent: Bool {
        highlightsCompletedCount > 0 || learningsCompletedCount > 0 || excitementCompletedCount > 0
    }
    
    // Functions
    private func loadExistingData() {
        if let items = viewModel.loadTodayHighlightItems(), !items.isEmpty {
            highlightItems = items
        }
        if let items = viewModel.loadTodayLearningItems(), !items.isEmpty {
            learningItems = items
        }
        if let items = viewModel.loadTodayExcitementItems(), !items.isEmpty {
            excitementItems = items
        }
    }
    
    private func saveAll() {
        isSaving = true
        
        let wasAlreadyCompleted = viewModel.todayNightJournalCompleted
        
        // Save highlights
        let nonEmptyHighlights = highlightItems.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        if !nonEmptyHighlights.isEmpty {
            viewModel.saveHighlightItems(nonEmptyHighlights)
            if nonEmptyHighlights.count >= 1 {
                viewModel.markHighlightCompleted()
            }
        }
        
        // Save learnings
        let nonEmptyLearnings = learningItems.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        if !nonEmptyLearnings.isEmpty {
            viewModel.saveLearningItems(nonEmptyLearnings)
            if nonEmptyLearnings.count >= 1 {
                viewModel.markLearningCompleted()
            }
        }
        
        // Save excitement
        let nonEmptyExcitement = excitementItems.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        if !nonEmptyExcitement.isEmpty {
            viewModel.saveExcitementItems(nonEmptyExcitement)
            if nonEmptyExcitement.count >= 1 {
                viewModel.markExcitementCompleted()
            }
        }
        
        // Small delay for visual feedback
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            isSaving = false
            
            // Show congratulations if just completed all sections
            if allCompleted && !wasAlreadyCompleted {
                showingCongratulations = true
            } else {
                dismiss()
            }
        }
    }
}

#Preview {
    NightJournalView(viewModel: MeditationViewModel())
}
