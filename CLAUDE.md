# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Idealy is an AI-powered idea management iOS app built with SwiftUI featuring dual-mode AI processing, real-time speech recognition, and intelligent content generation. The app supports both Apple Intelligence and local Mistral-7B inference via MLX-Swift, organizing ideas into "boxes" (project containers) with strict MVVM architecture and local Core Data persistence.

### Key Features
- **Dual AI Model Support**: Apple Intelligence and local Mistral-7B with automatic routing
- **Real-time Speech Recognition**: Hold-to-record voice input with live transcription
- **Intelligent Content Generation**: Structured business model creation from raw ideas
- **Adaptive UI**: Dynamic interface that adapts to device capabilities and model availability
- **Local-first**: On-device processing with Mistral for privacy and offline capability

## Data Model

### Entity: Box
Represents a high-level project or concept grouping multiple ideas.

**Attributes:**
- `channels`: String
- `costs`: String
- `createdDate`: Date
- `customerSegments`: String
- `earlyAdopters`: String
- `existingAlternatives`: String
- `highLevelConcept`: String
- `id`: UUID
- `keyMetrics`: String
- `modifiedDate`: Date
- `name`: String
- `problem`: String
- `revenueStreams`: String
- `solution`: String
- `summary`: String
- `unfairAdvantage`: String
- `uniqueValueProposition`: String

**Relationships:**
- `ideas` → Idea (One-to-Many)

### Entity: Idea
Represents a specific idea related to a box.

**Attributes:**
- `classification`: String
- `cons`: String
- `createdDate`: Date
- `id`: UUID
- `pros`: String
- `relatedIdeas`: [UUID]
- `summary`: String
- `title`: String

**Relationships:**
- `box` → Box (One-to-One)

## Architecture: MVVM

### Views
- `NewView` — **Main entry point with dual-mode AI input system**
  - Adaptive UI for Apple Intelligence availability states
  - Real-time speech recognition with hold-to-record functionality
  - Model selection (Apple Intelligence vs Mistral 7B)
  - Navigation to processing views based on input type
- `IdeaBoxView` — Displays details of a Box and its Ideas (Connected from NewView)
- `ReviewIdeaView` — **AI processing view for new Box creation** (Connected from Ideate button)
- `ReviewDumpView` — **AI processing view for Idea dumps** (Connected from Dump button)
- `EditBoxView` — Editing interface for a Box (Connected from IdeaBoxView)
- `EditIdeaView` — Editing interface for an Idea (Connected from IdeaBoxView)

### ViewModels

#### AI Processing ViewModels
- `IdeaProcessorVM` — **New Box Creation AI Processor**
  - Input: `title: String, content: String, modelName: String`
  - Output: Creates new Box with structured business model fields
  - Routes to Apple Intelligence (@guidance) or Mistral (MLX) based on modelName
  - Generates: problem, solution, uniqueValueProposition, customerSegments, etc.

- `DumpProcessorVM` — **Idea Dump AI Processor**
  - Input: `dumpText: String, box: Box, modelName: String`
  - Output: Creates structured Idea entities within existing Box
  - Routes to Apple Intelligence (@guidance) or Mistral (MLX) based on modelName
  - Generates: title, summary, pros, cons, classification, relatedIdeas

#### Infrastructure ViewModels
- `SpeechRecognizer` — **Real-time Speech-to-Text**
  - Uses iOS Speech framework for on-device transcription
  - Hold-to-record with live text streaming
  - Preserves existing text when adding new speech input
  - Automatic audio session management

- `MLXModelManager` — **Local Mistral Model Manager**
  - Downloads Mistral-7B-Instruct-v0.3-4bit from Hugging Face
  - MLX-Swift integration for Apple Silicon optimization
  - Persistent local storage with progress tracking
  - Debug tools for model management and info

- `ThemeManager` — **App Appearance Manager**
  - System/Light/Dark theme support
  - Color palette management with environment injection
  - Persistent user preferences

## NewView Detailed Capabilities

### Adaptive UI States
The NewView dynamically adapts based on Apple Intelligence availability:

1. **Apple Intelligence Available** (`AppleIntelligenceAvailableView`)
   - Shows both "Apple Intelligence" and "Mistral 7B" model options
   - Full feature access with model selection

2. **Device Not Eligible** (`DeviceNotEligibleView`) 
   - Shows only "Mistral 7B" option
   - Auto-downloads Mistral model if not present

3. **Apple Intelligence Not Enabled** 
   - Shows overlay prompting user to enable or use alternate models
   - Background content disabled until decision made

4. **Model Downloading** (`ModelNotReadyView`)
   - Shows progress indicator during Apple Intelligence or Mistral download
   - Dynamic titles based on which model is downloading

### Speech Recognition Integration
- **Hold-to-Record**: Press and hold microphone button to start recording
- **Real-time Transcription**: Text appears word-by-word as you speak
- **Text Preservation**: New speech appends to existing text without clearing
- **Visual Feedback**: Microphone icon turns red and scales during recording
- **On-device Processing**: Uses iOS Speech framework, no data sent to Apple

