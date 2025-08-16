//
//  DumpProcessorVM.swift
//  Idealy
//
//  Created by Claude Code on 15/8/2025.
//

import Foundation
import SwiftUI
import Combine
internal import CoreData

class DumpProcessorVM: ObservableObject {
    
    // MARK: - Published Properties
    @Published var isProcessing: Bool = false
    @Published var currentStatus: String = ""
    @Published var progress: Double = 0.0
    @Published var hasError: Bool = false
    @Published var errorMessage: String = ""
    
    // MARK: - Private Properties
    private var dumpText: String = ""
    private var targetBox: Box?
    private var modelName: String = ""
    private var mlxModelManager: MLXModelManager
    var viewContext: NSManagedObjectContext?
    
    // MARK: - Initialization
    init(mlxModelManager: MLXModelManager = MLXModelManager(), viewContext: NSManagedObjectContext? = nil) {
        self.mlxModelManager = mlxModelManager
        self.viewContext = viewContext
    }
    
    // MARK: - Public Methods
    
    /// Process dump text to create structured Idea entities within existing Box
    /// - Parameters:
    ///   - dumpText: The raw idea dump text to process
    ///   - box: The existing Box to add Ideas to
    ///   - modelName: The AI model to use ("Apple Intelligence" or "Qwen2.5-1.5B")
    func processDump(dumpText: String, box: Box, modelName: String) {
        print("🎯 DumpProcessorVM: Starting dump processing")
        print("   Dump Text: \(dumpText)")
        print("   Target Box: \(box.name ?? "unnamed")")
        print("   Model: \(modelName)")
        
        self.dumpText = dumpText
        self.targetBox = box
        self.modelName = modelName
        
        // Reset state
        isProcessing = true
        hasError = false
        errorMessage = ""
        currentStatus = "Preparing to analyze dump content..."
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
        print("🍎 Processing dump with Apple Intelligence...")
        currentStatus = "Connecting to Apple Intelligence..."
        
        // TODO: Implement Apple Intelligence processing with @guidance
        // This will generate Idea fields: title, summary, pros, cons, classification, relatedIdeas
        
        // Placeholder for now
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.currentStatus = "Apple Intelligence dump processing complete"
            self.progress = 1.0
            self.isProcessing = false
        }
    }
    
    private func processWithQwen() {
        print("🧠 Processing dump with Qwen2.5-1.5B...")
        currentStatus = "Loading Qwen model..."
        
        Task {
            do {
                // Check if model is ready
                guard mlxModelManager.isModelReady else {
                    await MainActor.run {
                        self.handleError("Qwen model is not ready. Please ensure the model is downloaded.")
                    }
                    return
                }
                
                await MainActor.run {
                    self.currentStatus = "Analyzing dump content with Qwen..."
                    self.progress = 0.5
                }
                
                // Simulate processing (replace with actual MLX inference later)
                try await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
                
                await MainActor.run {
                    self.currentStatus = "Qwen dump processing complete"
                    self.progress = 1.0
                    self.isProcessing = false
                }
                
            } catch {
                await MainActor.run {
                    self.handleError("Qwen processing failed: \(error.localizedDescription)")
                }
            }
        }
    }
    
    // MARK: - Error Handling
    
    private func handleError(_ message: String) {
        print("❌ DumpProcessorVM Error: \(message)")
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
        dumpText = ""
        targetBox = nil
        modelName = ""
    }
}
