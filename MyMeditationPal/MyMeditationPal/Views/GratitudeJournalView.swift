//
//  GratitudeJournalView.swift
//  MyMeditationPal
//
//  Created by Aaron Van Doren on 1/19/26.
//

import SwiftUI

struct GratitudeJournalView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var viewModel: MeditationViewModel
    
    @State private var gratitudeItems: [String] = ["", "", ""]
    @State private var isSaving = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Theme.lightGray.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: Theme.largePadding) {
                        // Prompt header
                        VStack(spacing: 12) {
                            Text("Daily Gratitude")
                                .font(.system(size: 32, weight: .bold))
                                .foregroundColor(Theme.textPrimary)
                            
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
                        .padding(.top, Theme.largePadding)
                        
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
                        Button(action: addGratitudeItem) {
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
                        
                        // Save button
                        Button(action: saveGratitude) {
                            HStack {
                                if isSaving {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                } else {
                                    Text(completedItemsCount >= 3 ? "Complete & Save" : "Save Progress")
                                        .font(.system(size: 18, weight: .semibold))
                                }
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                completedItemsCount >= 3 ? Theme.successGreen : Theme.primaryOrange
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
                                Image(systemName: completedItemsCount >= 3 ? "checkmark.circle.fill" : "circle.inset.filled")
                                    .font(.system(size: 16))
                                    .foregroundColor(completedItemsCount >= 3 ? Theme.successGreen : Theme.primaryOrange)
                                
                                Text("\(completedItemsCount) of 3 completed")
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
            loadExistingGratitude()
        }
    }
    
    private var completedItemsCount: Int {
        gratitudeItems.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }.count
    }
    
    private func addGratitudeItem() {
        gratitudeItems.append("")
    }
    
    private func loadExistingGratitude() {
        if let items = viewModel.loadTodayGratitudeItems(), !items.isEmpty {
            gratitudeItems = items
        }
    }
    
    private func saveGratitude() {
        isSaving = true
        
        // Filter out empty items
        let nonEmptyItems = gratitudeItems.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        
        // Save gratitude items
        viewModel.saveGratitudeItems(nonEmptyItems)
        
        // Mark as completed if 3 or more items
        if nonEmptyItems.count >= 3 {
            viewModel.markGratitudeCompleted()
        }
        
        // Small delay for visual feedback
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            isSaving = false
            dismiss()
        }
    }
}

struct GratitudeTextField: View {
    let number: Int
    @Binding var text: String
    @FocusState private var isFocused: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("\(number).")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(Theme.primaryOrange)
            
            TextField("Type your gratitude here...", text: $text, axis: .vertical)
                .font(.system(size: 16))
                .foregroundColor(Theme.textPrimary)
                .padding(Theme.spacing)
                .lineLimit(3...6)
                .background(Color.white)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isFocused ? Theme.primaryOrange : Color.clear, lineWidth: 2)
                )
                .focused($isFocused)
        }
        .padding(.vertical, 8)
    }
}

#Preview {
    GratitudeJournalView(viewModel: MeditationViewModel())
}