### Navigation Flow
```
NewView
├── Ideate Button → ReviewIdeaView (IdeaProcessorVM)
│   └── Creates new Box with structured business model
└── Dump Button → ReviewDumpView (DumpProcessorVM)
    └── Adds structured Ideas to selected Box
```

### Input Modes
1. **Box Creation Mode** (isNewBoxState = true)
   - Box name field + content field
   - Ideate button → ReviewIdeaView
   
2. **Idea Dump Mode** (isNewBoxState = false)
   - Single content field for selected box
   - Dump button → ReviewDumpView

## AI Model Integration Plan

### Apple Intelligence Implementation
- Use `@guidance` for structured generation
- Single call to generate all Box/Idea fields
- Built-in streaming and partial results
- Native iOS integration

### Mistral Implementation  
- Use MLX-Swift for local inference
- JSON schema prompting to replicate @guidance behavior
- Manual streaming implementation
- Fully local processing

### Model Routing Logic
```swift
switch modelName {
case "Apple Intelligence":
    // Use Foundation Models with @guidance
case "Mistral 7B":
    // Use MLX with local inference
default:
    // Error - unknown model
}
```

## Development Rules & Guidelines

### Core Principles
1. **Always work off a list** when handling Core Data entities in UI updates or processing
2. **Maintain MVVM** — no direct Core Data or model logic in Views
3. **Always keep a changelog** — every modification should be recorded
4. **Re-use existing functions** — no duplicate logic in different ViewModels
5. **Strict relationship handling** — maintain Core Data integrity between Box and Idea
6. **Performance first** — AI calls should be async with caching for summaries
7. **Core ML & Foundational Models** — AI summaries and insights must route through ViewModels for consistency

### Developer Workflow for Adding New Features

