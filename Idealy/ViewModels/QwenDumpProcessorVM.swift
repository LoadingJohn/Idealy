//
//  QwenDumpProcessorVM.swift
//  Idealy
//
//  Created by Claude Code on 17/8/2025.
//

import Foundation
import SwiftUI
import Combine
internal import CoreData

class QwenDumpProcessorVM: ObservableObject, DumpProcessorProtocol {
    
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
    private var mlxModelManager: MLXModelManager
    var viewContext: NSManagedObjectContext?
    
    // MARK: - Saved Ideas Reference
    @Published var savedIdeas: [Idea] = []
    
    // MARK: - Initialization
    init(mlxModelManager: MLXModelManager = MLXModelManager(), viewContext: NSManagedObjectContext? = nil) {
        self.mlxModelManager = mlxModelManager
        self.viewContext = viewContext
    }
    
    // MARK: - Public Methods
    
    /// Process dump text to create structured Idea entities within existing Box
    /// - Parameters:
    ///   - dumpText: The raw dump content to process
    ///   - box: The target Box to add ideas to
    ///   - modelName: The AI model to use ("Apple Intelligence" or "Qwen2.5-1.5B")
    func processDump(dumpText: String, box: Box, modelName: String) {
        print("🎯 QwenDumpProcessorVM: Starting dump processing")
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
        currentStatus = "Preparing to analyze dump..."
        progress = 0.0
        
        // Clear all generated fields
        resetGeneratedFields()
        
        // This ViewModel only handles Qwen
        if modelName == "Qwen2.5-1.5B" {
            processWithQwen()
        } else {
            handleError("QwenDumpProcessorVM can only handle Qwen2.5-1.5B model, not \(modelName)")
        }
    }
    
    // MARK: - Private Processing Methods
    
