//
//  EditIdeaView.swift
//  Idealy
//
//  Created by Claude Code on 17/8/2025.
//

import SwiftUI
internal import CoreData

struct EditIdeaView: View {
    let idea: Idea
    let onBack: () -> Void
    let onSaved: () -> Void
    let onIdeaDeleted: (() -> Void)?
    @Environment(\.colorPalette) private var colors
    @Environment(\.managedObjectContext) private var viewContext
    
    // Editable fields
    @State private var title: String
    @State private var summary: String
    @State private var pros: String
    @State private var cons: String
    @State private var classification: String
    @State private var showDeleteConfirmation = false
    
    // Classification options
    private let classificationOptions = [
        "Product & Engineering",
        "Marketing & Growth", 
        "Strategy & Vision",
        "Team & Operations",
        "People & Relationships",
        "Personal Development"
    ]
    
    init(idea: Idea, onBack: @escaping () -> Void, onSaved: @escaping () -> Void, onIdeaDeleted: (() -> Void)? = nil) {
        self.idea = idea
        self.onBack = onBack
        self.onSaved = onSaved
        self.onIdeaDeleted = onIdeaDeleted
        
        // Initialize state with current idea values
        self._title = State(initialValue: idea.title ?? "")
        self._summary = State(initialValue: idea.summary ?? "")
        self._pros = State(initialValue: idea.pros ?? "")
        self._cons = State(initialValue: idea.cons ?? "")
        self._classification = State(initialValue: idea.classification ?? "")
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                colors.background
                    .ignoresSafeArea()
                
                // Main scrollable content - full screen
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        // Title Field
                        ideaFieldView(title: "Title", content: $title)
                        
                        // Summary Field
                        ideaFieldView(title: "Summary", content: $summary)
                        
                        // Pros Field
                        ideaFieldView(title: "Pros", content: $pros)
                        
                        // Cons Field
                        ideaFieldView(title: "Cons", content: $cons)
                        
                        // Classification Dropdown
                        classificationDropdownView()
                        
                        // Delete Button at bottom
                        VStack(spacing: 16) {
                            Divider()
                                .background(colors.textSecondary.opacity(0.2))
                                .padding(.horizontal, 0)
                            
                            Button(action: {
                                // Haptic feedback for delete button
                                let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                                impactFeedback.impactOccurred()
                                showDeleteConfirmation = true
                            }) {
                                HStack {
                                    Image(systemName: "trash")
                                        .font(.system(size: 16, weight: .medium))
                                    Text("Delete Idea")
                                        .font(.system(size: 16, weight: .medium))
                                }
                                .foregroundColor(.red)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(Color.red.opacity(0.1))
                                .cornerRadius(8)
                            }
                        }
                        .padding(.top, 32)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 24)
                    .padding(.bottom, 24)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        // Haptic feedback for back button
                        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                        impactFeedback.impactOccurred()
                        onBack()
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(colors.accent)
                    }
                }
                
                ToolbarItem(placement: .principal) {
                    Text("Edit Idea")
                        .font(.headline)
                        .foregroundColor(colors.text)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        // Haptic feedback for save button
                        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                        impactFeedback.impactOccurred()
                        saveIdea()
                    }) {
                        Image(systemName: "checkmark")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.green)
                    }
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .confirmationDialog(
            "Are you sure you want to delete this idea?", 
            isPresented: $showDeleteConfirmation, 
            titleVisibility: .visible
        ) {
            Button("Delete Idea", role: .destructive) {
                deleteIdea()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This will permanently delete the idea. This action cannot be undone.")
        }
    }
    
    // MARK: - Field Views
    
    private func ideaFieldView(title: String, content: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(colors.accent)
            
            // Editable TextField with markdown support
            TextField("", text: content, axis: .vertical)
                .font(.system(size: 14))
                .foregroundColor(colors.text)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(colors.surface)
                .cornerRadius(8)
                .lineLimit(nil)
                .textFieldStyle(.plain)
        }
    }
    
    private func classificationDropdownView() -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Classification")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(colors.accent)
            
            // Editable dropdown menu
            Menu {
                ForEach(classificationOptions, id: \.self) { option in
                    Button(option) {
                        classification = option
                    }
                }
            } label: {
                HStack {
                    Text(classification.isEmpty ? "Select category..." : classification)
                        .font(.system(size: 14))
                        .foregroundColor(classification.isEmpty ? colors.textSecondary : colors.text)
                    Spacer()
                    Image(systemName: "chevron.down")
                        .font(.system(size: 12))
                        .foregroundColor(colors.textSecondary)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(colors.surface)
                .cornerRadius(8)
            }
        }
    }
    
    // MARK: - Delete Functionality
    
    private func deleteIdea() {
        // Haptic feedback for destructive action
        let notificationFeedback = UINotificationFeedbackGenerator()
        notificationFeedback.notificationOccurred(.warning)
        
        // Delete the idea
        viewContext.delete(idea)
        
        // Save changes
        do {
            try viewContext.save()
            print("✅ Successfully deleted idea: \(idea.title ?? "Untitled Idea")")
            
            // Success haptic feedback
            let successFeedback = UINotificationFeedbackGenerator()
            successFeedback.notificationOccurred(.success)
            
            // Notify parent view about the deletion
            onIdeaDeleted?()
            
            // Return to parent view
            onBack()
        } catch {
            print("❌ Failed to delete idea: \(error)")
            
            // Error haptic feedback
            let errorFeedback = UINotificationFeedbackGenerator()
            errorFeedback.notificationOccurred(.error)
            
            // TODO: Show error alert to user
        }
    }
    
    // MARK: - Save Functionality
    
    private func saveIdea() {
        // Update the idea with new values
        idea.title = title.isEmpty ? nil : title
        idea.summary = summary.isEmpty ? nil : summary
        idea.pros = pros.isEmpty ? nil : pros
        idea.cons = cons.isEmpty ? nil : cons
        idea.classification = classification.isEmpty ? nil : classification
        
        // Save to Core Data
        do {
            try viewContext.save()
            print("✅ Successfully saved idea: \(title)")
            
            // Haptic feedback
            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
            impactFeedback.impactOccurred()
            
            // Call callbacks
            onSaved()
            onBack()
        } catch {
            print("❌ Failed to save idea: \(error)")
            // TODO: Show error alert to user
        }
    }
}

#Preview {
    let context = PersistenceController.preview.container.viewContext
    let sampleIdea = Idea(context: context)
    sampleIdea.id = UUID()
    sampleIdea.title = "Sample Idea"
    sampleIdea.summary = "This is a sample idea for testing"
    sampleIdea.classification = "Product & Engineering"
    sampleIdea.createdDate = Date()
    
    return EditIdeaView(idea: sampleIdea, onBack: {}, onSaved: {})
        .environment(\.colorPalette, ColorPalette.light)
        .environment(\.managedObjectContext, context)
}