#### Step 1 — Define the Requirement
- Write a brief description of the feature (what it does, why it's needed)
- Decide if it impacts Box, Idea, or both

#### Step 2 — Update the Data Model
If new properties are needed:
- Update the Core Data model (.xcdatamodeld)
- Regenerate the NSManagedObject subclasses
- Migrate existing data if required
- Keep relationships intact — do not break Box ↔ Idea links

#### Step 3 — Update the Model Layer
- Add new Swift model properties or helper functions (if applicable)
- Do not add logic that belongs in ViewModels here

#### Step 4 — Update / Create a ViewModel
If the feature relates to AI:
- Add the method to the correct AI ViewModel (FMVM, MistralVM, FMAvailableVM, FMUnavailableVM)

If the feature relates to data handling:
- Add the method to a data-specific ViewModel
- Always re-use existing fetch/save/delete functions

#### Step 5 — Update the View
- Create or update a SwiftUI view that binds to the ViewModel's @Published properties
- Avoid performing Core Data or AI calls directly in the View — only call ViewModel methods

#### Step 6 — Maintain the Changelog
Every feature must have a changelog entry:
- Date
- Feature description
- Files updated
- Any migration or data change notes

#### Step 7 — Test
- Test on devices with and without Foundational Model support
- Verify Core Data persistence
- Verify AI summaries are correct and don't block UI
- Allow the human to run all the Buidling and testing, you will analyse and fix errors

## Development Commands

### Building and Running
```bash
# Build the project
xcodebuild -project Idealy.xcodeproj -scheme Idealy -destination 'platform=iOS Simulator,name=iPhone 15' build

# Run tests (if available)
xcodebuild test -project Idealy.xcodeproj -scheme Idealy -destination 'platform=iOS Simulator,name=iPhone 15'
```

### Project Configuration
- **Bundle ID**: `LoadingJohn.Idealy`
- **Development Team**: UNP26U3B6F
- **Swift Version**: 5.0
- **Deployment Target**: iOS 26.0
- **Supported Devices**: iPhone and iPad (Universal)

## Current Implementation Status & Challenges

### AI Processing Implementation (August 16, 2025)

#### What Has Been Implemented:
1. **Hierarchical Business Model Generation**
   - 3-phase contextual generation: Foundation → Market Analysis → Complete Business Model
   - Phase 1: Summary → Problem → Solution (with progressive context building)
   - Phase 2: Customer Segments → Early Adopters → Existing Alternatives (using Phase 1 context)
   - Phase 3: All remaining fields using full context from previous phases

2. **Streaming UI Architecture**
   - Real-time field updates as content generates
   - Progressive progress tracking through phases
   - Dynamic field display that shows content as it's generated
   - Proper context passing between NewView → ReviewIdeaView → IdeaProcessorVM

3. **MLX Model Integration Framework**
   - MLXModelManager with Mistral-7B-Instruct-v0.3-4bit download capability
   - Model availability detection and initialization
   - Token limits increased to 120-150 tokens per field for better content
   - Structured prompt system with clear task instructions

4. **Contextual Prompt Engineering**
   - Specialized prompts for each business model field
   - Clear separation of context vs. task instructions
   - Progressive context building (each field receives all previous analysis)
   - Structured format: `=== BUSINESS CONTEXT ===` + `=== PREVIOUS ANALYSIS ===` + `=== TASK ===`

#### Current Challenge: Real MLX Inference
**Problem**: The current implementation uses simulated MLX inference rather than actual model execution. The `generateText()` method in MLXModelManager loads the model config but doesn't perform real Mistral-7B inference.

**What's Missing**:
- Actual MLX-Swift model loading (`Module` instantiation)
- Real tokenizer implementation
- Proper Mistral model inference pipeline
- Token generation using the downloaded Mistral model weights

**Current Behavior**: Generates mock business content instead of using the actual local Mistral model for inference.

**Goal**: Use the downloaded Mistral-7B model to generate real, dynamic content based on user prompts without any pre-defined responses or keyword matching.

#### Files Implemented:
- `IdeaProcessorVM.swift` - Hierarchical generation with 3 phases
- `DumpProcessorVM.swift` - Similar structure for idea dumps
- `MLXModelManager.swift` - Model download and mock inference
- `ReviewIdeaView.swift` - Streaming UI with real-time field updates
- `ReviewDumpView.swift` - Processing view for dumps
- `NewView.swift` - Proper MLXModelManager dependency injection

#### Research Findings: MLX-Swift Implementation

**MLX-Swift Examples Repository**: `https://github.com/ml-explore/mlx-swift-examples`
- **LLMEval**: Official example for iOS/macOS with Hugging Face model downloads and text generation
- **MLXLMCommon**: Core library with `LanguageModel` protocol, `ModelContainer`, and `generate()` methods
- **Key APIs**: Uses `ModelContainer.perform()`, `MLXLMCommon.generate()`, and `NaiveStreamingDetokenizer`

**Real Implementation Pattern**:
```swift
// 1. Model Loading
let modelContainer = try await loadModel(id: "mlx-community/Mistral-7B-Instruct-v0.3-4bit")

// 2. Streaming Generation
let result = try await modelContainer.perform { context in
    let input = try context.processor.prepare(input: userInput)
    var detokenizer = NaiveStreamingDetokenizer(tokenizer: context.tokenizer)
    
    return try MLXLMCommon.generate(
        input: input,
        parameters: generateParameters,
        context: context
    ) { tokens in
        // Real streaming callback
        if let last = tokens.last {
            detokenizer.append(token: last)
        }
        if let newText = detokenizer.next() {
            // Stream to UI
            onTokenGenerated(newText)
        }
        return tokens.count >= maxTokens ? .stop : .more
    }
}
```

**Required Dependencies**:
- `MLXLMCommon` (model loading, generation)
- `MLXLLM` (language model implementations)
- `GenerateParameters` (temperature, topP, repetition penalty)
- `NaiveStreamingDetokenizer` (token-to-text conversion)

**Key Requirements**:
- Must run on physical iOS device (MLX doesn't work in Simulator)
- Requires GPU cache limits: `MLX.GPU.set(cacheLimit: 20 * 1024 * 1024)`
- Use Release build configuration for optimal performance
- 4-bit quantized models recommended for mobile (1-3B parameters)

#### Next Steps Implementation Plan:
1. **Add MLXLMCommon dependency** to project
2. **Replace mock `generateText()`** with real `MLXLMCommon.generate()`
3. **Implement `ModelContainer`** for Mistral model loading
4. **Add `NaiveStreamingDetokenizer`** for token streaming
5. **Configure `GenerateParameters`** for each business model field
6. **Test on physical iOS device** with real Mistral inference

## Development Notes

### Dependencies
- **MLX-Swift**: Local machine learning inference for Apple Silicon
  - Package: `https://github.com/ml-explore/mlx-swift`
  - Modules: MLX, MLXFFT, MLXFast, MLXLinalg, MLXNN
- **Apple Frameworks**: FoundationModels, Speech, AVFoundation, CoreData
- **SwiftUI + Combine**: Reactive UI with MVVM architecture

### Privacy Permissions Required
- **Microphone Usage**: For speech recognition functionality
- **Speech Recognition**: For voice-to-text transcription

### Testing Requirements
- Test on devices with Apple Intelligence support (iOS 18.1+, compatible hardware)
- Test on devices without Apple Intelligence (fallback to Mistral)
- Test speech recognition with various accents and environments
- Test Mistral model download and local inference performance
- Verify Core Data persistence across all workflows

### Build Configuration
- Uses automatic code signing with development team UNP26U3B6F
- SwiftUI previews enabled for UI development
- Deployment target: iOS 26.0 (ensure compatibility with speech frameworks)
- Universal app: iPhone and iPad support

### Performance Considerations
- Mistral model is ~4GB - ensure adequate device storage
- Speech recognition should be responsive with minimal latency
- UI should remain responsive during AI processing
- Background processing for model downloads with progress indicators
