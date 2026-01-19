//
//  DailyAffirmationView.swift
//  MyMeditationPal
//
//  Created by Aaron Van Doren on 1/19/26.
//

import SwiftUI

struct DailyAffirmationView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var viewModel: MeditationViewModel
    
    @State private var affirmationItems: [String] = [""]
    @State private var isSaving = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Theme.lightGray.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: Theme.largePadding) {
                        // Prompt header
                        VStack(spacing: 12) {
                            Text("Daily Affirmation(s)")
                                .font(.system(size: 32, weight: .bold))
                                .foregroundColor(Theme.textPrimary)
                            
                            Text("Positive statements to empower and encourage yourself")
                                .font(.system(size: 16))
                                .foregroundColor(Theme.textSecondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, Theme.spacing)
                        }
                        .padding(.top, Theme.largePadding)
                        
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
                        Button(action: addAffirmationItem) {
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
                        
                        // Save button
                        Button(action: saveAffirmation) {
                            HStack {
                                if isSaving {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                } else {
                                    Text(completedItemsCount >= 1 ? "Complete & Save" : "Save Progress")
                                        .font(.system(size: 18, weight: .semibold))
                                }
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                completedItemsCount >= 1 ? Theme.successGreen : Color(red: 0.3, green: 0.7, blue: 0.6)
                            )
                            .cornerRadius(Theme.cardCornerRadius)
                            .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
                        }
                        .disabled(isSaving || completedItemsCount == 0)
                        .opacity(completedItemsCount == 0 ? 0.5 : 1.0)
                        .padding(.horizontal, Theme.spacing)
                        
                        // Progress indicator
                        if completedItemsCount > 0 {
                            HStack(spacing: 6) {
                                Image(systemName: completedItemsCount >= 1 ? "checkmark.circle.fill" : "circle.inset.filled")
                                    .font(.system(size: 16))
                                    .foregroundColor(completedItemsCount >= 1 ? Theme.successGreen : Color(red: 0.3, green: 0.7, blue: 0.6))
                                
                                Text("\(completedItemsCount) affirmation\(completedItemsCount == 1 ? "" : "s")")
                                    .font(.system(size: 14))
                                    .foregroundColor(Theme.textSecondary)
                            }
                        }
                        
                        Spacer(minLength: 40)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(Theme.textSecondary)
                }
            }
        }
        .onAppear {
            loadExistingAffirmation()
        }
    }
    
    private var completedItemsCount: Int {
        affirmationItems.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }.count
    }
    
    private func addAffirmationItem() {
        affirmationItems.append("")
    }
    
    private func loadExistingAffirmation() {
        if let items = viewModel.loadTodayAffirmationItems(), !items.isEmpty {
            affirmationItems = items
        }
    }
    
    private func saveAffirmation() {
        isSaving = true
        
        // Filter out empty items
        let nonEmptyItems = affirmationItems.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        
        // Save affirmation items
        viewModel.saveAffirmationItems(nonEmptyItems)
        
        // Mark as completed if 1 or more items
        if nonEmptyItems.count >= 1 {
            viewModel.markAffirmationCompleted()
        }
        
        // Small delay for visual feedback
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            isSaving = false
            dismiss()
        }
    }
}

struct AffirmationTextField: View {
    let number: Int
    @Binding var text: String
    @FocusState private var isFocused: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("\(number).")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(Color(red: 0.3, green: 0.7, blue: 0.6))
            
            TextField("I am...", text: $text, axis: .vertical)
                .font(.system(size: 16))
                .foregroundColor(Theme.textPrimary)
                .padding(Theme.spacing)
                .lineLimit(3...6)
                .background(Color.white)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isFocused ? Color(red: 0.3, green: 0.7, blue: 0.6) : Color.clear, lineWidth: 2)
                )
                .focused($isFocused)
        }
        .padding(.vertical, 8)
    }
}

#Preview {
    DailyAffirmationView(viewModel: MeditationViewModel())
}
