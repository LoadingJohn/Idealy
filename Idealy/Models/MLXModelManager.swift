//
//  MLXModelManagerSimple.swift
//  Idealy
//
//  Created by Claude Code on 16/8/2025.
//  Clean service-based approach following ChatViewModel pattern
//

import Foundation
import MLX
import MLXLMCommon
import MLXLLM
import Combine

class MLXModelManager: ObservableObject {
    
    // MARK: - Singleton for Model Persistence
    static let shared = MLXModelManager()
    
    // MARK: - Published Properties
    @Published var isDownloading: Bool = false
    @Published var downloadProgress: Double = 0.0
    @Published var downloadStatus: String = ""
    @Published var isModelReady: Bool = false
    
    // MARK: - Private Properties
    private var mlxService = MLXService()
    
    // MARK: - Initialization
    init() {
        Task { @MainActor in
            self.downloadStatus = "Ready to load Qwen2.5-1.5B"
            self.isModelReady = true
            print("✅ MLXModelManager: Initialized for Qwen2.5-1.5B-Instruct-4bit model")
        }
    }
    
    // MARK: - Public Interface
    func downloadQwenModel() async {
        guard !isDownloading else {
            print("⚠️  Download already in progress, skipping")
            return
        }
        
        print("🎯 Starting Qwen2.5-1.5B model download via service layer")
        
        await MainActor.run {
            isDownloading = true
            downloadProgress = 0.0
            downloadStatus = "Downloading model..."
        }
        
        do {
            await MainActor.run {
                downloadStatus = "Loading Qwen2.5-1.5B model..."
                downloadProgress = 0.5
            }
            
            // Use service layer to handle model loading
            try await mlxService.downloadModel()
            
            await MainActor.run {
                self.downloadProgress = 1.0
                self.downloadStatus = "Model ready!"
                self.isModelReady = true
                print("🎉 Model loaded successfully via service layer!")
            }
            
        } catch {
            print("❌ MODEL LOADING FAILED: \(error)")
            
            await MainActor.run {
                downloadStatus = "Failed to load model: \(error.localizedDescription)"
                isModelReady = false
            }
        }
        
        await MainActor.run {
            isDownloading = false
        }
    }
    
    // MARK: - Text Generation (Service Layer)
    func generateText(systemPrompt: String, userPrompt: String, maxTokens: Int = 80, temperature: Float = 0.3, onTokenGenerated: @escaping (String) -> Void = { _ in }) async throws -> String {
        
        print("🚀 MLXModelManager: Using service layer (ChatViewModel pattern)")
        print("📝 System: \(systemPrompt.prefix(50))...")
        print("📝 User: \(userPrompt.prefix(50))...")
        
        var fullResponse = ""
        
        // Use the official MLX service - let's see what Generation cases are available
        for try await generation in try await mlxService.generate(
            systemPrompt: systemPrompt,
            userPrompt: userPrompt,
            maxTokens: maxTokens,
            temperature: temperature
        ) {
            // Let's check what cases Generation actually has
            print("📋 Generation type: \(generation)")
            
            // Try the common patterns from MLX examples
            switch generation {
            case let .chunk(text):
                // This is likely the text chunk case
                fullResponse += text
                onTokenGenerated(fullResponse)
                print("📤 Official chunk: '\(text)' (total: \(fullResponse.count) chars)")
                
            case let .info(completionInfo):
                // Performance info
                print("📊 Completion info: \(completionInfo)")
                
            case let .toolCall(toolCall):
                // Tool calls (not needed for our use case)
                print("🔧 Tool call: \(toolCall)")
                
            @unknown default:
                print("📊 Unknown generation type: \(generation)")
            }
        }
        
        print("✅ Service generation complete: '\(fullResponse.prefix(100))...'")
        return fullResponse
    }
    
    // MARK: - Model State Management
    func checkModelExists() -> Bool {
        return true // Service layer handles this
    }
    
    func loadExistingModel() async {
        await MainActor.run {
            downloadStatus = "Model ready"
            isModelReady = true
        }
        print("Using service layer - model will load on demand")
    }
    
    func clearModel() {
        mlxService.clearModel()
        isModelReady = false
        downloadStatus = ""
        print("Model cleared via service layer")
    }
    
    // MARK: - Utility Methods
    func getModelInfo() -> [String: Any] {
        return [
            "modelId": "mlx-community/Qwen2.5-1.5B-Instruct-4bit",
            "isReady": isModelReady,
            "isDownloading": isDownloading,
            "progress": downloadProgress,
            "status": downloadStatus,
            "apiType": "Service Layer API",
            "serviceLayer": "MLXService"
        ]
    }
}
