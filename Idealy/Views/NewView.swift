//
//  NewView.swift
//  Idealy
//
//  Created by Claude Code on 10/8/2025.
//
//  PRODUCTION RELEASE INSTRUCTIONS:
//  Search for "TEMPORARY DEBUG" and comment out or remove all sections marked with this flag
//  This includes: debug state variables, debug dropdown UI, debug availability override, and debug overlay conditions
//

import SwiftUI
import FoundationModels
import Speech

struct NewView: View {
    private var model = SystemLanguageModel.default
    @Environment(\.colorPalette) private var colors
    @EnvironmentObject private var themeManager: ThemeManager
    @Environment(\.managedObjectContext) private var viewContext
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Box.name, ascending: true)],
        animation: .default)
    private var boxes: FetchedResults<Box>
    
    @State private var selectedBox = "New Box"
    @State private var selectedBoxEntity: Box?
    @State private var isNewBoxState = true
    @State private var clearFieldsTrigger = false
    
    // MARK: - Swipe Navigation
    @State private var showingIdeaBoxView = false
    @State private var dragOffset: CGFloat = 0
    
    // MARK: - TEMPORARY DEBUG - COMMENT OUT FOR PRODUCTION
    @State private var debugMode = false
    @State private var forceState: SystemLanguageModel.Availability = .available
    @AppStorage("useAlternateModels") private var useAlternateModels = false
    @AppStorage("qwenModelDownloaded") private var qwenModelDownloaded = false
    @State private var isDownloadingQwen = false
    @ObservedObject private var mlxModelManager = MLXModelManager.shared
    @StateObject private var speechRecognizer = SpeechRecognizer()
    
    // MARK: - Box Save Handling
    private func handleBoxSaved(_ savedBox: Box) {
        // Update box selection to the newly saved box
        selectedBox = savedBox.name ?? "Unnamed Box"
        selectedBoxEntity = savedBox
        isNewBoxState = false
        
        // Trigger field clearing
        clearFieldsTrigger.toggle()
        
        print("📦 NewView: Box selection updated to '\(selectedBox)'")
    }
    
    let debugStates: [(String, SystemLanguageModel.Availability)] = [
        ("Available", .available),
        ("Not Enabled", .unavailable(.appleIntelligenceNotEnabled)),
        ("Loading", .unavailable(.modelNotReady)),
        ("Device Not Compatible", .unavailable(.deviceNotEligible)),
        ("Error", .unavailable(.deviceNotEligible)) // Using deviceNotEligible as placeholder for unknown error
    ]
    // END TEMPORARY DEBUG
    
    var body: some View {
        NavigationView {
            GeometryReader { geometry in
                ZStack {
                    // IdeaBoxView - shown when swiped up
                    if showingIdeaBoxView, let box = selectedBoxEntity {
                        IdeaBoxView(box: box, onBack: {
                            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                                showingIdeaBoxView = false
                                dragOffset = 0
                            }
                        }, onBoxDeleted: {
                            // Reset to "New Box" selection when box is deleted
                            selectedBox = "New Box"
                            selectedBoxEntity = nil
                            isNewBoxState = true
                            clearFieldsTrigger.toggle()
                            print("📦 NewView: Reset to 'New Box' after deletion")
                        })
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .offset(y: 0)
                        .ignoresSafeArea()
                        .transition(.move(edge: .bottom))
                        .zIndex(1)
                    }
                    
                    // Main NewView content
                    mainContentView(geometry: geometry)
                        .offset(y: showingIdeaBoxView ? -geometry.size.height : dragOffset)
                        .opacity(showingIdeaBoxView ? 0 : 1)
                        .gesture(swipeGesture(geometry: geometry))
                        .zIndex(0)
                }
            }
            .navigationBarHidden(true)
        }
    }
    
    // MARK: - Main Content View
    private func mainContentView(geometry: GeometryProxy) -> some View {
        ZStack {
                    // Background
                    colors.background
                        .ignoresSafeArea()
                    
                    VStack(spacing: 0) {
                        // Top bar with title and theme selector
                        HStack {
                            Text("Idealy")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(colors.text)
                            
                            Spacer()
                            
                            HStack {
                                // Box selector dropdown
                                Menu {
                                    Button("New Box") {
                                        selectedBox = "New Box"
                                        selectedBoxEntity = nil
                                        isNewBoxState = true
                                    }
                                    ForEach(boxes, id: \.self) { box in
                                        Button(box.name ?? "Unnamed Box") {
                                            selectedBox = box.name ?? "Unnamed Box"
                                            selectedBoxEntity = box
                                            isNewBoxState = false
                                        }
                                    }
                                } label: {
                                    HStack {
                                        Text(selectedBox)
                                            .foregroundColor(colors.textSecondary)
                                        Image(systemName: "chevron.down")
                                            .foregroundColor(colors.textSecondary)
                                            .font(.system(size: 12))
                                    }
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(colors.surface)
                                    .cornerRadius(12)
                                }
                                
                                // MARK: - TEMPORARY DEBUG DROPDOWN - COMMENT OUT FOR PRODUCTION
                                Menu {
                                    Button("Use Real State") {
                                        debugMode = false
                                    }
                                    Button("Reset useAlternateModels") {
                                        useAlternateModels = false
                                    }
                                    Button("Delete Downloaded Model") {
                                        mlxModelManager.clearModel()
                                        qwenModelDownloaded = false
                                    }
                                    Button("Show Model Info") {
                                        let info = mlxModelManager.getModelInfo()
                                        print("🔍 DEBUG MODEL INFO:")
                                        for (key, value) in info {
                                            print("   \(key): \(value)")
                                        }
                                    }
                                    ForEach(Array(debugStates.enumerated()), id: \.offset) { index, state in
                                        Button(state.0) {
                                            debugMode = true
                                            forceState = state.1
                                        }
                                    }
                                } label: {
                                    HStack {
                                        Text("🐛")
                                            .font(.system(size: 16))
                                        if debugMode {
                                            Text("DEBUG")
                                                .font(.system(size: 10, weight: .bold))
                                                .foregroundColor(.orange)
                                        }
                                    }
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 6)
                                    .background(debugMode ? Color.orange.opacity(0.2) : colors.surface)
                                    .cornerRadius(8)
                                }
                                // END TEMPORARY DEBUG
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 16)
                        .padding(.bottom, 12)
                        
                        // Apple Intelligence availability check with embedded content
                        ZStack {
                            // MARK: - TEMPORARY DEBUG - COMMENT OUT FOR PRODUCTION
                            let currentAvailability = debugMode ? forceState : model.availability
                            let effectiveAvailability = useAlternateModels ? SystemLanguageModel.Availability.unavailable(.deviceNotEligible) : currentAvailability
                            
                            // DEBUG: Print availability states
                            let _ = print("DEBUG - currentAvailability: \(currentAvailability)")
                            let _ = print("DEBUG - useAlternateModels: \(useAlternateModels)")
                            let _ = print("DEBUG - effectiveAvailability: \(effectiveAvailability)")
                            let _ = print("DEBUG - debugMode: \(debugMode)")
                            let _ = print("DEBUG - qwenModelDownloaded: \(qwenModelDownloaded)")
                            let _ = print("DEBUG - isDownloadingQwen: \(isDownloadingQwen)")
                            let _ = print("DEBUG - Priority check result: \(isDownloadingQwen || effectiveAvailability == .unavailable(.modelNotReady) || (effectiveAvailability == .unavailable(.deviceNotEligible) && !qwenModelDownloaded))")
                            // END TEMPORARY DEBUG
                            
                            // PRIORITY CHECK: Always show ModelNotReadyView if any of these conditions are met
                            // 1. Currently downloading Qwen (isDownloadingQwen = true)
                            // 2. Apple Intelligence is downloading (.unavailable(.modelNotReady))
                            // 3. Device not eligible AND Qwen not downloaded (auto-triggers download)
                            if isDownloadingQwen || effectiveAvailability == .unavailable(.modelNotReady) || 
                               (effectiveAvailability == .unavailable(.deviceNotEligible) && !qwenModelDownloaded) {
                                ModelNotReadyView(
                                    isNewBoxState: isNewBoxState, 
                                    selectedBoxEntity: selectedBoxEntity,
                                    isDownloadingQwen: isDownloadingQwen,
                                    isDownloadingAppleIntelligence: effectiveAvailability == .unavailable(.modelNotReady),
                                    onBoxSaved: handleBoxSaved,
                                    clearFieldsTrigger: clearFieldsTrigger,
                                    mlxModelManager: mlxModelManager
                                )
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .onAppear {
                                    // Auto-start Qwen download if device not eligible and Qwen not downloaded
                                    if effectiveAvailability == .unavailable(.deviceNotEligible) && !qwenModelDownloaded && !isDownloadingQwen {
                                        isDownloadingQwen = true
                                        Task {
                                            await mlxModelManager.downloadQwenModel()
                                            isDownloadingQwen = false
                                            qwenModelDownloaded = true  // Mark as downloaded
                                        }
                                    }
                                }
                            } else {
                                // MAIN VIEW SWITCH: Determine which view to show based on Apple Intelligence availability
                                switch effectiveAvailability {
                                case .available:
                                    // Apple Intelligence is available and user hasn't selected alternate models
                                    AppleIntelligenceAvailableView(
                                        isNewBoxState: isNewBoxState, 
                                        selectedBoxEntity: selectedBoxEntity,
                                        speechRecognizer: speechRecognizer,
                                        mlxModelManager: mlxModelManager,
                                        onQwenSelected: {
                                            if !qwenModelDownloaded {
                                                isDownloadingQwen = true
                                                Task {
                                                    await mlxModelManager.downloadQwenModel()
                                                    isDownloadingQwen = false
                                                    qwenModelDownloaded = true
                                                }
                                            }
                                        },
                                        onBoxSaved: handleBoxSaved,
                                        clearFieldsTrigger: clearFieldsTrigger
                                    )
                                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                                
                                case .unavailable(.deviceNotEligible):
                                    // Device not eligible OR user selected "Use alternate models"
                                    if qwenModelDownloaded {
                                        // Qwen already downloaded - show device not eligible view
                                        DeviceNotEligibleView(
                                            isNewBoxState: isNewBoxState, 
                                            selectedBoxEntity: selectedBoxEntity,
                                            speechRecognizer: speechRecognizer,
                                            mlxModelManager: mlxModelManager,
                                            onQwenSelected: {
                                                isDownloadingQwen = true
                                                Task {
                                                    await mlxModelManager.downloadQwenModel()
                                                    isDownloadingQwen = false
                                                    qwenModelDownloaded = true
                                                }
                                            },
                                            onBoxSaved: handleBoxSaved,
                                            clearFieldsTrigger: clearFieldsTrigger
                                        )
                                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                                    } else {
                                        // Qwen not downloaded - will be handled by priority check above (auto-download)
                                        EmptyView()
                                    }
                                
                                case .unavailable(.appleIntelligenceNotEnabled):
                                    // Apple Intelligence not enabled - show content behind overlay (input blocked)
                                    AppleIntelligenceAvailableView(
                                        isNewBoxState: isNewBoxState, 
                                        selectedBoxEntity: selectedBoxEntity,
                                        speechRecognizer: speechRecognizer,
                                        mlxModelManager: mlxModelManager,
                                        onQwenSelected: {
                                            if !qwenModelDownloaded {
                                                isDownloadingQwen = true
                                                Task {
                                                    await mlxModelManager.downloadQwenModel()
                                                    isDownloadingQwen = false
                                                    qwenModelDownloaded = true
                                                }
                                            }
                                        },
                                        onBoxSaved: handleBoxSaved,
                                        clearFieldsTrigger: clearFieldsTrigger
                                    )
                                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                                    .disabled(true)
                                    .opacity(0.3)
                                    
                                case .unavailable(.modelNotReady):
                                    // Apple Intelligence downloading - will be handled by priority check above
                                    EmptyView()
                                    
                                case .unavailable(_):
                                    // Unknown Apple Intelligence error - show content (no overlay currently)
                                    AppleIntelligenceAvailableView(
                                        isNewBoxState: isNewBoxState, 
                                        selectedBoxEntity: selectedBoxEntity,
                                        speechRecognizer: speechRecognizer,
                                        mlxModelManager: mlxModelManager,
                                        onQwenSelected: {
                                            if !qwenModelDownloaded {
                                                isDownloadingQwen = true
                                                Task {
                                                    await mlxModelManager.downloadQwenModel()
                                                    isDownloadingQwen = false
                                                    qwenModelDownloaded = true
                                                }
                                            }
                                        },
                                        onBoxSaved: handleBoxSaved,
                                        clearFieldsTrigger: clearFieldsTrigger
                                    )
                                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                                }
                            }
                            
                            // Overlay popups
                            // MARK: - TEMPORARY DEBUG - COMMENT OUT FOR PRODUCTION  
                            if case .unavailable(.appleIntelligenceNotEnabled) = currentAvailability,
                               !useAlternateModels {
                                AppleIntelligenceNotEnabledOverlay(onUseAlternateModels: {
                                    useAlternateModels = true
                                })
                            }
                            
                            // TEMPORARY DISABLE - checking if this overlay is blocking UI
                            // if case .unavailable(let other) = currentAvailability,
                            //    other != .deviceNotEligible,
                            //    other != .appleIntelligenceNotEnabled,
                            //    other != .modelNotReady {
                            //     ModelUnavailableOverlay(reason: other)
                            // }
                            // END TEMPORARY DEBUG
                        }
                        
                        Spacer()
                    }
                }
        }
    
    // MARK: - Swipe Gesture
    private func swipeGesture(geometry: GeometryProxy) -> some Gesture {
        DragGesture()
            .onChanged { value in
                // Only allow swipe up when a real box is selected (not "New Box")
                guard !isNewBoxState, selectedBoxEntity != nil else { return }
                
                // Only respond to upward swipes (negative translation)
                if value.translation.height < 0 {
                    dragOffset = max(value.translation.height, -geometry.size.height * 0.5)
                }
            }
            .onEnded { value in
                // Only allow swipe up when a real box is selected
                guard !isNewBoxState, selectedBoxEntity != nil else {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        dragOffset = 0
                    }
                    return
                }
                
                // Threshold for triggering the transition (1/3 of screen height upward)
                let threshold = -geometry.size.height / 3
                
                if value.translation.height < threshold {
                    // Distinct haptic feedback for successful swipe transition
                    let notificationFeedback = UINotificationFeedbackGenerator()
                    notificationFeedback.notificationOccurred(.success)
                    
                    // Trigger swipe to IdeaBoxView
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                        showingIdeaBoxView = true
                        dragOffset = 0
                    }
                } else {
                    // Snap back to original position
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        dragOffset = 0
                    }
                }
            }
    }
}

