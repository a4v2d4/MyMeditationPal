//
//  HighlightsView.swift
//  MyMeditationPal
//
//  Created by Aaron Van Doren on 1/19/26.
//

import SwiftUI

struct HighlightsView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var viewModel: MeditationViewModel
    
    @State private var highlightItems: [String] = [""]
    @State private var isSaving = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Theme.lightGray.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: Theme.largePadding) {
                        // Prompt header
                        VStack(spacing: 12) {
                            Text("Highlight(s) of the Day")
                                .font(.system(size: 32, weight: .bold))
                                .foregroundColor(Theme.textPrimary)
                            
                            Text("Celebrate the best moments from today")
                                .font(.system(size: 16))
                                .foregroundColor(Theme.textSecondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, Theme.spacing)
                        }
                        .padding(.top, Theme.largePadding)
                        
                        // Highlight text fields
                        VStack(spacing: Theme.spacing) {
                            ForEach(0..<highlightItems.count, id: \.self) { index in
                                HighlightTextField(
                                    number: index + 1,
                                    text: $highlightItems[index],
                                    autoFocus: index == 0
                                )
                            }
                        }
                        .padding(.horizontal, Theme.spacing)
                        
                        // Add more button
                        Button(action: addHighlightItem) {
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
                        
                        // Save button
                        Button(action: saveHighlights) {
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
                                completedItemsCount >= 1 ? Theme.successGreen : Color(red: 1.0, green: 0.6, blue: 0.4)
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
                                    .foregroundColor(completedItemsCount >= 1 ? Theme.successGreen : Color(red: 1.0, green: 0.6, blue: 0.4))
                                
                                Text("\(completedItemsCount) highlight\(completedItemsCount == 1 ? "" : "s")")
                                    .font(.system(size: 14))
                                    .foregroundColor(Theme.textSecondary)
                            }
                        }
                        
                        Spacer(minLength: 40)
                    }
                }
                .scrollDismissesKeyboard(.interactively)
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
            loadExistingHighlights()
        }
    }
    
    private var completedItemsCount: Int {
        highlightItems.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }.count
    }
    
    private func addHighlightItem() {
        highlightItems.append("")
    }
    
    private func loadExistingHighlights() {
        if let items = viewModel.loadTodayHighlightItems(), !items.isEmpty {
            highlightItems = items
        }
    }
    
    private func saveHighlights() {
        isSaving = true
        
        // Filter out empty items
        let nonEmptyItems = highlightItems.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        
        // Save highlight items
        viewModel.saveHighlightItems(nonEmptyItems)
        
        // Mark as completed if 1 or more items
        if nonEmptyItems.count >= 1 {
            viewModel.markHighlightCompleted()
        }
        
        // Small delay for visual feedback
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            isSaving = false
            dismiss()
        }
    }
}

struct HighlightTextField: View {
    let number: Int
    @Binding var text: String
    var autoFocus: Bool = false
    @FocusState private var isFocused: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("\(number).")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(Color(red: 1.0, green: 0.6, blue: 0.4))
            
            TextField("Today's highlight was...", text: $text, axis: .vertical)
                .font(.system(size: 16))
                .foregroundColor(Theme.textPrimary)
                .padding(Theme.spacing)
                .lineLimit(3...6)
                .background(Color.white)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isFocused ? Color(red: 1.0, green: 0.6, blue: 0.4) : Color.clear, lineWidth: 2)
                )
                .focused($isFocused)
                .toolbar {
                    ToolbarItemGroup(placement: .keyboard) {
                        Spacer()
                        Button("Done") { isFocused = false }
                            .fontWeight(.semibold)
                    }
                }
        }
        .padding(.vertical, 8)
        .onAppear {
            if autoFocus {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    isFocused = true
                }
            }
        }
    }
}

#Preview {
    HighlightsView(viewModel: MeditationViewModel())
}
