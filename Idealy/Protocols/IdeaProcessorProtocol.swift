//
//  IdeaProcessorProtocol.swift
//  Idealy
//
//  Created by Claude Code on 16/8/2025.
//  Unified protocol for all AI model processors to ensure consistent interface
//

import Foundation
import SwiftUI
import Combine
internal import CoreData

/// Protocol that all idea processors must conform to for unified interface
/// This allows ReviewIdeaView to work with any AI model processor
protocol IdeaProcessorProtocol: ObservableObject {
    
    // MARK: - Processing State
    var isProcessing: Bool { get }
    var currentStatus: String { get }
    var progress: Double { get }
    var hasError: Bool { get }
    var errorMessage: String { get }
    
    // MARK: - Generated Business Model Fields
    var generatedProblem: String { get set }
    var generatedSolution: String { get set }
    var generatedUniqueValueProposition: String { get set }
    var generatedCustomerSegments: String { get set }
    var generatedChannels: String { get set }
    var generatedRevenueStreams: String { get set }
    var generatedCosts: String { get set }
    var generatedKeyMetrics: String { get set }
    var generatedUnfairAdvantage: String { get set }
    var generatedEarlyAdopters: String { get set }
    var generatedExistingAlternatives: String { get set }
    var generatedHighLevelConcept: String { get set }
    var generatedSummary: String { get set }
    
    // MARK: - Core Data Integration
    var viewContext: NSManagedObjectContext? { get set }
    var savedBox: Box? { get }
    
    // MARK: - Required Methods
    
    /// Process title and content to create structured business model fields
    /// - Parameters:
    ///   - title: The box name/title
    ///   - content: The raw idea content to process
    ///   - modelName: The AI model to use for processing
    func processIdea(title: String, content: String, modelName: String)
    
    /// Manually save the current generated content as a Box
    /// - Returns: The saved Box if successful, nil otherwise
    func saveBoxManually() async -> Box?
    
    /// Reset all state and generated content
    func resetState()
}

// MARK: - Protocol Extensions

extension IdeaProcessorProtocol {
    
    /// Check if the processor has generated any content
    var hasGeneratedContent: Bool {
        return !generatedSummary.isEmpty ||
               !generatedProblem.isEmpty ||
               !generatedSolution.isEmpty ||
               !generatedUniqueValueProposition.isEmpty ||
               !generatedCustomerSegments.isEmpty ||
               !generatedChannels.isEmpty ||
               !generatedRevenueStreams.isEmpty ||
               !generatedCosts.isEmpty ||
               !generatedKeyMetrics.isEmpty ||
               !generatedUnfairAdvantage.isEmpty ||
               !generatedEarlyAdopters.isEmpty ||
               !generatedExistingAlternatives.isEmpty ||
               !generatedHighLevelConcept.isEmpty
    }
    
    /// Check if processing is complete and content is ready to save
    var isReadyToSave: Bool {
        return !isProcessing && !hasError && hasGeneratedContent
    }
    
    /// Get a description of the processor type for debugging
    var processorType: String {
        return String(describing: type(of: self))
    }
}