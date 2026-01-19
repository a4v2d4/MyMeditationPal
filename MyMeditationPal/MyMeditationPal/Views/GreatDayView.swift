//
//  GreatDayView.swift
//  MyMeditationPal
//
//  Created by Aaron Van Doren on 1/19/26.
//

import SwiftUI

struct GreatDayView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var viewModel: MeditationViewModel
    
    @State private var greatDayItems: [String] = [""]
    @State private var isSaving = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Theme.lightGray.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: Theme.largePadding) {
                        // Prompt header
                        VStack(spacing: 12) {
                            Text("What Would Make")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(Theme.textPrimary)
                            
                            Text("Today Great?")
                                .font(.system(size: 32, weight: .bold))
                                .foregroundColor(Theme.textPrimary)
                            
                            Text("Set intentions for a meaningful day")
                                .font(.system(size: 16))
                                .foregroundColor(Theme.textSecondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, Theme.spacing)
                        }
                        .padding(.top, Theme.largePadding)
                        
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
                        Button(action: addGreatDayItem) {
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
                        
                        // Save button
                        Button(action: saveGreatDay) {
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
                                completedItemsCount >= 1 ? Theme.successGreen : Color(red: 0.95, green: 0.75, blue: 0.3)
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
                                    .foregroundColor(completedItemsCount >= 1 ? Theme.successGreen : Color(red: 0.95, green: 0.75, blue: 0.3))
                                
                                Text("\(completedItemsCount) intention\(completedItemsCount == 1 ? "" : "s")")
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
            loadExistingGreatDay()
        }
    }
    
    private var completedItemsCount: Int {
        greatDayItems.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }.count
    }
    
    private func addGreatDayItem() {
        greatDayItems.append("")
    }
    
    private func loadExistingGreatDay() {
        if let items = viewModel.loadTodayGreatDayItems(), !items.isEmpty {
            greatDayItems = items
        }
    }
    
    private func saveGreatDay() {
        isSaving = true
        
        // Filter out empty items
        let nonEmptyItems = greatDayItems.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        
        // Save great day items
        viewModel.saveGreatDayItems(nonEmptyItems)
        
        // Mark as completed if 1 or more items
        if nonEmptyItems.count >= 1 {
            viewModel.markGreatDayCompleted()
        }
        
        // Small delay for visual feedback
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            isSaving = false
            dismiss()
        }
    }
}

struct GreatDayTextField: View {
    let number: Int
    @Binding var text: String
    @FocusState private var isFocused: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("\(number).")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(Color(red: 0.95, green: 0.75, blue: 0.3))
            
            TextField("Today would be great if...", text: $text, axis: .vertical)
                .font(.system(size: 16))
                .foregroundColor(Theme.textPrimary)
                .padding(Theme.spacing)
                .lineLimit(3...6)
                .background(Color.white)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isFocused ? Color(red: 0.95, green: 0.75, blue: 0.3) : Color.clear, lineWidth: 2)
                )
                .focused($isFocused)
        }
        .padding(.vertical, 8)
    }
}

#Preview {
    GreatDayView(viewModel: MeditationViewModel())
}
