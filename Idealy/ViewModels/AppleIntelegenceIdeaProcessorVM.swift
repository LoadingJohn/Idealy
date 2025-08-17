//
//  AppleIntelligenceIdeaProcessorVM.swift
//  Idealy
//
//  Created by Claude Code on 16/8/2025.
//  Apple Intelligence (Foundation Models) implementation for business model generation
//

import Foundation
import SwiftUI
import Combine
import FoundationModels
internal import CoreData

class AppleIntelligenceIdeaProcessorVM: ObservableObject, IdeaProcessorProtocol {
    
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
    private let model = SystemLanguageModel.default
    var viewContext: NSManagedObjectContext?
    
    // MARK: - Saved Box Reference
    @Published var savedBox: Box?
    
    // MARK: - Initialization
    init(viewContext: NSManagedObjectContext? = nil) {
        self.viewContext = viewContext
    }
    
    // MARK: - Public Methods
    
    /// Process title and content to create a new Box with structured business model fields using Apple Intelligence
    /// - Parameters:
    ///   - title: The box name/title
    ///   - content: The raw idea content to process
    ///   - modelName: The AI model to use (should be "Apple Intelligence")
    func processIdea(title: String, content: String, modelName: String) {
        print("🍎 AppleIntelligenceIdeaProcessorVM: Starting Apple Intelligence processing")
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
        currentStatus = "Connecting to Apple Intelligence..."
        progress = 0.0
        
        // Clear all generated fields
        resetGeneratedFields()
        
        // Start Apple Intelligence processing
        processWithAppleIntelligence()
    }
    
    // MARK: - Private Processing Methods
    
    private func processWithAppleIntelligence() {
        print("🍎 Processing with Apple Intelligence...")
        currentStatus = "Generating business model structure..."
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
                
                // Generate structured business model using @guidance approach
                try await generateStructuredBusinessModelWithGuidance()
                
            } catch {
                await MainActor.run {
                    self.handleError("Apple Intelligence processing failed: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func generateStructuredBusinessModelWithGuidance() async throws {
        // Field-by-field generation using Apple Intelligence @guidance
        let fields = [
            ("summary", "Brief business overview"),
            ("problem", "Core problem being solved"),
            ("solution", "How the business solves the problem"),
            ("uniqueValueProposition", "What makes this unique"),
            ("customerSegments", "Target customer groups"),
            ("earlyAdopters", "First customers to adopt"),
            ("existingAlternatives", "Current competition"),
            ("channels", "How to reach customers"),
            ("revenueStreams", "How to make money"),
            ("costs", "Major business expenses"),
            ("keyMetrics", "Success measurements"),
            ("unfairAdvantage", "Competitive advantages"),
            ("highLevelConcept", "Elevator pitch")
        ]
        
        let totalFields = Double(fields.count)
        
        // Process each field with Apple Intelligence
        for (index, (field, description)) in fields.enumerated() {
            await MainActor.run {
                self.currentStatus = "Generating \(field.replacingOccurrences(of: "([a-z])([A-Z])", with: "$1 $2", options: .regularExpression))..."
                self.progress = Double(index) / totalFields
                
                // Clear the field before starting generation
                self.updateGeneratedField(field: field, content: "")
            }
            
            // Create prompt for this specific field
            let prompt = createPromptForField(field: field, description: description, idea: "\(title): \(content)")
            print("🍎 Generating field: \(field) with Apple Intelligence")
            
            // Generate content using Apple Intelligence
            let result = try await generateWithAppleIntelligence(prompt: prompt, field: field)
            
            // Update UI with final result
            await MainActor.run {
                self.updateGeneratedField(field: field, content: result)
                print("✅ AI Field '\(field)' COMPLETE: \(result.count) characters")
                
                // Haptic feedback for completed field
                let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                impactFeedback.impactOccurred()
            }
            
            // Small delay between fields
            try await Task.sleep(nanoseconds: 300_000_000) // 0.3 seconds
        }
        
        await MainActor.run {
            self.currentStatus = "Apple Intelligence processing complete!"
            self.progress = 1.0
            self.isProcessing = false
            
            // Special haptic feedback for completion
            let notificationFeedback = UINotificationFeedbackGenerator()
            notificationFeedback.notificationOccurred(.success)
        }
        
        // Note: Box is only saved when user presses the checkmark button
    }
    
    private func generateWithAppleIntelligence(prompt: String, field: String) async throws -> String {
        // TODO: Implement actual Apple Intelligence @guidance generation
        // For now, return a placeholder that indicates Apple Intelligence would be used
        
        // Simulate streaming by updating field incrementally
        let mockResponse = "Apple Intelligence generated content for \(field): This would be real AI-generated business analysis using Foundation Models."
        
        // Simulate streaming updates
        let words = mockResponse.components(separatedBy: " ")
        var currentText = ""
        
        for (index, word) in words.enumerated() {
            currentText += (index == 0 ? "" : " ") + word
            
            await MainActor.run {
                self.updateGeneratedField(field: field, content: currentText)
            }
            
            // Small delay to simulate streaming
            try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        }
        
        return currentText
    }
    
    private func createPromptForField(field: String, description: String, idea: String) -> String {
        let basePrompt = """
        Business Idea: \(idea)
        
        Generate a concise, specific response for: \(description)
        
        Keep the response to 1-3 sentences, focused and relevant to the business idea.
        Provide direct, actionable insights without headers or formatting.
        """
        
        // Field-specific prompts can be added here for more tailored generation
        switch field {
        case "summary":
            return basePrompt + "\n\nWrite a one-sentence summary of what this business does:"
        case "problem":
            return basePrompt + "\n\nWhat main problem does this business solve?"
        case "solution":
            return basePrompt + "\n\nHow does this business solve the problem?"
        default:
            return basePrompt + "\n\nAnalyze the \(field) aspect:"
        }
    }
    
    private func updateGeneratedField(field: String, content: String) {
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
        
        print("🍎 AI FIELD UPDATE \(field): \(content.count) chars")
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
                print("✅ Apple Intelligence: Successfully saved Box: \(self.title)")
                self.savedBox = newBox
                return newBox
            } catch {
                print("❌ Apple Intelligence: Failed to save Box: \(error)")
                self.handleError("Failed to save Box: \(error.localizedDescription)")
                return nil
            }
        }
    }
    
    // MARK: - Error Handling
    
    private func handleError(_ message: String) {
        print("❌ AppleIntelligenceIdeaProcessorVM Error: \(message)")
        hasError = true
        errorMessage = message
        isProcessing = false
        currentStatus = "Error occurred"
    }
    
    // MARK: - Utility Methods
    
    private func resetGeneratedFields() {
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
    
    func resetState() {
        isProcessing = false
        currentStatus = ""
        progress = 0.0
        hasError = false
        errorMessage = ""
        title = ""
        content = ""
        modelName = ""
        
        resetGeneratedFields()
    }
}