    private func processWithQwen() {
        print("🧠 Processing with Qwen2.5-1.5B...")
        currentStatus = "Loading Qwen2.5-1.5B model..."
        
        Task {
            do {
                // Check if model is ready
                guard mlxModelManager.isModelReady else {
                    await MainActor.run {
                        self.handleError("Qwen2.5-1.5B model is not ready. Please ensure the model is downloaded.")
                    }
                    return
                }
                
                await MainActor.run {
                    self.currentStatus = "Analyzing dump content..."
                    self.progress = 0.1
                }
                
                await MainActor.run {
                    self.currentStatus = "Processing with Qwen2.5-1.5B..."
                    self.progress = 0.2
                }
                
                // Generate structured idea analysis using field-by-field approach
                try await generateStructuredIdeaAnalysis()
                
            } catch {
                await MainActor.run {
                    self.handleError("Qwen2.5-1.5B processing failed: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func generateStructuredIdeaAnalysis() async throws {
        // Generate EACH field as a SEPARATE chat/inference with constrained token limits
        let fields = [
            ("title", 40),           // Brief title for the dump - SEPARATE CHAT
            ("summary", 80),         // Core summary - SEPARATE CHAT
            ("pros", 60),           // Positive aspects - SEPARATE CHAT
            ("cons", 60),           // Negative aspects - SEPARATE CHAT
            ("classification", 30)   // Category/type - SEPARATE CHAT
        ]
        
        let totalFields = Double(fields.count)
        
        // EACH FIELD GETS ITS OWN SEPARATE MLX INFERENCE CALL
        for (index, (field, maxTokens)) in fields.enumerated() {
            await MainActor.run {
                self.currentStatus = "Generating \(field.replacingOccurrences(of: "([a-z])([A-Z])", with: "$1 $2", options: .regularExpression))..."
                self.progress = Double(index) / totalFields
                
                // Clear the field before starting generation
                self.updateGeneratedField(field: field, content: "")
            }
            
            let (systemPrompt, userPrompt) = createStructuredDumpPrompts(field: field, dumpText: dumpText, boxContext: targetBox)
            print("📝 🆕 NEW CHAT for \(field)")
            print("   System: \(systemPrompt.prefix(50))...")
            print("   User: \(userPrompt.prefix(50))...")
            
            // SEPARATE MLX INFERENCE CALL FOR THIS FIELD ONLY
            let result = try await mlxModelManager.generateText(
                systemPrompt: systemPrompt,
                userPrompt: userPrompt,
                maxTokens: maxTokens, 
                temperature: 0.3
            ) { streamingText in
                // IMMEDIATE UI UPDATE - NO ASYNC DISPATCH
                print("🔥 STREAMING \(field): \(streamingText.count) chars")
                
                // Direct update since we removed DispatchQueue from MLXModelManager
                Task { @MainActor in
                    self.updateGeneratedField(field: field, content: streamingText)
                    print("✅ UI updated for \(field): \(streamingText.count) chars")
                }
            }
            
            // Ensure final result is set and complete
            await MainActor.run {
                self.updateGeneratedField(field: field, content: result)
                print("✅ Field '\(field)' COMPLETE: \(result.count) characters total")
                print("📋 Final content: '\(result)'")
                
                // Haptic feedback for completed field
                let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                impactFeedback.impactOccurred()
            }
            
            // Small delay between separate chats
            try await Task.sleep(nanoseconds: 300_000_000) // 0.3 seconds
        }
        
        await MainActor.run {
            self.currentStatus = "Dump analysis complete!"
            self.progress = 1.0
            self.isProcessing = false
            
            // Special haptic feedback for completion of all segments
            let notificationFeedback = UINotificationFeedbackGenerator()
            notificationFeedback.notificationOccurred(.success)
        }
    }
    
    private func createStructuredDumpPrompts(field: String, dumpText: String, boxContext: Box?) -> (systemPrompt: String, userPrompt: String) {
        // Build limited context from the target box (only essential fields)
        var contextString = ""
        if let box = boxContext {
            contextString = """
            
            === BACKGROUND INFORMATION ===
            Business Summary: \(box.summary ?? "")
            Core Problem: \(box.problem ?? "")
            Current Solution: \(box.solution ?? "")
            
            Note: This is background context. Focus on analyzing the user's input and how it relates to or could integrate with this business.
            """
        }
        
        let systemPrompt = """
        You are an idea analysis expert. Generate concise, specific content for idea components. 
        Keep responses focused and relevant to the given dump content and box context. 
        IMPORTANT: Do not use quotation marks, markdown formatting, headers, or structured text.
        Provide direct, plain text responses only. Keep responses to 1-3 sentences maximum.
        Do not include quotes, bullet points, or any special formatting.
        Stop immediately after providing the answer. Do not repeat or continue generating.
        """
        
        let userPrompt: String
        
        switch field {
        case "title":
            userPrompt = "User's idea: \(dumpText)\(contextString)\n\nGenerate a concise title for the user's specific idea. Focus only on what the user described. Maximum 3 words or 15 characters. Do not use quotes around the title:"
            
        case "summary":
            userPrompt = "User's idea: \(dumpText)\(contextString)\n\nSummarize the user's specific ideas in relation to this business context. Focus on what the user proposed:"
            
        case "pros":
            userPrompt = "User's idea: \(dumpText)\(contextString)\n\nIdentify the positive aspects of the user's specific ideas as they relate to this business:"
            
        case "cons":
            userPrompt = "User's idea: \(dumpText)\(contextString)\n\nIdentify potential challenges with the user's specific ideas in this business context:"
            
        case "classification":
            userPrompt = "User's idea: \(dumpText)\(contextString)\n\nClassify the user's ideas into ONE category: Product & Engineering, Marketing & Growth, Strategy & Vision, Team & Operations, People & Relationships, Personal Development. Answer with the category name only, no quotes:"
            
        default:
            userPrompt = "User's idea: \(dumpText)\(contextString)\n\nAnalyze the \(field) aspect of the user's ideas:"
        }
        
        return (systemPrompt: systemPrompt, userPrompt: userPrompt)
    }
    
    // Helper function to clean text responses from AI
    private func cleanAIResponse(_ text: String) -> String {
        var cleaned = text
        
        // Remove leading/trailing whitespace and newlines
        cleaned = cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Remove leading special characters (anything that's not alphanumeric or space)
        while !cleaned.isEmpty && !cleaned.first!.isLetter && !cleaned.first!.isNumber && cleaned.first! != " " {
            cleaned.removeFirst()
        }
        
        // Remove trailing special characters (anything that's not alphanumeric or space)
        while !cleaned.isEmpty && !cleaned.last!.isLetter && !cleaned.last!.isNumber && cleaned.last! != " " {
            cleaned.removeLast()
        }
        
        // Remove leading spaces and newlines again after character removal
        cleaned = cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // For classification field, ensure it matches one of our exact categories
        if cleaned.lowercased().contains("product") && cleaned.lowercased().contains("engineering") {
            cleaned = "Product & Engineering"
        } else if cleaned.lowercased().contains("marketing") && cleaned.lowercased().contains("growth") {
            cleaned = "Marketing & Growth"
        } else if cleaned.lowercased().contains("strategy") && cleaned.lowercased().contains("vision") {
            cleaned = "Strategy & Vision"
        } else if cleaned.lowercased().contains("team") && cleaned.lowercased().contains("operations") {
            cleaned = "Team & Operations"
        } else if cleaned.lowercased().contains("people") && cleaned.lowercased().contains("relationships") {
            cleaned = "People & Relationships"
        } else if cleaned.lowercased().contains("personal") && cleaned.lowercased().contains("development") {
            cleaned = "Personal Development"
        }
        
        return cleaned
    }
    
    private func updateGeneratedField(field: String, content: String) {
        // Clean the content before updating
        let cleanedContent = cleanAIResponse(content)
        
        // Update the specific published property for this field
        switch field {
        case "title":
            if generatedTitle != cleanedContent {
                generatedTitle = cleanedContent
                objectWillChange.send()
            }
        case "summary":
            if generatedSummary != cleanedContent {
                generatedSummary = cleanedContent
                objectWillChange.send()
            }
        case "pros":
            if generatedPros != cleanedContent {
                generatedPros = cleanedContent
                objectWillChange.send()
            }
        case "cons":
            if generatedCons != cleanedContent {
                generatedCons = cleanedContent
                objectWillChange.send()
            }
        case "classification":
            if generatedClassification != cleanedContent {
                generatedClassification = cleanedContent
                objectWillChange.send()
            }
        default:
            print("⚠️ Unknown field: \(field)")
            break
        }
        
        // Additional debug info for streaming verification
        print("🎯 DUMP FIELD UPDATE \(field): \(content.count) chars - Preview: '\(content.prefix(50))...'")
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
                print("✅ Manually saved new Idea: \(self.generatedTitle)")
                let savedIdeas = [newIdea]
                self.savedIdeas = savedIdeas
                return savedIdeas
            } catch {
                print("❌ Failed to manually save Idea: \(error)")
                self.handleError("Failed to save Idea: \(error.localizedDescription)")
                return []
            }
        }
    }
    
    // MARK: - Error Handling
    
    private func handleError(_ message: String) {
        print("❌ QwenDumpProcessorVM Error: \(message)")
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