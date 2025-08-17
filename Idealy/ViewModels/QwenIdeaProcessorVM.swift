//
//  QwenIdeaProcessorVM.swift
//  Idealy
//
//  Created by Claude Code on 15/8/2025.
//

import Foundation
import SwiftUI
import Combine
internal import CoreData

class QwenIdeaProcessorVM: ObservableObject, IdeaProcessorProtocol {
    
    // MARK: - Published Properties
    @Published var isProcessing: Bool = false
    @Published var currentStatus: String = ""
    @Published var progress: Double = 0.0
    @Published var hasError: Bool = false
    @Published var errorMessage: String = ""
    
    // Streaming generation results - bindable for editing
    @Published var generatedProblem: String = ""
    @Published var generatedSolution: String = ""
    @Published var generatedUniqueValueProposition: String = ""
    @Published var generatedCustomerSegments: String = ""
    @Published var generatedChannels: String = ""
    @Published var generatedRevenueStreams: String = ""
    @Published var generatedCosts: String = ""
    @Published var generatedKeyMetrics: String = ""
    @Published var generatedUnfairAdvantage: String = ""
    @Published var generatedEarlyAdopters: String = ""
    @Published var generatedExistingAlternatives: String = ""
    @Published var generatedHighLevelConcept: String = ""
    @Published var generatedSummary: String = ""
    
    // MARK: - Private Properties
    private var title: String = ""
    private var content: String = ""
    private var modelName: String = ""
    private var mlxModelManager: MLXModelManager
    var viewContext: NSManagedObjectContext?
    
    // MARK: - Saved Box Reference
    @Published var savedBox: Box?
    
    // MARK: - Initialization
    init(mlxModelManager: MLXModelManager = MLXModelManager(), viewContext: NSManagedObjectContext? = nil) {
        self.mlxModelManager = mlxModelManager
        self.viewContext = viewContext
    }
    
    // MARK: - Public Methods
    
    /// Process title and content to create a new Box with structured business model fields
    /// - Parameters:
    ///   - title: The box name/title
    ///   - content: The raw idea content to process
    ///   - modelName: The AI model to use ("Apple Intelligence" or "Qwen2.5-1.5B")
    func processIdea(title: String, content: String, modelName: String) {
        print("🎯 QwenIdeaProcessorVM: Starting idea processing")
        print("   Title: \(title)")
        print("   Content: \(content)")
        print("   Model: \(modelName)")
        
        self.title = title
        self.content = content
        self.modelName = modelName
        
        // Reset state
        isProcessing = true
        hasError = false
        errorMessage = ""
        currentStatus = "Preparing to generate business model..."
        progress = 0.0
        
        // Route to appropriate model
        switch modelName {
        case "Apple Intelligence":
            processWithAppleIntelligence()
        case "Qwen2.5-1.5B":
            processWithQwen()
        default:
            handleError("Unknown model: \(modelName)")
        }
    }
    
    // MARK: - Private Processing Methods
    
