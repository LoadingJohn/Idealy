//
//  AppleIntelligenceDumpProcessorVM.swift
//  Idealy
//
//  Created by Claude Code on 17/8/2025.
//  Apple Intelligence (Foundation Models) implementation for dump processing
//

import Foundation
import SwiftUI
import Combine
import FoundationModels
internal import CoreData

@Generable
struct DumpAnalysis {
    @Guide(description: "Create a concise title for the user's specific ideas. Focus only on what the user described. Maximum 3 words or 15 characters. Do not use quotation marks.")
    var title: String
    
    @Guide(description: "Write a comprehensive 3-4 sentence summary of the user's specific ideas in relation to this business context. Explain how the user's proposals would work within the business framework and what impact they might have. Focus on what the user proposed, not the overall business.")
    var summary: String
    
    @Guide(description: "Provide a detailed analysis of the positive aspects of the user's specific ideas as they relate to this business. Include 3-4 specific benefits, advantages, or opportunities that these ideas would create. Explain why these aspects are valuable.")
    var pros: String
    
    @Guide(description: "Provide a thorough analysis of potential challenges with the user's specific ideas in this business context. Include 3-4 specific obstacles, risks, or limitations that might need to be addressed. Explain why these challenges matter and how they might impact implementation.")
    var cons: String
    
    @Guide(description: "Classify the user's ideas into ONE of these specific categories: Product & Engineering, Marketing & Growth, Strategy & Vision, Team & Operations, People & Relationships, Personal Development. Respond with only the category name.")
    var classification: String
}

@MainActor
class AppleIntelligenceDumpProcessorVM: ObservableObject, DumpProcessorProtocol {
    
    // MARK: - Published Properties
    @Published var isProcessing: Bool = false
    @Published var currentStatus: String = ""
    @Published var progress: Double = 0.0
    @Published var hasError: Bool = false
    @Published var errorMessage: String = ""
    
    // Streaming generation results for dump ideas - bindable for editing
    @Published var generatedTitle: String = ""
    @Published var generatedSummary: String = ""
    @Published var generatedPros: String = ""
    @Published var generatedCons: String = ""
    @Published var generatedClassification: String = ""
    
    // MARK: - Private Properties
    private var dumpText: String = ""
    private var targetBox: Box?
    private var modelName: String = ""
    private let model = SystemLanguageModel.default
    var viewContext: NSManagedObjectContext?
    
    // MARK: - Saved Ideas Reference
    @Published var savedIdeas: [Idea] = []
    
    // MARK: - Initialization
    init(viewContext: NSManagedObjectContext? = nil) {
        self.viewContext = viewContext
    }
    
    // MARK: - Public Methods
    
    /// Process dump text to create structured Idea entities within existing Box using Apple Intelligence
    /// - Parameters:
    ///   - dumpText: The raw dump content to process
    ///   - box: The target Box to add ideas to
    ///   - modelName: The AI model to use (should be "Apple Intelligence")
    func processDump(dumpText: String, box: Box, modelName: String) {
        print("🍎 AppleIntelligenceDumpProcessorVM: Starting Apple Intelligence dump processing")
        print("   Dump Text: \(dumpText)")
        print("   Target Box: \(box.name ?? "Unnamed")")
        print("   Model: \(modelName)")
        
        self.dumpText = dumpText
        self.targetBox = box
        self.modelName = modelName
        
        // Reset state
        isProcessing = true
        hasError = false
        errorMessage = ""
        currentStatus = "Connecting to Apple Intelligence..."
        progress = 0.0
        
        // Clear all generated fields
        resetGeneratedFields()
        
        // Start Apple Intelligence processing
        processWithAppleIntelligence()
    }
    
    // MARK: - Private Processing Methods
    
