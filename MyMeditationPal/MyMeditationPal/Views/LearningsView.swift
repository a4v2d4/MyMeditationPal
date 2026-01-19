//
//  LearningsView.swift
//  MyMeditationPal
//
//  Created by Aaron Van Doren on 1/19/26.
//

import SwiftUI

struct LearningsView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var viewModel: MeditationViewModel
    
    @State private var learningItems: [String] = [""]
    @State private var isSaving = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Theme.lightGray.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: Theme.largePadding) {
                        // Prompt header
                        VStack(spacing: 12) {
                            Text("What Did I Learn Today?")
                                .font(.system(size: 32, weight: .bold))
                                .foregroundColor(Theme.textPrimary)
                            
                            Text("Reflect on today's insights and growth")
                                .font(.system(size: 16))
                                .foregroundColor(Theme.textSecondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, Theme.spacing)
                        }
                        .padding(.top, Theme.largePadding)
                        
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
                        Button(action: addLearningItem) {
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
                        
                        // Save button
                        Button(action: saveLearnings) {
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
                                completedItemsCount >= 1 ? Theme.successGreen : Color(red: 0.5, green: 0.4, blue: 0.7)
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
                                    .foregroundColor(completedItemsCount >= 1 ? Theme.successGreen : Color(red: 0.5, green: 0.4, blue: 0.7))
                                
                                Text("\(completedItemsCount) learning\(completedItemsCount == 1 ? "" : "s")")
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
            loadExistingLearnings()
        }
    }
    
    private var completedItemsCount: Int {
        learningItems.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }.count
    }
    
    private func addLearningItem() {
        learningItems.append("")
    }
    
    private func loadExistingLearnings() {
        if let items = viewModel.loadTodayLearningItems(), !items.isEmpty {
            learningItems = items
        }
    }
    
    private func saveLearnings() {
        isSaving = true
        
        // Filter out empty items
        let nonEmptyItems = learningItems.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        
        // Save learning items
        viewModel.saveLearningItems(nonEmptyItems)
        
        // Mark as completed if 1 or more items
        if nonEmptyItems.count >= 1 {
            viewModel.markLearningCompleted()
        }
        
        // Small delay for visual feedback
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            isSaving = false
            dismiss()
        }
    }
}

struct LearningTextField: View {
    let number: Int
    @Binding var text: String
    @FocusState private var isFocused: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("\(number).")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(Color(red: 0.5, green: 0.4, blue: 0.7))
            
            TextField("I learned that...", text: $text, axis: .vertical)
                .font(.system(size: 16))
                .foregroundColor(Theme.textPrimary)
                .padding(Theme.spacing)
                .lineLimit(3...6)
                .background(Color.white)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isFocused ? Color(red: 0.5, green: 0.4, blue: 0.7) : Color.clear, lineWidth: 2)
                )
                .focused($isFocused)
        }
        .padding(.vertical, 8)
    }
}

#Preview {
    LearningsView(viewModel: MeditationViewModel())
}