// TRIGGER CONDITIONS:
// - Apple Intelligence is available (.available)
// - User has NOT selected "Use alternate models" (useAlternateModels = false)
// SHOWS: BoxView/IdeaView with both ["Apple Intelligence", "Qwen2.5-1.5B"] available
// CALLBACK: onQwenSelected triggers download if Qwen not already downloaded
struct AppleIntelligenceAvailableView: View {
    let isNewBoxState: Bool
    let selectedBoxEntity: Box?
    @ObservedObject var speechRecognizer: SpeechRecognizer
    @ObservedObject var mlxModelManager: MLXModelManager
    let onQwenSelected: () -> Void
    let onBoxSaved: ((Box) -> Void)?
    let clearFieldsTrigger: Bool
    @Environment(\.colorPalette) private var colors
    
    var body: some View {
        VStack {
            // Embedded content based on box selection - full models available
            if isNewBoxState {
                BoxView(
                    availableModels: ["Apple Intelligence", "Qwen2.5-1.5B"],
                    speechRecognizer: speechRecognizer,
                    mlxModelManager: mlxModelManager,
                    onModelSelected: { model in
                        if model == "Qwen2.5-1.5B" {
                            onQwenSelected()
                        }
                    },
                    onBoxSaved: onBoxSaved,
                    clearFieldsTrigger: clearFieldsTrigger
                )
            } else {
                IdeaView(
                    selectedBox: selectedBoxEntity, 
                    availableModels: ["Apple Intelligence", "Qwen2.5-1.5B"],
                    speechRecognizer: speechRecognizer,
                    mlxModelManager: mlxModelManager,
                    onModelSelected: { model in
                        if model == "Qwen2.5-1.5B" {
                            onQwenSelected()
                        }
                    }
                )
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// TRIGGER CONDITIONS:
// - Device is not eligible for Apple Intelligence (.unavailable(.deviceNotEligible))
// - OR user selected "Use alternate models" (useAlternateModels = true)
// - AND Qwen is already downloaded (qwenModelDownloaded = true)
// - AND not currently downloading (isDownloadingQwen = false)
// SHOWS: BoxView/IdeaView with only ["Qwen2.5-1.5B"] available
// CALLBACK: onQwenSelected always triggers download (for re-download scenarios)
struct DeviceNotEligibleView: View {
    let isNewBoxState: Bool
    let selectedBoxEntity: Box?
    @ObservedObject var speechRecognizer: SpeechRecognizer
    @ObservedObject var mlxModelManager: MLXModelManager
    let onQwenSelected: () -> Void
    let onBoxSaved: ((Box) -> Void)?
    let clearFieldsTrigger: Bool
    @Environment(\.colorPalette) private var colors
    
    var body: some View {
        VStack {
            // Embedded content based on box selection - only Qwen available
            if isNewBoxState {
                BoxView(
                    availableModels: ["Qwen2.5-1.5B"],
                    speechRecognizer: speechRecognizer,
                    mlxModelManager: mlxModelManager,
                    onModelSelected: { model in
                        if model == "Qwen2.5-1.5B" {
                            onQwenSelected()
                        }
                    },
                    onBoxSaved: onBoxSaved,
                    clearFieldsTrigger: clearFieldsTrigger
                )
            } else {
                IdeaView(
                    selectedBox: selectedBoxEntity, 
                    availableModels: ["Qwen2.5-1.5B"],
                    speechRecognizer: speechRecognizer,
                    mlxModelManager: mlxModelManager,
                    onModelSelected: { model in
                        if model == "Qwen2.5-1.5B" {
                            onQwenSelected()
                        }
                    }
                )
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct AppleIntelligenceNotEnabledView: View {
    let isNewBoxState: Bool
    let selectedBoxEntity: Box?
    let onBoxSaved: ((Box) -> Void)?
    let clearFieldsTrigger: Bool
    @Environment(\.colorPalette) private var colors
    
    var body: some View {
        VStack {
            // Embedded content based on box selection
            if isNewBoxState {
                BoxView(
                    mlxModelManager: MLXModelManager.shared,
                    onBoxSaved: onBoxSaved,
                    clearFieldsTrigger: clearFieldsTrigger
                )
            } else {
                IdeaView(selectedBox: selectedBoxEntity, mlxModelManager: MLXModelManager.shared)
            }
            
            Spacer()
        }
    }
}

// TRIGGER CONDITIONS (PRIORITY CHECK - shown regardless of other cases):
// - Currently downloading Qwen (isDownloadingQwen = true)
// - OR Apple Intelligence is downloading (.unavailable(.modelNotReady))
// - OR device not eligible AND Qwen not downloaded (.unavailable(.deviceNotEligible) && !qwenModelDownloaded)
// SHOWS: Loading screen with progress indicator and dynamic titles based on what's downloading
// AUTO-TRIGGER: Automatically starts Qwen download if device not eligible and Qwen not downloaded
struct ModelNotReadyView: View {
    let isNewBoxState: Bool
    let selectedBoxEntity: Box?
    let isDownloadingQwen: Bool
    let isDownloadingAppleIntelligence: Bool
    let onBoxSaved: ((Box) -> Void)?
    let clearFieldsTrigger: Bool
    @ObservedObject var mlxModelManager: MLXModelManager
    @Environment(\.colorPalette) private var colors
    
    init(isNewBoxState: Bool, selectedBoxEntity: Box?, isDownloadingQwen: Bool = false, isDownloadingAppleIntelligence: Bool = false, onBoxSaved: ((Box) -> Void)? = nil, clearFieldsTrigger: Bool = false, mlxModelManager: MLXModelManager? = nil) {
        self.isNewBoxState = isNewBoxState
        self.selectedBoxEntity = selectedBoxEntity
        self.isDownloadingQwen = isDownloadingQwen
        self.isDownloadingAppleIntelligence = isDownloadingAppleIntelligence
        self.onBoxSaved = onBoxSaved
        self.clearFieldsTrigger = clearFieldsTrigger
        self.mlxModelManager = mlxModelManager ?? MLXModelManager.shared
    }
    
    private var downloadTitle: String {
        if isDownloadingQwen && isDownloadingAppleIntelligence {
            return "Downloading Models"
        } else if isDownloadingQwen {
            return mlxModelManager.downloadStatus.isEmpty ? "Downloading Qwen2.5-1.5B" : mlxModelManager.downloadStatus
        } else if isDownloadingAppleIntelligence {
            return "Preparing Apple Intelligence"
        } else {
            return "Downloading Models"
        }
    }
    
    private var downloadSubtitle: String {
        if isDownloadingQwen && isDownloadingAppleIntelligence {
            return "AI models are being downloaded and prepared for use"
        } else if isDownloadingQwen {
            return "Qwen2.5-1.5B model is being downloaded and optimized for local inference"
        } else if isDownloadingAppleIntelligence {
            return "Apple Intelligence is being prepared for use"
        } else {
            return "AI models are being downloaded and prepared for use"
        }
    }
    
    var body: some View {
        ZStack {
            // Background content
            VStack {
                if isNewBoxState {
                    BoxView(
                        availableModels: ["Apple Intelligence", "Qwen2.5-1.5B"], 
                        mlxModelManager: MLXModelManager.shared,
                        onBoxSaved: onBoxSaved,
                        clearFieldsTrigger: clearFieldsTrigger
                    )
                } else {
                    IdeaView(selectedBox: selectedBoxEntity, availableModels: ["Apple Intelligence", "Qwen2.5-1.5B"], mlxModelManager: MLXModelManager.shared)
                }
                
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .opacity(isDownloadingQwen || isDownloadingAppleIntelligence ? 0.3 : 1.0)
            
            // Loading overlay - only show if actually downloading
            if isDownloadingQwen || isDownloadingAppleIntelligence {
                VStack(spacing: 24) {
                    if isDownloadingQwen && mlxModelManager.downloadProgress > 0 {
                        // Show determinate progress for MLX downloads
                        ProgressView(value: mlxModelManager.downloadProgress)
                            .progressViewStyle(LinearProgressViewStyle(tint: colors.accent))
                            .scaleEffect(1.2)
                    } else {
                        // Show indeterminate progress
                        ProgressView()
                            .scaleEffect(1.5)
                            .progressViewStyle(CircularProgressViewStyle(tint: colors.accent))
                    }
                    
                    Text(downloadTitle)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(colors.text)
                        .multilineTextAlignment(.center)
                    
                    Text(downloadSubtitle)
                        .font(.system(size: 16))
                        .foregroundColor(colors.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .padding(32)
                .background(colors.surface)
                .cornerRadius(12)
                .padding(.horizontal, 20)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct ModelUnavailableView: View {
    let reason: any Error
    let isNewBoxState: Bool
    let selectedBoxEntity: Box?
    let onBoxSaved: ((Box) -> Void)?
    let clearFieldsTrigger: Bool
    @Environment(\.colorPalette) private var colors
    
    var body: some View {
        VStack {
            // Embedded content based on box selection
            if isNewBoxState {
                BoxView(
                    mlxModelManager: MLXModelManager.shared,
                    onBoxSaved: onBoxSaved,
                    clearFieldsTrigger: clearFieldsTrigger
                )
            } else {
                IdeaView(selectedBox: selectedBoxEntity, mlxModelManager: MLXModelManager.shared)
            }
            
            Spacer()
        }
    }
}

struct BoxView: View {
    @Environment(\.colorPalette) private var colors
    @State private var boxName = ""
    @State private var boxContent = ""
    @State private var selectedModel: String
    
    let availableModels: [String]
    @ObservedObject var speechRecognizer: SpeechRecognizer
    let mlxModelManager: MLXModelManager
    let onModelSelected: ((String) -> Void)?
    let onBoxSaved: ((Box) -> Void)?
    let clearFieldsTrigger: Bool
    
    init(availableModels: [String] = ["Apple Intelligence", "Qwen2.5-1.5B"], speechRecognizer: SpeechRecognizer? = nil, mlxModelManager: MLXModelManager = MLXModelManager.shared, onModelSelected: ((String) -> Void)? = nil, onBoxSaved: ((Box) -> Void)? = nil, clearFieldsTrigger: Bool = false) {
        self.availableModels = availableModels
        self.speechRecognizer = speechRecognizer ?? SpeechRecognizer()
        self.mlxModelManager = mlxModelManager
        self.onModelSelected = onModelSelected
        self.onBoxSaved = onBoxSaved
        self.clearFieldsTrigger = clearFieldsTrigger
        self._selectedModel = State(initialValue: availableModels.first ?? "Unknown")
    }
    
    var body: some View {
        VStack(spacing: 20) {
            // Box name input
            TextField("Box name...", text: $boxName)
                .font(.system(size: 16))
                .foregroundColor(colors.text)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(colors.surface)
                .cornerRadius(12)
                .padding(.horizontal, 20)
            
            // Content text area
            TextField("Ideate the idea here...", text: $boxContent, axis: .vertical)
                .font(.system(size: 16))
                .foregroundColor(colors.text)
                .background(colors.surface)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .lineLimit(nil)
                .multilineTextAlignment(.leading)
                .accentColor(colors.text)
                .frame(maxWidth: .infinity, minHeight: 120, maxHeight: .infinity, alignment: .topLeading)
                .background(colors.surface)
                .cornerRadius(12)
                .padding(.horizontal, 20)
            
            // Model selector with microphone
            HStack {
                Menu {
                    ForEach(availableModels, id: \.self) { model in
                        Button(model) {
                            selectedModel = model
                            onModelSelected?(model)
                        }
                    }
                } label: {
                    Text(selectedModel)
                        .font(.system(size: 16))
                        .foregroundColor(colors.textSecondary)
                }
                
                Spacer()
                
                Button(action: {}) {
                    Image(systemName: speechRecognizer.isRecording ? "mic.circle.fill" : "mic.fill")
                        .font(.system(size: 20))
                        .foregroundColor(speechRecognizer.isRecording ? .red : colors.textSecondary)
                        .scaleEffect(speechRecognizer.isRecording ? 1.2 : 1.0)
                        .animation(.easeInOut(duration: 0.1), value: speechRecognizer.isRecording)
                }
                .simultaneousGesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { _ in
                            if !speechRecognizer.isRecording {
                                speechRecognizer.setOriginalText(boxContent)
                                speechRecognizer.startRecording()
                            }
                        }
                        .onEnded { _ in
                            if speechRecognizer.isRecording {
                                speechRecognizer.stopRecording()
                                speechRecognizer.finalizeText()
                            }
                        }
                )
                .onChange(of: speechRecognizer.transcript) {
                    if speechRecognizer.isRecording {
                        speechRecognizer.updateTextRealTime(&boxContent)
                    }
                }
            }
            .padding(.horizontal, 20)
            
            // Ideate button
            NavigationLink(destination: ReviewIdeaView(
                title: boxName.isEmpty ? "Untitled Idea" : boxName,
                content: boxContent,
                modelType: AIModelType.from(string: selectedModel),
                mlxModelManager: mlxModelManager,
                onBoxSaved: onBoxSaved
            )) {
                Text("Ideate")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(colors.background)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(colors.text)
                    .cornerRadius(12)
            }
            .disabled(boxContent.isEmpty)
            .padding(.horizontal, 20)
            
            Spacer()
        }
        .onChange(of: clearFieldsTrigger) { _ in
            // Clear fields when trigger changes
            boxName = ""
            boxContent = ""
            speechRecognizer.clearTranscript()
        }
    }
}

struct IdeaView: View {
    let selectedBox: Box?
    @Environment(\.colorPalette) private var colors
    @State private var ideaContent = ""
    @State private var selectedModel: String
    
    let availableModels: [String]
    @ObservedObject var speechRecognizer: SpeechRecognizer
    let mlxModelManager: MLXModelManager
    let onModelSelected: ((String) -> Void)?
    
    init(selectedBox: Box?, availableModels: [String] = ["Apple Intelligence", "Qwen2.5-1.5B"], speechRecognizer: SpeechRecognizer? = nil, mlxModelManager: MLXModelManager = MLXModelManager.shared, onModelSelected: ((String) -> Void)? = nil) {
        self.selectedBox = selectedBox
        self.availableModels = availableModels
        self.speechRecognizer = speechRecognizer ?? SpeechRecognizer()
        self.mlxModelManager = mlxModelManager
        self.onModelSelected = onModelSelected
        self._selectedModel = State(initialValue: availableModels.first ?? "Unknown")
    }
    
    var body: some View {
        VStack(spacing: 20) {
            if let box = selectedBox {
                // Content text area
                TextField("Dump your idea...", text: $ideaContent, axis: .vertical)
                    .font(.system(size: 16))
                    .foregroundColor(colors.text)
                    .background(colors.surface)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .lineLimit(nil)
                    .multilineTextAlignment(.leading)
                    .accentColor(colors.text)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                    .background(colors.surface)
                    .cornerRadius(12)
                    .padding(.horizontal, 20)
                
                // Model selector with microphone
                HStack {
                    Menu {
                        ForEach(availableModels, id: \.self) { model in
                            Button(model) {
                                selectedModel = model
                                onModelSelected?(model)
                            }
                        }
                    } label: {
                        Text(selectedModel)
                            .font(.system(size: 16))
                            .foregroundColor(colors.textSecondary)
                    }
                    
                    Spacer()
                    
                    Button(action: {}) {
                        Image(systemName: speechRecognizer.isRecording ? "mic.circle.fill" : "mic.fill")
                            .font(.system(size: 20))
                            .foregroundColor(speechRecognizer.isRecording ? .red : colors.textSecondary)
                            .scaleEffect(speechRecognizer.isRecording ? 1.2 : 1.0)
                            .animation(.easeInOut(duration: 0.1), value: speechRecognizer.isRecording)
                    }
                    .simultaneousGesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { _ in
                                if !speechRecognizer.isRecording {
                                    speechRecognizer.setOriginalText(ideaContent)
                                    speechRecognizer.startRecording()
                                }
                            }
                            .onEnded { _ in
                                if speechRecognizer.isRecording {
                                    speechRecognizer.stopRecording()
                                    speechRecognizer.finalizeText()
                                }
                            }
                    )
                    .onChange(of: speechRecognizer.transcript) {
                        if speechRecognizer.isRecording {
                            speechRecognizer.updateTextRealTime(&ideaContent)
                        }
                    }
                }
                .padding(.horizontal, 20)
                
                // Dump button
                NavigationLink(destination: ReviewDumpView(
                    dumpText: ideaContent,
                    targetBox: box,
                    modelType: AIModelType.from(string: selectedModel),
                    mlxModelManager: mlxModelManager,
                    onIdeasSaved: { savedIdeas in
                        // Clear the idea content when ideas are saved
                        ideaContent = ""
                        print("💡 Ideas saved: \(savedIdeas.count) ideas added to \(box.name ?? "box")")
                    }
                )) {
                    Text("Dump")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(colors.background)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(colors.text)
                        .cornerRadius(12)
                }
                .disabled(ideaContent.isEmpty)
                .padding(.horizontal, 20)
                
            } else {
                Text("No Box Selected")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(colors.text)
                    .padding(.top, 20)
            }
            
            Spacer()
        }
    }
}

// TRIGGER CONDITIONS (OVERLAY):
// - Apple Intelligence is not enabled (.unavailable(.appleIntelligenceNotEnabled))
// - AND user has NOT selected "Use alternate models" (useAlternateModels = false)
// SHOWS: Popup overlay with "Enable Apple Intelligence" and "Use alternate models" buttons
// BLOCKS INPUT: Background view is disabled and dimmed until button is pressed
struct AppleIntelligenceNotEnabledOverlay: View {
    let onUseAlternateModels: () -> Void
    @Environment(\.colorPalette) private var colors
    
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "gear")
                .font(.system(size: 48))
                .foregroundColor(colors.accent)
            
            Text("Enable Apple Intelligence")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(colors.text)
                .multilineTextAlignment(.center)
            
            Text("Please enable Apple Intelligence in Settings to access AI features")
                .font(.system(size: 16))
                .foregroundColor(colors.textSecondary)
                .multilineTextAlignment(.center)
            
            VStack(spacing: 12) {
                Button("Open Settings") {
                    if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(settingsURL)
                    }
                }
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(colors.background)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(colors.text)
                .cornerRadius(12)
                
                Button("Use alternate models") {
                    onUseAlternateModels()
                }
                .font(.system(size: 16))
                .foregroundColor(colors.textSecondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(colors.surface)
                .cornerRadius(12)
            }
        }
        .padding(32)
        .background(colors.surface)
        .cornerRadius(12)
        .padding(.horizontal, 20)
    }
}

// TRIGGER CONDITIONS (OVERLAY - CURRENTLY DISABLED):
// - Apple Intelligence is unavailable for unknown reasons
// - NOT deviceNotEligible, appleIntelligenceNotEnabled, or modelNotReady
// SHOWS: Generic "AI Unavailable" popup with retry and continue options
// NOTE: Currently commented out to debug UI issues
struct ModelUnavailableOverlay: View {
    let reason: SystemLanguageModel.Availability.UnavailableReason
    @Environment(\.colorPalette) private var colors
    
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundColor(.orange)
            
            Text("AI Unavailable")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(colors.text)
                .multilineTextAlignment(.center)
            
            Text("Apple Intelligence is temporarily unavailable. You can continue using the app with basic features.")
                .font(.system(size: 16))
                .foregroundColor(colors.textSecondary)
                .multilineTextAlignment(.center)
            
            VStack(spacing: 12) {
                Button("Retry") {
                    // Handle retry logic
                }
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(colors.background)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(colors.text)
                .cornerRadius(12)
                
                Button("Continue without AI") {
                    // Handle fallback mode
                }
                .font(.system(size: 16))
                .foregroundColor(colors.textSecondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(colors.surface)
                .cornerRadius(12)
            }
        }
        .padding(32)
        .background(colors.surface)
        .cornerRadius(12)
        .padding(.horizontal, 20)
    }
}

#Preview {
    NewView()
}