    private func processWithAppleIntelligence() {
        print("🍎 Processing dump with Apple Intelligence...")
        currentStatus = "Analyzing dump content..."
        progress = 0.1
        
        Task {
            do {
                // Check if Apple Intelligence is available
                guard model.availability == .available else {
                    await MainActor.run {
                        self.handleError("Apple Intelligence is not available on this device")
                    }
                    return
                }
                
                await MainActor.run {
                    self.currentStatus = "Using Apple Intelligence..."
                    self.progress = 0.2
                }
                
                // Generate structured dump analysis using @guidance approach
                try await generateStructuredDumpAnalysisWithGuidance()
                
            } catch {
                await MainActor.run {
                    self.handleError("Apple Intelligence processing failed: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func generateStructuredDumpAnalysisWithGuidance() async throws {
        await MainActor.run {
            self.currentStatus = "Generating dump analysis..."
            self.progress = 0.1
        }
        
        // Build context from the target box
        var contextString = ""
        if let box = targetBox {
            contextString = """
            
            === BOX CONTEXT ===
            Box Name: \(box.name ?? "Unnamed")
            Problem: \(box.problem ?? "")
            Solution: \(box.solution ?? "")
            Customer Segments: \(box.customerSegments ?? "")
            Unique Value Proposition: \(box.uniqueValueProposition ?? "")
            """
        }
        
        // Create the dump analysis prompt focused on user's specific ideas
        let dumpAnalysisPrompt = """
        User's Ideas: \(dumpText)\(contextString)
        
        Analyze the user's specific ideas in relation to the business context provided. Focus on what the user proposed, not the overall business concept.
        """
        
        print("🍎 Starting streaming guided generation for dump analysis")
        
        // Create language model session
        let session = LanguageModelSession(model: model)
        
        // Configure generation options with proper max tokens
        let generationOptions = GenerationOptions(
            temperature: 0.3,
            maximumResponseTokens: 2000
        )
        
        // Use streaming guided generation with @Generable structure
        let response = try await session.streamResponse(
            to: dumpAnalysisPrompt,
            generating: DumpAnalysis.self,
            options: generationOptions
        )
        
        // Stream the results field by field
        for try await partialResult in response {
            await MainActor.run {
                // Update individual fields as they become available
                if let title = partialResult.title, !title.isEmpty {
                    self.updateGeneratedField(field: "title", content: title)
                }
                if let summary = partialResult.summary, !summary.isEmpty {
                    self.updateGeneratedField(field: "summary", content: summary)
                }
                if let pros = partialResult.pros, !pros.isEmpty {
                    self.updateGeneratedField(field: "pros", content: pros)
                }
                if let cons = partialResult.cons, !cons.isEmpty {
                    self.updateGeneratedField(field: "cons", content: cons)
                }
                if let classification = partialResult.classification, !classification.isEmpty {
                    self.updateGeneratedField(field: "classification", content: classification)
                }
                
                // Update progress based on filled fields
                let totalFields = 5.0
                var filledFields = 0.0
                if let title = partialResult.title, !title.isEmpty { filledFields += 1 }
                if let summary = partialResult.summary, !summary.isEmpty { filledFields += 1 }
                if let pros = partialResult.pros, !pros.isEmpty { filledFields += 1 }
                if let cons = partialResult.cons, !cons.isEmpty { filledFields += 1 }
                if let classification = partialResult.classification, !classification.isEmpty { filledFields += 1 }
                
                self.progress = min(0.9, 0.1 + (filledFields / totalFields) * 0.8)
                self.currentStatus = "Generating field \(Int(filledFields + 1)) of \(Int(totalFields))..."
            }
            
            // Haptic feedback for each field completion
            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
            impactFeedback.impactOccurred()
        }
        
        await MainActor.run {
            self.currentStatus = "Apple Intelligence dump analysis complete!"
            self.progress = 1.0
            self.isProcessing = false
            
            // Special haptic feedback for completion
            let notificationFeedback = UINotificationFeedbackGenerator()
            notificationFeedback.notificationOccurred(.success)
        }
    }
    
    private func updateGeneratedField(field: String, content: String) {
        // Update the specific published property for this field
        switch field {
        case "title":
            if generatedTitle != content {
                generatedTitle = content
                objectWillChange.send()
            }
        case "summary":
            if generatedSummary != content {
                generatedSummary = content
                objectWillChange.send()
            }
        case "pros":
            if generatedPros != content {
                generatedPros = content
                objectWillChange.send()
            }
        case "cons":
            if generatedCons != content {
                generatedCons = content
                objectWillChange.send()
            }
        case "classification":
            if generatedClassification != content {
                generatedClassification = content
                objectWillChange.send()
            }
        default:
            print("⚠️ Unknown field: \(field)")
            break
        }
        
        print("🍎 AI DUMP FIELD UPDATE \(field): \(content.count) chars")
    }
    
    // MARK: - Manual Save Method
    func saveIdeasManually() async -> [Idea] {
        guard let context = viewContext, let box = targetBox else {
            print("⚠️ No Core Data context or target box available, cannot save Ideas")
            return []
        }
        
        return await MainActor.run {
            let newIdea = Idea(context: context)
            newIdea.id = UUID()
            newIdea.title = self.generatedTitle
            newIdea.summary = self.generatedSummary
            newIdea.pros = self.generatedPros
            newIdea.cons = self.generatedCons
            newIdea.classification = self.generatedClassification
            newIdea.createdDate = Date()
            newIdea.box = box
            
            do {
                try context.save()
                print("✅ Apple Intelligence: Successfully saved Idea: \(self.generatedTitle)")
                let savedIdeas = [newIdea]
                self.savedIdeas = savedIdeas
                return savedIdeas
            } catch {
                print("❌ Apple Intelligence: Failed to save Idea: \(error)")
                self.handleError("Failed to save Idea: \(error.localizedDescription)")
                return []
            }
        }
    }
    
    // MARK: - Error Handling
    
    private func handleError(_ message: String) {
        print("❌ AppleIntelligenceDumpProcessorVM Error: \(message)")
        hasError = true
        errorMessage = message
        isProcessing = false
        currentStatus = "Error occurred"
    }
    
    // MARK: - Utility Methods
    
    private func resetGeneratedFields() {
        generatedTitle = ""
        generatedSummary = ""
        generatedPros = ""
        generatedCons = ""
        generatedClassification = ""
    }
    
    func resetState() {
        isProcessing = false
        currentStatus = ""
        progress = 0.0
        hasError = false
        errorMessage = ""
        dumpText = ""
        targetBox = nil
        modelName = ""
        
        resetGeneratedFields()
    }
}