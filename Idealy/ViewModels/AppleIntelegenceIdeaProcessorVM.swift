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

@Generable
struct BusinessModelAnalysis {
    @Guide(description: "Write a comprehensive 3-4 sentence business summary that explains what the company does, its core value proposition, and its target market. Focus on clarity and impact.")
    var summary: String
    
    @Guide(description: "Identify the specific problem or pain point this business addresses. Explain why this problem matters and who experiences it most acutely.")
    var problem: String
    
    @Guide(description: "Describe how this business solves the identified problem. Explain the core approach, methodology, or product that addresses the pain point.")
    var solution: String
    
    @Guide(description: "Articulate what makes this solution unique and different from alternatives. What special advantage or approach sets it apart?")
    var uniqueValueProposition: String
    
    @Guide(description: "Define the specific groups of customers this business targets. Be detailed about demographics, psychographics, and behavioral characteristics.")
    var customerSegments: String
    
    @Guide(description: "Identify the first wave of customers who would be most eager to adopt this solution. What makes them early adopters?")
    var earlyAdopters: String
    
    @Guide(description: "List current alternatives and competitors that customers use to solve this problem today. Include direct and indirect competition.")
    var existingAlternatives: String
    
    @Guide(description: "Outline how the business will reach and acquire customers. Include both digital and traditional channels for marketing and sales.")
    var channels: String
    
    @Guide(description: "Explain how the business will generate revenue. Include pricing models, revenue streams, and monetization strategies.")
    var revenueStreams: String
    
    @Guide(description: "Identify the major costs and expenses required to operate this business. Include both fixed and variable costs.")
    var costs: String
    
    @Guide(description: "Define the key metrics that will measure success and business health. Include both financial and operational KPIs.")
    var keyMetrics: String
    
    @Guide(description: "Identify sustainable competitive advantages that will be hard for competitors to replicate or overcome.")
    var unfairAdvantage: String
    
    @Guide(description: "Create a compelling elevator pitch that captures the essence of the business in 1-2 sentences. Make it memorable and impactful.")
    var highLevelConcept: String
}

@MainActor
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
        await MainActor.run {
            self.currentStatus = "Generating complete business model..."
            self.progress = 0.1
        }
        
        // Create the business model generation prompt
        let businessIdeaPrompt = """
        Business Idea Title: \(title)
        
        Business Idea Description: \(content)
        
        Analyze this business idea and provide a comprehensive business model analysis.
        """
        
        print("🍎 Starting streaming guided generation for business model")
        
        // Create language model session
        let session = LanguageModelSession(model: model)
        
        // Configure generation options with proper max tokens
        let generationOptions = GenerationOptions(
            temperature: 0.3,
            maximumResponseTokens: 4000
        )
        
        // Use streaming guided generation with @Generable structure
        let response = try await session.streamResponse(
            to: businessIdeaPrompt,
            generating: BusinessModelAnalysis.self,
            options: generationOptions
        )
        
        // Stream the results field by field
        for try await partialResult in response {
            await MainActor.run {
                // Update individual fields as they become available
                if let summary = partialResult.summary, !summary.isEmpty {
                    self.updateGeneratedField(field: "summary", content: summary)
                }
                if let problem = partialResult.problem, !problem.isEmpty {
                    self.updateGeneratedField(field: "problem", content: problem)
                }
                if let solution = partialResult.solution, !solution.isEmpty {
                    self.updateGeneratedField(field: "solution", content: solution)
                }
                if let uniqueValueProposition = partialResult.uniqueValueProposition, !uniqueValueProposition.isEmpty {
                    self.updateGeneratedField(field: "uniqueValueProposition", content: uniqueValueProposition)
                }
                if let customerSegments = partialResult.customerSegments, !customerSegments.isEmpty {
                    self.updateGeneratedField(field: "customerSegments", content: customerSegments)
                }
                if let earlyAdopters = partialResult.earlyAdopters, !earlyAdopters.isEmpty {
                    self.updateGeneratedField(field: "earlyAdopters", content: earlyAdopters)
                }
                if let existingAlternatives = partialResult.existingAlternatives, !existingAlternatives.isEmpty {
                    self.updateGeneratedField(field: "existingAlternatives", content: existingAlternatives)
                }
                if let channels = partialResult.channels, !channels.isEmpty {
                    self.updateGeneratedField(field: "channels", content: channels)
                }
                if let revenueStreams = partialResult.revenueStreams, !revenueStreams.isEmpty {
                    self.updateGeneratedField(field: "revenueStreams", content: revenueStreams)
                }
                if let costs = partialResult.costs, !costs.isEmpty {
                    self.updateGeneratedField(field: "costs", content: costs)
                }
                if let keyMetrics = partialResult.keyMetrics, !keyMetrics.isEmpty {
                    self.updateGeneratedField(field: "keyMetrics", content: keyMetrics)
                }
                if let unfairAdvantage = partialResult.unfairAdvantage, !unfairAdvantage.isEmpty {
                    self.updateGeneratedField(field: "unfairAdvantage", content: unfairAdvantage)
                }
                if let highLevelConcept = partialResult.highLevelConcept, !highLevelConcept.isEmpty {
                    self.updateGeneratedField(field: "highLevelConcept", content: highLevelConcept)
                }
                
                // Update progress based on filled fields
                let totalFields = 13.0
                var filledFields = 0.0
                if let summary = partialResult.summary, !summary.isEmpty { filledFields += 1 }
                if let problem = partialResult.problem, !problem.isEmpty { filledFields += 1 }
                if let solution = partialResult.solution, !solution.isEmpty { filledFields += 1 }
                if let uniqueValueProposition = partialResult.uniqueValueProposition, !uniqueValueProposition.isEmpty { filledFields += 1 }
                if let customerSegments = partialResult.customerSegments, !customerSegments.isEmpty { filledFields += 1 }
                if let earlyAdopters = partialResult.earlyAdopters, !earlyAdopters.isEmpty { filledFields += 1 }
                if let existingAlternatives = partialResult.existingAlternatives, !existingAlternatives.isEmpty { filledFields += 1 }
                if let channels = partialResult.channels, !channels.isEmpty { filledFields += 1 }
                if let revenueStreams = partialResult.revenueStreams, !revenueStreams.isEmpty { filledFields += 1 }
                if let costs = partialResult.costs, !costs.isEmpty { filledFields += 1 }
                if let keyMetrics = partialResult.keyMetrics, !keyMetrics.isEmpty { filledFields += 1 }
                if let unfairAdvantage = partialResult.unfairAdvantage, !unfairAdvantage.isEmpty { filledFields += 1 }
                if let highLevelConcept = partialResult.highLevelConcept, !highLevelConcept.isEmpty { filledFields += 1 }
                
                self.progress = min(0.9, 0.1 + (filledFields / totalFields) * 0.8)
                self.currentStatus = "Generating field \(Int(filledFields + 1)) of \(Int(totalFields))..."
            }
            
            // Haptic feedback for each field completion
            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
            impactFeedback.impactOccurred()
        }
        
        await MainActor.run {
            self.currentStatus = "Apple Intelligence processing complete!"
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