//
//  DumpProcessorProtocol.swift
//  Idealy
//
//  Created by Claude Code on 17/8/2025.
//  Unified protocol for all dump processors to ensure consistent interface
//

import Foundation
import SwiftUI
import Combine
internal import CoreData

/// Protocol that all dump processors must conform to for unified interface
/// This allows ReviewDumpView to work with any AI model processor
protocol DumpProcessorProtocol: ObservableObject {
    
    // MARK: - Processing State
    var isProcessing: Bool { get }
    var currentStatus: String { get }
    var progress: Double { get }
    var hasError: Bool { get }
    var errorMessage: String { get }
    
    // MARK: - Generated Dump Analysis Fields
    var generatedTitle: String { get set }
    var generatedSummary: String { get set }
    var generatedPros: String { get set }
    var generatedCons: String { get set }
    var generatedClassification: String { get set }
    
    // MARK: - Core Data Integration
    var viewContext: NSManagedObjectContext? { get set }
    var savedIdeas: [Idea] { get }
    
    // MARK: - Required Methods
    
    /// Process dump text to create structured idea analysis
    /// - Parameters:
    ///   - dumpText: The raw dump content to process
    ///   - box: The target Box to add ideas to
    ///   - modelName: The AI model to use for processing
    func processDump(dumpText: String, box: Box, modelName: String)
    
    /// Manually save the current generated content as Ideas
    /// - Returns: The saved Ideas if successful, empty array otherwise
    func saveIdeasManually() async -> [Idea]
    
    /// Reset all state and generated content
    func resetState()
}

// MARK: - Protocol Extensions

extension DumpProcessorProtocol {
    
    /// Check if the processor has generated any content
    var hasGeneratedContent: Bool {
        return !generatedTitle.isEmpty ||
               !generatedSummary.isEmpty ||
               !generatedPros.isEmpty ||
               !generatedCons.isEmpty ||
               !generatedClassification.isEmpty
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