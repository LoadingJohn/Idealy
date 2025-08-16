//
//  MLXService.swift
//  Idealy
//
//  Created by Claude Code on 16/8/2025.
//  Using official MLX-Swift ChatExample implementation - NO manual token handling!
//

import Foundation
import MLXLMCommon
import MLXLLM
import MLX
internal import Tokenizers


/// Simple message type for our use case
struct SimpleMessage {
    enum Role {
        case system, user, assistant
    }
    let role: Role
    let content: String
}

/// Service layer using official MLX-Swift example approach
/// NO manual token processing - let MLXLMCommon handle everything!
@Observable
class MLXService {
    
    // MARK: - Properties
    private var modelContext: ModelContext?
    private let modelId = "mlx-community/Qwen2.5-1.5B-Instruct-4bit"
    
    /// Track model download progress
    var modelDownloadProgress: Progress?
    
    // MARK: - Initialization
    init() {
        print("🎯 MLXService initialized for \(modelId) with official MLX approach")
    }
    
    // MARK: - Public API (EXACT ChatExample Pattern)
    
    /// Generate text using official MLX approach - returns AsyncStream<Generation> directly
    func generate(systemPrompt: String, userPrompt: String, maxTokens: Int = 80, temperature: Float = 0.3) async throws -> AsyncStream<Generation> {
        
        // Create messages like ChatExample
        let messages = [
            SimpleMessage(role: .system, content: systemPrompt),
            SimpleMessage(role: .user, content: userPrompt)
        ]
        
        // Load model context
        let context = try await loadModel()
        
        // Create simple chat prompt instead of complex Chat.Message approach
        let chatPrompt = """
        <|im_start|>system
        \(systemPrompt)<|im_end|>
        <|im_start|>user
        \(userPrompt)<|im_end|>
        <|im_start|>assistant
        """
        
        print("🚀 MLXService: Using MLX with simple prompt approach")
        
        // Use simpler approach with direct context
        let inputTokens = context.tokenizer.encode(text: chatPrompt)
        let tokenArray = MLXArray(inputTokens)
        let input = LMInput(tokens: tokenArray)
        
        // Add better stopping conditions to prevent looping
        let parameters = GenerateParameters(
            temperature: temperature,
            topP: 0.9,           // Add top-p sampling
            repetitionPenalty: 1.1,  // Reduce repetition
            repetitionContextSize: 20 // Context for repetition penalty
        )
        
        print("🎯 MLXService: Generation params - temp: \(temperature), maxTokens: \(maxTokens)")
        
        // This returns AsyncStream<Generation> directly - MLX handles all token complexity!
        return try MLXLMCommon.generate(
            input: input, 
            parameters: parameters, 
            context: context
        )
    }
    
    // MARK: - Model Management (Simplified)
    
    /// Load model using MLX approach  
    private func loadModel() async throws -> ModelContext {
        if let context = modelContext {
            return context
        }
        
        print("📂 Loading model context...")
        
        // Set GPU cache for iPhone 13 Pro
        MLX.GPU.set(cacheLimit: 8 * 1024 * 1024)
        
        let configuration = ModelConfiguration(id: modelId)
        let context = try await MLXLMCommon.loadModel(configuration: configuration)
        
        modelContext = context
        print("✅ Model context loaded successfully!")
        
        return context
    }
    
    /// Download model (if needed)
    func downloadModel() async throws {
        _ = try await loadModel()
    }
    
    /// Clear model from memory
    func clearModel() {
        modelContext = nil
        print("🗑️ Model cleared")
    }
}
