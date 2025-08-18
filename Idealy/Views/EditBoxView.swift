//
//  EditBoxView.swift
//  Idealy
//
//  Created by Claude Code on 17/8/2025.
//

import SwiftUI
internal import CoreData

struct EditBoxView: View {
    let box: Box
    let onBack: () -> Void
    let onSaved: () -> Void
    @Environment(\.colorPalette) private var colors
    @Environment(\.managedObjectContext) private var viewContext
    
    // Editable fields (main business model fields)
    @State private var name: String
    @State private var summary: String
    @State private var problem: String
    @State private var solution: String
    @State private var uniqueValueProposition: String
    @State private var customerSegments: String
    @State private var channels: String
    @State private var revenueStreams: String
    @State private var costs: String
    @State private var keyMetrics: String
    @State private var unfairAdvantage: String
    @State private var earlyAdopters: String
    @State private var existingAlternatives: String
    @State private var highLevelConcept: String
    
    init(box: Box, onBack: @escaping () -> Void, onSaved: @escaping () -> Void) {
        self.box = box
        self.onBack = onBack
        self.onSaved = onSaved
        
        // Initialize state with current box values
        self._name = State(initialValue: box.name ?? "")
        self._summary = State(initialValue: box.summary ?? "")
        self._problem = State(initialValue: box.problem ?? "")
        self._solution = State(initialValue: box.solution ?? "")
        self._uniqueValueProposition = State(initialValue: box.uniqueValueProposition ?? "")
        self._customerSegments = State(initialValue: box.customerSegments ?? "")
        self._channels = State(initialValue: box.channels ?? "")
        self._revenueStreams = State(initialValue: box.revenueStreams ?? "")
        self._costs = State(initialValue: box.costs ?? "")
        self._keyMetrics = State(initialValue: box.keyMetrics ?? "")
        self._unfairAdvantage = State(initialValue: box.unfairAdvantage ?? "")
        self._earlyAdopters = State(initialValue: box.earlyAdopters ?? "")
        self._existingAlternatives = State(initialValue: box.existingAlternatives ?? "")
        self._highLevelConcept = State(initialValue: box.highLevelConcept ?? "")
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
                        // Core Fields
                        boxFieldView(title: "Business Name", content: $name)
                        boxFieldView(title: "Summary", content: $summary)
                        boxFieldView(title: "Problem", content: $problem)
                        boxFieldView(title: "Solution", content: $solution)
                        boxFieldView(title: "Unique Value Proposition", content: $uniqueValueProposition)
                        
                        // Market Fields
                        boxFieldView(title: "Customer Segments", content: $customerSegments)
                        boxFieldView(title: "Early Adopters", content: $earlyAdopters)
                        boxFieldView(title: "Existing Alternatives", content: $existingAlternatives)
                        
                        // Business Model Fields
                        boxFieldView(title: "Channels", content: $channels)
                        boxFieldView(title: "Revenue Streams", content: $revenueStreams)
                        boxFieldView(title: "Costs", content: $costs)
                        boxFieldView(title: "Key Metrics", content: $keyMetrics)
                        boxFieldView(title: "Unfair Advantage", content: $unfairAdvantage)
                        boxFieldView(title: "High Level Concept", content: $highLevelConcept)
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
                    Text("Edit Box")
                        .font(.headline)
                        .foregroundColor(colors.text)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        // Haptic feedback for save button
                        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                        impactFeedback.impactOccurred()
                        saveBox()
                    }) {
                        Image(systemName: "checkmark")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.green)
                    }
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
    
    // MARK: - Field Views
    
    private func boxFieldView(title: String, content: Binding<String>) -> some View {
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
    
    // MARK: - Save Functionality
    
    private func saveBox() {
        // Update the box with new values
        box.name = name.isEmpty ? nil : name
        box.summary = summary.isEmpty ? nil : summary
        box.problem = problem.isEmpty ? nil : problem
        box.solution = solution.isEmpty ? nil : solution
        box.uniqueValueProposition = uniqueValueProposition.isEmpty ? nil : uniqueValueProposition
        box.customerSegments = customerSegments.isEmpty ? nil : customerSegments
        box.channels = channels.isEmpty ? nil : channels
        box.revenueStreams = revenueStreams.isEmpty ? nil : revenueStreams
        box.costs = costs.isEmpty ? nil : costs
        box.keyMetrics = keyMetrics.isEmpty ? nil : keyMetrics
        box.unfairAdvantage = unfairAdvantage.isEmpty ? nil : unfairAdvantage
        box.earlyAdopters = earlyAdopters.isEmpty ? nil : earlyAdopters
        box.existingAlternatives = existingAlternatives.isEmpty ? nil : existingAlternatives
        box.highLevelConcept = highLevelConcept.isEmpty ? nil : highLevelConcept
        box.modifiedDate = Date()
        
        // Save to Core Data
        do {
            try viewContext.save()
            print("✅ Successfully saved box: \(name)")
            
            // Haptic feedback
            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
            impactFeedback.impactOccurred()
            
            // Call callbacks
            onSaved()
            onBack()
        } catch {
            print("❌ Failed to save box: \(error)")
            // TODO: Show error alert to user
        }
    }
}

#Preview {
    let context = PersistenceController.preview.container.viewContext
    let sampleBox = Box(context: context)
    sampleBox.id = UUID()
    sampleBox.name = "Sample Box"
    sampleBox.summary = "This is a sample box for testing"
    sampleBox.problem = "Sample problem description"
    sampleBox.solution = "Sample solution description"
    sampleBox.createdDate = Date()
    
    return EditBoxView(box: sampleBox, onBack: {}, onSaved: {})
        .environment(\.colorPalette, ColorPalette.light)
        .environment(\.managedObjectContext, context)
}