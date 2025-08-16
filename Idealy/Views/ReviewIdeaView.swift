//
//  ReviewIdeaView.swift
//  Idealy
//
//  Created by Claude Code on 10/8/2025.
//

import SwiftUI
internal import CoreData

struct ReviewIdeaView: View {
    @StateObject private var ideaProcessor: IdeaProcessorVM
    @Environment(\.colorPalette) private var colors
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.presentationMode) var presentationMode
    @StateObject private var mlxModelManager: MLXModelManager
    
    let title: String
    let content: String
    let modelName: String
    let onBoxSaved: ((Box) -> Void)?
    
    init(title: String, content: String, modelName: String, mlxModelManager: MLXModelManager, onBoxSaved: ((Box) -> Void)? = nil) {
        self.title = title
        self.content = content
        self.modelName = modelName
        self.onBoxSaved = onBoxSaved
        
        // Initialize the ideaProcessor with the passed MLXModelManager
        self._ideaProcessor = StateObject(wrappedValue: IdeaProcessorVM(mlxModelManager: mlxModelManager))
        self._mlxModelManager = StateObject(wrappedValue: mlxModelManager)
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background
                colors.background
                    .ignoresSafeArea()
                
                // Main scrollable content - full screen
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        // Processing state - show content as it streams
                        if ideaProcessor.isProcessing {
                            // SUMMARY FIRST
                            if !ideaProcessor.generatedSummary.isEmpty {
                                GeneratedFieldView(title: "Summary", content: $ideaProcessor.generatedSummary, colors: colors, isEditable: false)
                            }
                            if !ideaProcessor.generatedProblem.isEmpty {
                                GeneratedFieldView(title: "Problem", content: $ideaProcessor.generatedProblem, colors: colors, isEditable: false)
                            }
                            if !ideaProcessor.generatedSolution.isEmpty {
                                GeneratedFieldView(title: "Solution", content: $ideaProcessor.generatedSolution, colors: colors, isEditable: false)
                            }
                            if !ideaProcessor.generatedUniqueValueProposition.isEmpty {
                                GeneratedFieldView(title: "Unique Value Proposition", content: $ideaProcessor.generatedUniqueValueProposition, colors: colors, isEditable: false)
                            }
                            if !ideaProcessor.generatedCustomerSegments.isEmpty {
                                GeneratedFieldView(title: "Customer Segments", content: $ideaProcessor.generatedCustomerSegments, colors: colors, isEditable: false)
                            }
                            if !ideaProcessor.generatedChannels.isEmpty {
                                GeneratedFieldView(title: "Channels", content: $ideaProcessor.generatedChannels, colors: colors, isEditable: false)
                            }
                            if !ideaProcessor.generatedRevenueStreams.isEmpty {
                                GeneratedFieldView(title: "Revenue Streams", content: $ideaProcessor.generatedRevenueStreams, colors: colors, isEditable: false)
                            }
                            if !ideaProcessor.generatedCosts.isEmpty {
                                GeneratedFieldView(title: "Costs", content: $ideaProcessor.generatedCosts, colors: colors, isEditable: false)
                            }
                            if !ideaProcessor.generatedKeyMetrics.isEmpty {
                                GeneratedFieldView(title: "Key Metrics", content: $ideaProcessor.generatedKeyMetrics, colors: colors, isEditable: false)
                            }
                            if !ideaProcessor.generatedUnfairAdvantage.isEmpty {
                                GeneratedFieldView(title: "Unfair Advantage", content: $ideaProcessor.generatedUnfairAdvantage, colors: colors, isEditable: false)
                            }
                            if !ideaProcessor.generatedEarlyAdopters.isEmpty {
                                GeneratedFieldView(title: "Early Adopters", content: $ideaProcessor.generatedEarlyAdopters, colors: colors, isEditable: false)
                            }
                            if !ideaProcessor.generatedExistingAlternatives.isEmpty {
                                GeneratedFieldView(title: "Existing Alternatives", content: $ideaProcessor.generatedExistingAlternatives, colors: colors, isEditable: false)
                            }
                            if !ideaProcessor.generatedHighLevelConcept.isEmpty {
                                GeneratedFieldView(title: "High Level Concept", content: $ideaProcessor.generatedHighLevelConcept, colors: colors, isEditable: false)
                            }
                        } else if ideaProcessor.hasError {
                            // Error state
                            VStack(spacing: 24) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .font(.system(size: 64))
                                    .foregroundColor(.red)
                                
                                VStack(spacing: 12) {
                                    Text("Processing Error")
                                        .font(.system(size: 24, weight: .semibold))
                                        .foregroundColor(colors.text)
                                    
                                    Text(ideaProcessor.errorMessage)
                                        .font(.system(size: 16))
                                        .foregroundColor(colors.textSecondary)
                                        .multilineTextAlignment(.center)
                                        .lineLimit(nil)
                                }
                            }
                            .padding(.horizontal, 32)
                        } else {
                            // Completed state - show all fields as editable, SUMMARY FIRST
                            GeneratedFieldView(title: "Summary", content: $ideaProcessor.generatedSummary, colors: colors)
                            GeneratedFieldView(title: "Problem", content: $ideaProcessor.generatedProblem, colors: colors)
                            GeneratedFieldView(title: "Solution", content: $ideaProcessor.generatedSolution, colors: colors)
                            GeneratedFieldView(title: "Unique Value Proposition", content: $ideaProcessor.generatedUniqueValueProposition, colors: colors)
                            GeneratedFieldView(title: "Customer Segments", content: $ideaProcessor.generatedCustomerSegments, colors: colors)
                            GeneratedFieldView(title: "Channels", content: $ideaProcessor.generatedChannels, colors: colors)
                            GeneratedFieldView(title: "Revenue Streams", content: $ideaProcessor.generatedRevenueStreams, colors: colors)
                            GeneratedFieldView(title: "Costs", content: $ideaProcessor.generatedCosts, colors: colors)
                            GeneratedFieldView(title: "Key Metrics", content: $ideaProcessor.generatedKeyMetrics, colors: colors)
                            GeneratedFieldView(title: "Unfair Advantage", content: $ideaProcessor.generatedUnfairAdvantage, colors: colors)
                            GeneratedFieldView(title: "Early Adopters", content: $ideaProcessor.generatedEarlyAdopters, colors: colors)
                            GeneratedFieldView(title: "Existing Alternatives", content: $ideaProcessor.generatedExistingAlternatives, colors: colors)
                            GeneratedFieldView(title: "High Level Concept", content: $ideaProcessor.generatedHighLevelConcept, colors: colors)
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, ideaProcessor.isProcessing ? 120 : 24) // Dynamic padding based on processing state
                    .padding(.bottom, 24)
                }
                
                // Floating glass elements overlay - only show during processing
                if ideaProcessor.isProcessing {
                    VStack {
                        // Progress bar
                        ProgressView(value: ideaProcessor.progress)
                            .progressViewStyle(LinearProgressViewStyle(tint: colors.accent))
                            .background(Material.ultraThinMaterial)
                            .padding(.horizontal, 24)
                            .padding(.top, 8)
                        
                        // Status section with liquid glass background
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(ideaProcessor.currentStatus)
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(colors.text)
                                
                                Text("Using \(modelName)")
                                    .font(.caption)
                                    .foregroundColor(colors.textSecondary)
                            }
                            Spacer()
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(Material.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
                        .padding(.horizontal, 24)
                        .padding(.top, 8)
                        
                        Spacer()
                    }
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(false)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text(ideaProcessor.isProcessing ? "Processing with \(modelName)" : "\"\(title)\"")
                    .font(.headline)
                    .foregroundColor(ideaProcessor.isProcessing ? colors.text : colors.accent)
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    // Haptic feedback for save button
                    let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                    impactFeedback.impactOccurred()
                    
                    // Save the box manually
                    Task {
                        if let savedBox = await ideaProcessor.saveBoxManually() {
                            // Notify parent view about the saved box
                            onBoxSaved?(savedBox)
                            
                            // Navigate back to NewView
                            await MainActor.run {
                                presentationMode.wrappedValue.dismiss()
                            }
                            
                            print("✅ Box saved successfully, navigated back to NewView")
                        }
                    }
                }) {
                    Image(systemName: "checkmark")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.green)
                }
                .disabled(ideaProcessor.isProcessing) // Disable during processing
            }
        }
        .onAppear {
            // Set the view context for Core Data operations
            ideaProcessor.viewContext = viewContext
            ideaProcessor.processIdea(title: title, content: content, modelName: modelName)
        }
    }
}


struct GeneratedFieldView: View {
    let title: String
    @Binding var content: String
    let colors: ColorPalette
    let isEditable: Bool
    
    init(title: String, content: Binding<String>, colors: ColorPalette, isEditable: Bool = true) {
        self.title = title
        self._content = content
        self.colors = colors
        self.isEditable = isEditable
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(colors.accent)
            
            if isEditable {
                // Editable TextField with markdown support
                TextField("", text: $content, axis: .vertical)
                    .font(.system(size: 14))
                    .foregroundColor(colors.text)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(colors.surface)
                    .cornerRadius(8)
                    .lineLimit(nil)
                    .textFieldStyle(.plain)
            } else {
                // Read-only with markdown rendering
                Text(try! AttributedString(markdown: content))
                    .font(.system(size: 14))
                    .foregroundColor(colors.text)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(colors.surface)
                    .cornerRadius(8)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
}

#Preview {
    NavigationView {
        ReviewIdeaView(
            title: "Sample Idea",
            content: "This is a sample idea content for testing",
            modelName: "Apple Intelligence",
            mlxModelManager: MLXModelManager.shared,
            onBoxSaved: nil
        )
        .environment(\.colorPalette, ColorPalette.light)
    }
}
