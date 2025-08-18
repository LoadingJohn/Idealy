//
//  ReviewDumpView.swift
//  Idealy
//
//  Created by Claude Code on 15/8/2025.
//

import SwiftUI
import FoundationModels
internal import CoreData

enum DumpProcessorType {
    case appleIntelligence(AppleIntelligenceDumpProcessorVM)
    case qwen(QwenDumpProcessorVM)
    
    var processor: any DumpProcessorProtocol {
        switch self {
        case .appleIntelligence(let processor):
            return processor
        case .qwen(let processor):
            return processor
        }
    }
}

struct ReviewDumpView: View {
    @StateObject private var qwenProcessor: QwenDumpProcessorVM
    @StateObject private var appleIntelligenceProcessor: AppleIntelligenceDumpProcessorVM
    @State private var isAppleIntelligenceAvailable: Bool = false
    @Environment(\.colorPalette) private var colors
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.presentationMode) var presentationMode
    
    let dumpText: String
    let targetBox: Box
    let modelType: AIModelType
    let onIdeasSaved: (([Idea]) -> Void)?
    
    // Computed property to get the active processor
    private var activeProcessor: any DumpProcessorProtocol {
        switch modelType {
        case .appleIntelligence:
            return isAppleIntelligenceAvailable ? appleIntelligenceProcessor : qwenProcessor
        case .qwen:
            return qwenProcessor
        }
    }
    
    // Check if all fields have been generated
    private var allFieldsCompleted: Bool {
        return !activeProcessor.generatedTitle.isEmpty &&
               !activeProcessor.generatedSummary.isEmpty &&
               !activeProcessor.generatedPros.isEmpty &&
               !activeProcessor.generatedCons.isEmpty &&
               !activeProcessor.generatedClassification.isEmpty
    }
    
    // Classification options
    private let classificationOptions = [
        "Product & Engineering",
        "Marketing & Growth", 
        "Strategy & Vision",
        "Team & Operations",
        "People & Relationships",
        "Personal Development"
    ]
    
    // Helper function to create the right field view based on model type
    private func dumpFieldView(title: String, qwenKeyPath: ReferenceWritableKeyPath<QwenDumpProcessorVM, String>, appleIntelligenceKeyPath: ReferenceWritableKeyPath<AppleIntelligenceDumpProcessorVM, String>, isEditable: Bool = true) -> some View {
        if modelType == .qwen || !isAppleIntelligenceAvailable {
            // Use Qwen processor if Qwen model selected OR Apple Intelligence not available
            return AnyView(GeneratedFieldView(title: title, content: Binding(
                get: { qwenProcessor[keyPath: qwenKeyPath] },
                set: { qwenProcessor[keyPath: qwenKeyPath] = $0 }
            ), colors: colors, isEditable: isEditable))
        } else {
            // Use Apple Intelligence processor
            return AnyView(GeneratedFieldView(title: title, content: Binding(
                get: { appleIntelligenceProcessor[keyPath: appleIntelligenceKeyPath] },
                set: { appleIntelligenceProcessor[keyPath: appleIntelligenceKeyPath] = $0 }
            ), colors: colors, isEditable: isEditable))
        }
    }
    
    // Helper function for classification dropdown
    private func classificationDropdownView(isEditable: Bool = true) -> some View {
        let binding = Binding<String>(
            get: {
                if modelType == .qwen || !isAppleIntelligenceAvailable {
                    return qwenProcessor.generatedClassification
                } else {
                    return appleIntelligenceProcessor.generatedClassification
                }
            },
            set: { newValue in
                if modelType == .qwen || !isAppleIntelligenceAvailable {
                    qwenProcessor.generatedClassification = newValue
                } else {
                    appleIntelligenceProcessor.generatedClassification = newValue
                }
            }
        )
        
        return ClassificationDropdownFieldView(
            title: "Classification",
            selectedClassification: binding,
            options: classificationOptions,
            colors: colors,
            isEditable: isEditable
        )
    }
    
    init(dumpText: String, targetBox: Box, modelType: AIModelType, mlxModelManager: MLXModelManager, onIdeasSaved: (([Idea]) -> Void)? = nil) {
        self.dumpText = dumpText
        self.targetBox = targetBox
        self.modelType = modelType
        self.onIdeasSaved = onIdeasSaved
        
        // Always initialize Qwen processor
        self._qwenProcessor = StateObject(wrappedValue: QwenDumpProcessorVM(mlxModelManager: mlxModelManager))
        
        // Check Apple Intelligence availability first
        let model = SystemLanguageModel.default
        let available = model.availability == .available
        self._isAppleIntelligenceAvailable = State(initialValue: available)
        
        // Only initialize Apple Intelligence processor if available
        if available {
            self._appleIntelligenceProcessor = StateObject(wrappedValue: AppleIntelligenceDumpProcessorVM())
        } else {
            // Create a dummy processor to satisfy @StateObject requirements
            self._appleIntelligenceProcessor = StateObject(wrappedValue: AppleIntelligenceDumpProcessorVM())
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
                            if !activeProcessor.generatedTitle.isEmpty {
                                dumpFieldView(title: "Title", qwenKeyPath: \.generatedTitle, appleIntelligenceKeyPath: \.generatedTitle, isEditable: false)
                            }
                            if !activeProcessor.generatedSummary.isEmpty {
                                dumpFieldView(title: "Summary", qwenKeyPath: \.generatedSummary, appleIntelligenceKeyPath: \.generatedSummary, isEditable: false)
                            }
                            if !activeProcessor.generatedPros.isEmpty {
                                dumpFieldView(title: "Pros", qwenKeyPath: \.generatedPros, appleIntelligenceKeyPath: \.generatedPros, isEditable: false)
                            }
                            if !activeProcessor.generatedCons.isEmpty {
                                dumpFieldView(title: "Cons", qwenKeyPath: \.generatedCons, appleIntelligenceKeyPath: \.generatedCons, isEditable: false)
                            }
                            if !activeProcessor.generatedClassification.isEmpty {
                                classificationDropdownView(isEditable: false)
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
                            // Completed state - show all fields as editable
                            dumpFieldView(title: "Title", qwenKeyPath: \.generatedTitle, appleIntelligenceKeyPath: \.generatedTitle)
                            dumpFieldView(title: "Summary", qwenKeyPath: \.generatedSummary, appleIntelligenceKeyPath: \.generatedSummary)
                            dumpFieldView(title: "Pros", qwenKeyPath: \.generatedPros, appleIntelligenceKeyPath: \.generatedPros)
                            dumpFieldView(title: "Cons", qwenKeyPath: \.generatedCons, appleIntelligenceKeyPath: \.generatedCons)
                            classificationDropdownView(isEditable: true)
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
                Text(activeProcessor.isProcessing ? "Processing with \(modelType.displayName)" : (activeProcessor.generatedTitle.isEmpty ? "Dump Analysis" : "\"\(activeProcessor.generatedTitle)\""))
                    .font(.headline)
                    .foregroundColor(activeProcessor.isProcessing ? colors.text : colors.accent)
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    // Haptic feedback for save button
                    let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                    impactFeedback.impactOccurred()
                    
                    // Save the ideas manually
                    Task {
                        let savedIdeas = await activeProcessor.saveIdeasManually()
                        if !savedIdeas.isEmpty {
                            // Notify parent view about the saved ideas
                            onIdeasSaved?(savedIdeas)
                            
                            // Navigate back to NewView
                            await MainActor.run {
                                presentationMode.wrappedValue.dismiss()
                            }
                            
                            print("✅ Ideas saved successfully, navigated back to NewView")
                        }
                    }
                }) {
                    Image(systemName: "checkmark")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.accentColor)
                }
                .disabled(activeProcessor.isProcessing || !allFieldsCompleted)
            }
        }
        .onAppear {
            // Set the view context for Core Data operations and start processing
            switch modelType {
            case .appleIntelligence:
                if isAppleIntelligenceAvailable {
                    appleIntelligenceProcessor.viewContext = viewContext
                    appleIntelligenceProcessor.processDump(dumpText: dumpText, box: targetBox, modelName: modelType.displayName)
                } else {
                    // Fallback to Qwen if Apple Intelligence not available
                    print("🔄 Falling back to Qwen processor since Apple Intelligence unavailable")
                    qwenProcessor.viewContext = viewContext
                    qwenProcessor.processDump(dumpText: dumpText, box: targetBox, modelName: AIModelType.qwen.displayName)
                }
            case .qwen:
                qwenProcessor.viewContext = viewContext
                qwenProcessor.processDump(dumpText: dumpText, box: targetBox, modelName: modelType.displayName)
            }
        }
    }
}

struct ClassificationDropdownFieldView: View {
    let title: String
    @Binding var selectedClassification: String
    let options: [String]
    let colors: ColorPalette
    let isEditable: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(colors.accent)
            
            if isEditable {
                // Editable dropdown menu
                Menu {
                    ForEach(options, id: \.self) { option in
                        Button(option) {
                            selectedClassification = option
                        }
                    }
                } label: {
                    HStack {
                        Text(selectedClassification.isEmpty ? "Select category..." : selectedClassification)
                            .font(.system(size: 14))
                            .foregroundColor(selectedClassification.isEmpty ? colors.textSecondary : colors.text)
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
            } else {
                // Read-only display
                Text(selectedClassification.isEmpty ? "Generating..." : selectedClassification)
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
    let context = PersistenceController.preview.container.viewContext
    let sampleBox = Box(context: context)
    sampleBox.name = "Sample Box"
    sampleBox.id = UUID()
    sampleBox.createdDate = Date()
    
    return NavigationView {
        ReviewDumpView(
            dumpText: "Sample dump text for testing",
            targetBox: sampleBox,
            modelType: .appleIntelligence,
            mlxModelManager: MLXModelManager.shared
        )
        .environment(\.colorPalette, ColorPalette.light)
    }
}