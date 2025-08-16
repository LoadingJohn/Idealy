//
//  ReviewDumpView.swift
//  Idealy
//
//  Created by Claude Code on 15/8/2025.
//

import SwiftUI
internal import CoreData

struct ReviewDumpView: View {
    @StateObject private var dumpProcessor: DumpProcessorVM
    @Environment(\.colorPalette) private var colors
    @Environment(\.managedObjectContext) private var viewContext
    
    let dumpText: String
    let targetBox: Box
    let modelName: String
    
    init(dumpText: String, targetBox: Box, modelName: String, mlxModelManager: MLXModelManager) {
        self.dumpText = dumpText
        self.targetBox = targetBox
        self.modelName = modelName
        
        // Initialize the dumpProcessor with the passed MLXModelManager
        self._dumpProcessor = StateObject(wrappedValue: DumpProcessorVM(mlxModelManager: mlxModelManager))
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background
                colors.background
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header section
                    VStack(spacing: 24) {
                        VStack(spacing: 12) {
                            Text("Processing Dump")
                                .font(.system(size: 32, weight: .bold))
                                .foregroundColor(colors.text)
                            
                            Text("Adding to \"\(targetBox.name ?? "Unnamed Box")\"")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(colors.accent)
                                .multilineTextAlignment(.center)
                        }
                        
                        Text("AI is analyzing your idea dump and creating structured insights")
                            .font(.system(size: 17))
                            .foregroundColor(colors.textSecondary)
                            .multilineTextAlignment(.center)
                            .lineLimit(nil)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 40)
                    
                    Spacer()
                    
                    // Content section - centered
                    VStack {
                        if dumpProcessor.isProcessing {
                            VStack(spacing: 32) {
                                ProgressView()
                                    .scaleEffect(2.0)
                                    .progressViewStyle(CircularProgressViewStyle(tint: colors.accent))
                                
                                VStack(spacing: 12) {
                                    Text(dumpProcessor.currentStatus)
                                        .font(.system(size: 18, weight: .medium))
                                        .foregroundColor(colors.text)
                                        .multilineTextAlignment(.center)
                                    
                                    Text("Using \(modelName)")
                                        .font(.system(size: 14))
                                        .foregroundColor(colors.textSecondary)
                                }
                            }
                        }
                        
                        if dumpProcessor.hasError {
                            VStack(spacing: 24) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .font(.system(size: 64))
                                    .foregroundColor(.red)
                                
                                VStack(spacing: 12) {
                                    Text("Processing Error")
                                        .font(.system(size: 24, weight: .semibold))
                                        .foregroundColor(colors.text)
                                    
                                    Text(dumpProcessor.errorMessage)
                                        .font(.system(size: 16))
                                        .foregroundColor(colors.textSecondary)
                                        .multilineTextAlignment(.center)
                                        .lineLimit(nil)
                                }
                            }
                            .padding(.horizontal, 32)
                        }
                    }
                    
                    Spacer()
                    Spacer()
                }
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(false)
        .onAppear {
            // Set the view context for Core Data operations
            dumpProcessor.viewContext = viewContext
            dumpProcessor.processDump(dumpText: dumpText, box: targetBox, modelName: modelName)
        }
    }
}

#Preview {
    let context = PersistenceController.preview.container.viewContext
    let sampleBox = Box(context: context)
    sampleBox.name = "Sample Box"
    sampleBox.id = UUID()
    sampleBox.createdDate = Date()
    
    return NavigationView {
        ReviewDumpView(
            dumpText: "Sample dump text for testing",
            targetBox: sampleBox,
            modelName: "Apple Intelligence",
            mlxModelManager: MLXModelManager.shared
        )
        .environment(\.colorPalette, ColorPalette.light)
    }
}