    private func processWithAppleIntelligence() {
        print("🍎 Processing with Apple Intelligence...")
        currentStatus = "Connecting to Apple Intelligence..."
        
        // TODO: Implement Apple Intelligence processing with @guidance
        // This will generate all Box fields: problem, solution, uniqueValueProposition, etc.
        
        // Placeholder for now
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.currentStatus = "Apple Intelligence processing complete"
            self.progress = 1.0
            self.isProcessing = false
        }
    }
    
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
                    self.currentStatus = "Generating business model structure..."
                    self.progress = 0.1
                }
                
                await MainActor.run {
                    self.currentStatus = "Processing with Qwen2.5-1.5B..."
                    self.progress = 0.2
                }
                
                // Generate structured business model using field-by-field approach
                try await generateStructuredBusinessModel()
                
            } catch {
                await MainActor.run {
                    self.handleError("Qwen2.5-1.5B processing failed: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func generateStructuredBusinessModel() async throws {
        // Generate EACH field as a SEPARATE chat/inference with constrained token limits
        let fields = [
            ("summary", 80),               // Brief overview - SEPARATE CHAT
            ("problem", 60),               // Core problem - SEPARATE CHAT
            ("solution", 60),              // How it solves the problem - SEPARATE CHAT
            ("uniqueValueProposition", 50), // What makes it unique - SEPARATE CHAT
            ("customerSegments", 80),       // Who are the customers - SEPARATE CHAT
            ("earlyAdopters", 50),         // First customers - SEPARATE CHAT
            ("existingAlternatives", 60),  // Current competition - SEPARATE CHAT
            ("channels", 60),              // How to reach customers - SEPARATE CHAT
            ("revenueStreams", 60),        // How to make money - SEPARATE CHAT
            ("costs", 50),                 // Major expenses - SEPARATE CHAT
            ("keyMetrics", 60),            // What to measure - SEPARATE CHAT
            ("unfairAdvantage", 50),       // Competitive moats - SEPARATE CHAT
            ("highLevelConcept", 40)       // Elevator pitch - SEPARATE CHAT
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
            
            let (systemPrompt, userPrompt) = createStructuredPrompts(field: field, idea: "\(title): \(content)")
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
            self.currentStatus = "Business model generation complete!"
            self.progress = 1.0
            self.isProcessing = false
            
            // Special haptic feedback for completion of all segments
            let notificationFeedback = UINotificationFeedbackGenerator()
            notificationFeedback.notificationOccurred(.success)
        }
        
        // Note: Box is now only saved when user presses the checkmark button
    }
    
    
    
    
    private func createStructuredPrompts(field: String, idea: String) -> (systemPrompt: String, userPrompt: String) {
        // Structured system/user prompts with better stopping conditions
        
        let systemPrompt = """
        You are a business analysis expert. Generate concise, specific content for business model components. 
        Keep responses focused and relevant to the given idea. Do not include markdown formatting, headers, or structured text.
        Provide direct, plain text responses only. Keep responses to 1-3 sentences maximum.
        Stop immediately after providing the answer. Do not repeat or continue generating.
        """
        
        let userPrompt: String
        
        switch field {
        case "summary":
            userPrompt = "Business idea: \(idea)\n\nWrite a one-sentence summary of what this business does:"
            
        case "problem":
            userPrompt = "Business idea: \(idea)\n\nWhat main problem does this business solve?"
            
        case "solution":
            userPrompt = "Business idea: \(idea)\n\nHow does this business work to solve the problem?"
            
        case "uniqueValueProposition":
            userPrompt = "Business idea: \(idea)\n\nWhat makes this business unique compared to alternatives?"
            
        case "customerSegments":
            userPrompt = "Business idea: \(idea)\n\nWho are the target customers for this business?"
            
        case "earlyAdopters":
            userPrompt = "Business idea: \(idea)\n\nWho would be the first customers to try this?"
            
        case "existingAlternatives":
            userPrompt = "Business idea: \(idea)\n\nWhat current alternatives or competitors exist?"
            
        case "channels":
            userPrompt = "Business idea: \(idea)\n\nHow would this business reach its customers?"
            
        case "revenueStreams":
            userPrompt = "Business idea: \(idea)\n\nHow would this business make money?"
            
        case "costs":
            userPrompt = "Business idea: \(idea)\n\nWhat are the main costs to run this business?"
            
        case "keyMetrics":
            userPrompt = "Business idea: \(idea)\n\nWhat key metrics would measure success?"
            
        case "unfairAdvantage":
            userPrompt = "Business idea: \(idea)\n\nWhat competitive advantages does this business have?"
            
        case "highLevelConcept":
            userPrompt = "Business idea: \(idea)\n\nProvide a brief elevator pitch for this business:"
            
        default:
            userPrompt = "Business idea: \(idea)\n\nAnalyze the \(field) aspect of this business:"
        }
        
        return (systemPrompt: systemPrompt, userPrompt: userPrompt)
    }
    
    
    private func getFieldContent(field: String) -> String {
        switch field {
        case "problem": return generatedProblem
        case "solution": return generatedSolution
        case "uniqueValueProposition": return generatedUniqueValueProposition
        case "customerSegments": return generatedCustomerSegments
        case "channels": return generatedChannels
        case "revenueStreams": return generatedRevenueStreams
        case "costs": return generatedCosts
        case "keyMetrics": return generatedKeyMetrics
        case "unfairAdvantage": return generatedUnfairAdvantage
        case "earlyAdopters": return generatedEarlyAdopters
        case "existingAlternatives": return generatedExistingAlternatives
        case "highLevelConcept": return generatedHighLevelConcept
        case "summary": return generatedSummary
        default: return ""
        }
    }
    
    private func updateGeneratedField(field: String, content: String) {
        // CRITICAL: Force immediate UI update for token streaming
        
        // Update the specific published property for this field
        switch field {
        case "problem":
            if generatedProblem != content {
                generatedProblem = content
                objectWillChange.send()
            }
        case "solution":
            if generatedSolution != content {
                generatedSolution = content
                objectWillChange.send()
            }
        case "uniqueValueProposition":
            if generatedUniqueValueProposition != content {
                generatedUniqueValueProposition = content
                objectWillChange.send()
            }
        case "customerSegments":
            if generatedCustomerSegments != content {
                generatedCustomerSegments = content
                objectWillChange.send()
            }
        case "channels":
            if generatedChannels != content {
                generatedChannels = content
                objectWillChange.send()
            }
        case "revenueStreams":
            if generatedRevenueStreams != content {
                generatedRevenueStreams = content
                objectWillChange.send()
            }
        case "costs":
            if generatedCosts != content {
                generatedCosts = content
                objectWillChange.send()
            }
        case "keyMetrics":
            if generatedKeyMetrics != content {
                generatedKeyMetrics = content
                objectWillChange.send()
            }
        case "unfairAdvantage":
            if generatedUnfairAdvantage != content {
                generatedUnfairAdvantage = content
                objectWillChange.send()
            }
        case "earlyAdopters":
            if generatedEarlyAdopters != content {
                generatedEarlyAdopters = content
                objectWillChange.send()
            }
        case "existingAlternatives":
            if generatedExistingAlternatives != content {
                generatedExistingAlternatives = content
                objectWillChange.send()
            }
        case "highLevelConcept":
            if generatedHighLevelConcept != content {
                generatedHighLevelConcept = content
                objectWillChange.send()
            }
        case "summary":
            if generatedSummary != content {
                generatedSummary = content
                objectWillChange.send()
            }
        default:
            print("⚠️ Unknown field: \(field)")
            break
        }
        
        // Additional debug info for streaming verification
        print("🎯 FIELD UPDATE \(field): \(content.count) chars - Preview: '\(content.prefix(50))...'")
    }
    
    private func createAndSaveBox() async {
        guard let context = viewContext else {
            print("⚠️ No Core Data context available, cannot save Box")
            return
        }
        
        await MainActor.run {
            let newBox = Box(context: context)
            newBox.id = UUID()
            newBox.name = self.title
            newBox.createdDate = Date()
            newBox.modifiedDate = Date()
            
            // Set generated business model fields
            newBox.problem = self.generatedProblem
            newBox.solution = self.generatedSolution
            newBox.uniqueValueProposition = self.generatedUniqueValueProposition
            newBox.customerSegments = self.generatedCustomerSegments
            newBox.channels = self.generatedChannels
            newBox.revenueStreams = self.generatedRevenueStreams
            newBox.costs = self.generatedCosts
            newBox.keyMetrics = self.generatedKeyMetrics
            newBox.unfairAdvantage = self.generatedUnfairAdvantage
            newBox.earlyAdopters = self.generatedEarlyAdopters
            newBox.existingAlternatives = self.generatedExistingAlternatives
            newBox.highLevelConcept = self.generatedHighLevelConcept
            newBox.summary = self.generatedSummary
            
            do {
                try context.save()
                print("✅ Successfully saved new Box: \(self.title)")
                self.currentStatus = "Box saved successfully!"
                self.savedBox = newBox
            } catch {
                print("❌ Failed to save Box: \(error)")
                self.handleError("Failed to save Box: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - Manual Save Method
    func saveBoxManually() async -> Box? {
        guard let context = viewContext else {
            print("⚠️ No Core Data context available, cannot save Box")
            return nil
        }
        
        return await MainActor.run {
            let newBox = Box(context: context)
            newBox.id = UUID()
            newBox.name = self.title
            newBox.createdDate = Date()
            newBox.modifiedDate = Date()
            
            // Set current field values (may be edited by user)
            newBox.problem = self.generatedProblem
            newBox.solution = self.generatedSolution
            newBox.uniqueValueProposition = self.generatedUniqueValueProposition
            newBox.customerSegments = self.generatedCustomerSegments
            newBox.channels = self.generatedChannels
            newBox.revenueStreams = self.generatedRevenueStreams
            newBox.costs = self.generatedCosts
            newBox.keyMetrics = self.generatedKeyMetrics
            newBox.unfairAdvantage = self.generatedUnfairAdvantage
            newBox.earlyAdopters = self.generatedEarlyAdopters
            newBox.existingAlternatives = self.generatedExistingAlternatives
            newBox.highLevelConcept = self.generatedHighLevelConcept
            newBox.summary = self.generatedSummary
            
            do {
                try context.save()
                print("✅ Manually saved new Box: \(self.title)")
                self.savedBox = newBox
                return newBox
            } catch {
                print("❌ Failed to manually save Box: \(error)")
                self.handleError("Failed to save Box: \(error.localizedDescription)")
                return nil
            }
        }
    }
    
    // MARK: - Error Handling
    
    private func handleError(_ message: String) {
        print("❌ QwenIdeaProcessorVM Error: \(message)")
        hasError = true
        errorMessage = message
        isProcessing = false
        currentStatus = "Error occurred"
    }
    
    // MARK: - Utility Methods
    
    func resetState() {
        isProcessing = false
        currentStatus = ""
        progress = 0.0
        hasError = false
        errorMessage = ""
        title = ""
        content = ""
        modelName = ""
        
        // Reset all generated fields
        generatedProblem = ""
        generatedSolution = ""
        generatedUniqueValueProposition = ""
        generatedCustomerSegments = ""
        generatedChannels = ""
        generatedRevenueStreams = ""
        generatedCosts = ""
        generatedKeyMetrics = ""
        generatedUnfairAdvantage = ""
        generatedEarlyAdopters = ""
        generatedExistingAlternatives = ""
        generatedHighLevelConcept = ""
        generatedSummary = ""
    }
}
