//
//  ReviewIdeaView.swift
//  Idealy
//
//  Created by Claude Code on 10/8/2025.
//

import SwiftUI
import FoundationModels
internal import CoreData

enum ProcessorType {
    case appleIntelligence(AppleIntelligenceIdeaProcessorVM)
    case qwen(QwenIdeaProcessorVM)
    
    var processor: any IdeaProcessorProtocol {
        switch self {
        case .appleIntelligence(let processor):
            return processor
        case .qwen(let processor):
            return processor
        }
    }
}

struct ReviewIdeaView: View {
    @StateObject private var qwenProcessor: QwenIdeaProcessorVM
    @State private var appleIntelligenceProcessor: AppleIntelligenceIdeaProcessorVM?
    @Environment(\.colorPalette) private var colors
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.presentationMode) var presentationMode
    
    let title: String
    let content: String
    let modelType: AIModelType
    let onBoxSaved: ((Box) -> Void)?
    
    // Computed property to get the active processor
    private var activeProcessor: any IdeaProcessorProtocol {
        switch modelType {
        case .appleIntelligence:
            return appleIntelligenceProcessor ?? qwenProcessor // Fallback to Qwen if Apple Intelligence not available
        case .qwen:
            return qwenProcessor
        }
    }
    
    // Helper function to create the right field view based on model type
    private func fieldView(title: String, qwenKeyPath: ReferenceWritableKeyPath<QwenIdeaProcessorVM, String>, appleIntelligenceKeyPath: ReferenceWritableKeyPath<AppleIntelligenceIdeaProcessorVM, String>, isEditable: Bool = true) -> some View {
        if modelType == .qwen || appleIntelligenceProcessor == nil {
            // Use Qwen processor if Qwen model selected OR Apple Intelligence not available
            return AnyView(GeneratedFieldView(title: title, content: Binding(
                get: { qwenProcessor[keyPath: qwenKeyPath] },
                set: { qwenProcessor[keyPath: qwenKeyPath] = $0 }
            ), colors: colors, isEditable: isEditable))
        } else {
            // Use Apple Intelligence processor
            return AnyView(GeneratedFieldView(title: title, content: Binding(
                get: { appleIntelligenceProcessor![keyPath: appleIntelligenceKeyPath] },
                set: { appleIntelligenceProcessor![keyPath: appleIntelligenceKeyPath] = $0 }
            ), colors: colors, isEditable: isEditable))
        }
    }
    
    init(title: String, content: String, modelType: AIModelType, mlxModelManager: MLXModelManager, onBoxSaved: ((Box) -> Void)? = nil) {
        self.title = title
        self.content = content
        self.modelType = modelType
        self.onBoxSaved = onBoxSaved
        
        // Always initialize Qwen processor
        self._qwenProcessor = StateObject(wrappedValue: QwenIdeaProcessorVM(mlxModelManager: mlxModelManager))
        
        // Check Apple Intelligence availability before initializing
        let model = SystemLanguageModel.default
        let isAppleIntelligenceAvailable = model.availability == .available
        
        if modelType == .appleIntelligence && isAppleIntelligenceAvailable {
            self._appleIntelligenceProcessor = State(initialValue: AppleIntelligenceIdeaProcessorVM())
        } else {
            // Don't create Apple Intelligence processor if not available - this prevents crashes
            self._appleIntelligenceProcessor = State(initialValue: nil)
            if modelType == .appleIntelligence {
                print("⚠️ Apple Intelligence requested but not available - device: \(model.availability). Using Qwen fallback.")
            }
        }
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
                        if activeProcessor.isProcessing {
                            // SUMMARY FIRST
                            if !activeProcessor.generatedSummary.isEmpty {
                                fieldView(title: "Summary", qwenKeyPath: \.generatedSummary, appleIntelligenceKeyPath: \.generatedSummary, isEditable: false)
                            }
                            if !activeProcessor.generatedProblem.isEmpty {
                                fieldView(title: "Problem", qwenKeyPath: \.generatedProblem, appleIntelligenceKeyPath: \.generatedProblem, isEditable: false)
                            }
                            if !activeProcessor.generatedSolution.isEmpty {
                                fieldView(title: "Solution", qwenKeyPath: \.generatedSolution, appleIntelligenceKeyPath: \.generatedSolution, isEditable: false)
                            }
                            if !activeProcessor.generatedUniqueValueProposition.isEmpty {
                                fieldView(title: "Unique Value Proposition", qwenKeyPath: \.generatedUniqueValueProposition, appleIntelligenceKeyPath: \.generatedUniqueValueProposition, isEditable: false)
                            }
                            if !activeProcessor.generatedCustomerSegments.isEmpty {
                                fieldView(title: "Customer Segments", qwenKeyPath: \.generatedCustomerSegments, appleIntelligenceKeyPath: \.generatedCustomerSegments, isEditable: false)
                            }
                            if !activeProcessor.generatedChannels.isEmpty {
                                fieldView(title: "Channels", qwenKeyPath: \.generatedChannels, appleIntelligenceKeyPath: \.generatedChannels, isEditable: false)
                            }
                            if !activeProcessor.generatedRevenueStreams.isEmpty {
                                fieldView(title: "Revenue Streams", qwenKeyPath: \.generatedRevenueStreams, appleIntelligenceKeyPath: \.generatedRevenueStreams, isEditable: false)
                            }
                            if !activeProcessor.generatedCosts.isEmpty {
                                fieldView(title: "Costs", qwenKeyPath: \.generatedCosts, appleIntelligenceKeyPath: \.generatedCosts, isEditable: false)
                            }
                            if !activeProcessor.generatedKeyMetrics.isEmpty {
                                fieldView(title: "Key Metrics", qwenKeyPath: \.generatedKeyMetrics, appleIntelligenceKeyPath: \.generatedKeyMetrics, isEditable: false)
                            }
                            if !activeProcessor.generatedUnfairAdvantage.isEmpty {
                                fieldView(title: "Unfair Advantage", qwenKeyPath: \.generatedUnfairAdvantage, appleIntelligenceKeyPath: \.generatedUnfairAdvantage, isEditable: false)
                            }
                            if !activeProcessor.generatedEarlyAdopters.isEmpty {
                                fieldView(title: "Early Adopters", qwenKeyPath: \.generatedEarlyAdopters, appleIntelligenceKeyPath: \.generatedEarlyAdopters, isEditable: false)
                            }
                            if !activeProcessor.generatedExistingAlternatives.isEmpty {
                                fieldView(title: "Existing Alternatives", qwenKeyPath: \.generatedExistingAlternatives, appleIntelligenceKeyPath: \.generatedExistingAlternatives, isEditable: false)
                            }
                            if !activeProcessor.generatedHighLevelConcept.isEmpty {
                                fieldView(title: "High Level Concept", qwenKeyPath: \.generatedHighLevelConcept, appleIntelligenceKeyPath: \.generatedHighLevelConcept, isEditable: false)
                            }
                        } else if activeProcessor.hasError {
                            // Error state
                            VStack(spacing: 24) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .font(.system(size: 64))
                                    .foregroundColor(.red)
                                
                                VStack(spacing: 12) {
                                    Text("Processing Error")
                                        .font(.system(size: 24, weight: .semibold))
                                        .foregroundColor(colors.text)
                                    
                                    Text(activeProcessor.errorMessage)
                                        .font(.system(size: 16))
                                        .foregroundColor(colors.textSecondary)
                                        .multilineTextAlignment(.center)
                                        .lineLimit(nil)
                                }
                            }
                            .padding(.horizontal, 32)
                        } else {
                            // Completed state - show all fields as editable, SUMMARY FIRST
                            fieldView(title: "Summary", qwenKeyPath: \.generatedSummary, appleIntelligenceKeyPath: \.generatedSummary)
                            fieldView(title: "Problem", qwenKeyPath: \.generatedProblem, appleIntelligenceKeyPath: \.generatedProblem)
                            fieldView(title: "Solution", qwenKeyPath: \.generatedSolution, appleIntelligenceKeyPath: \.generatedSolution)
                            fieldView(title: "Unique Value Proposition", qwenKeyPath: \.generatedUniqueValueProposition, appleIntelligenceKeyPath: \.generatedUniqueValueProposition)
                            fieldView(title: "Customer Segments", qwenKeyPath: \.generatedCustomerSegments, appleIntelligenceKeyPath: \.generatedCustomerSegments)
                            fieldView(title: "Channels", qwenKeyPath: \.generatedChannels, appleIntelligenceKeyPath: \.generatedChannels)
                            fieldView(title: "Revenue Streams", qwenKeyPath: \.generatedRevenueStreams, appleIntelligenceKeyPath: \.generatedRevenueStreams)
                            fieldView(title: "Costs", qwenKeyPath: \.generatedCosts, appleIntelligenceKeyPath: \.generatedCosts)
                            fieldView(title: "Key Metrics", qwenKeyPath: \.generatedKeyMetrics, appleIntelligenceKeyPath: \.generatedKeyMetrics)
                            fieldView(title: "Unfair Advantage", qwenKeyPath: \.generatedUnfairAdvantage, appleIntelligenceKeyPath: \.generatedUnfairAdvantage)
                            fieldView(title: "Early Adopters", qwenKeyPath: \.generatedEarlyAdopters, appleIntelligenceKeyPath: \.generatedEarlyAdopters)
                            fieldView(title: "Existing Alternatives", qwenKeyPath: \.generatedExistingAlternatives, appleIntelligenceKeyPath: \.generatedExistingAlternatives)
                            fieldView(title: "High Level Concept", qwenKeyPath: \.generatedHighLevelConcept, appleIntelligenceKeyPath: \.generatedHighLevelConcept)
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, activeProcessor.isProcessing ? 120 : 24) // Dynamic padding based on processing state
                    .padding(.bottom, 24)
                }
                
                // Floating glass elements overlay - only show during processing
                if activeProcessor.isProcessing {
                    VStack {
                        // Progress bar
                        ProgressView(value: activeProcessor.progress)
                            .progressViewStyle(LinearProgressViewStyle(tint: colors.accent))
                            .background(Material.ultraThinMaterial)
                            .padding(.horizontal, 24)
                            .padding(.top, 8)
                        
                        // Status section with liquid glass background
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(activeProcessor.currentStatus)
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(colors.text)
                                
                                Text("Using \(modelType.displayName)")
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
                Text(activeProcessor.isProcessing ? "Processing with \(modelType.displayName)" : "\"\(title)\"")
                    .font(.headline)
                    .foregroundColor(activeProcessor.isProcessing ? colors.text : colors.accent)
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    // Haptic feedback for save button
                    let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                    impactFeedback.impactOccurred()
                    
                    // Save the box manually
                    Task {
                        if let savedBox = await activeProcessor.saveBoxManually() {
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
                .disabled(activeProcessor.isProcessing) // Disable during processing
            }
        }
        .onAppear {
            // Set the view context for Core Data operations and start processing
            switch modelType {
            case .appleIntelligence:
                if let appleProcessor = appleIntelligenceProcessor {
                    appleProcessor.viewContext = viewContext
                    appleProcessor.processIdea(title: title, content: content, modelName: modelType.displayName)
                } else {
                    // Fallback to Qwen if Apple Intelligence not available
                    print("🔄 Falling back to Qwen processor since Apple Intelligence unavailable")
                    qwenProcessor.viewContext = viewContext
                    qwenProcessor.processIdea(title: title, content: content, modelName: AIModelType.qwen.displayName)
                }
            case .qwen:
                qwenProcessor.viewContext = viewContext
                qwenProcessor.processIdea(title: title, content: content, modelName: modelType.displayName)
            }
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
            modelType: .appleIntelligence,
            mlxModelManager: MLXModelManager.shared,
            onBoxSaved: nil
        )
        .environment(\.colorPalette, ColorPalette.light)
    }
}
