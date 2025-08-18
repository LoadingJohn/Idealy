//
//  IdeaBoxView.swift
//  Idealy
//
//  Created by Claude Code on 10/8/2025.
//

import SwiftUI
internal import CoreData

struct IdeaBoxView: View {
    let box: Box
    let onBack: () -> Void
    let onBoxDeleted: (() -> Void)?
    @Environment(\.colorPalette) private var colors
    @Environment(\.managedObjectContext) private var viewContext
    @State private var recentIdeas: [Idea] = []
    @State private var ideasByClassification: [String: [Idea]] = [:]
    @State private var showEditIdeaView = false
    @State private var selectedIdea: Idea?
    @State private var showEditBoxView = false
    @State private var showDeleteConfirmation = false
    
    // Fetch ideas for this box
    @FetchRequest private var ideas: FetchedResults<Idea>
    
    init(box: Box, onBack: @escaping () -> Void, onBoxDeleted: (() -> Void)? = nil) {
        self.box = box
        self.onBack = onBack
        self.onBoxDeleted = onBoxDeleted
        
        // Create fetch request for ideas belonging to this box
        self._ideas = FetchRequest(
            sortDescriptors: [NSSortDescriptor(keyPath: \Idea.createdDate, ascending: false)],
            predicate: NSPredicate(format: "box == %@", box)
        )
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                colors.background
                    .ignoresSafeArea()
                
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 0) {
                        // Box Summary Section (if exists)
                        if let summary = box.summary, !summary.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Summary")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(colors.accent)
                                
                                Text(summary)
                                    .font(.system(size: 14))
                                    .foregroundColor(colors.text)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(colors.surface)
                                    .cornerRadius(8)
                            }
                            .padding(.horizontal, 16)
                            .padding(.top, 20)
                            .padding(.bottom, 32)
                        }
                        
                        // RECENT IDEAS SECTION - Top-level, non-scrollable
                        if !recentIdeas.isEmpty {
                            VStack(alignment: .leading, spacing: 10) {
                                ForEach(recentIdeas.prefix(3), id: \.id) { idea in
                                    Button(action: {
                                        // Haptic feedback for idea selection
                                        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                                        impactFeedback.impactOccurred()
                                        selectedIdea = idea
                                        showEditIdeaView = true
                                    }) {
                                        RecentIdeaCardView(idea: idea, colors: colors)
                                        .padding(.vertical, 16)
                                        .padding(.horizontal, 16)
                                        .background(colors.surface)
                                        .cornerRadius(12)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.bottom, 32)
                        }
                        
                        // CLASSIFICATION SECTIONS
                        ForEach(Array(ideasByClassification.keys.sorted()), id: \.self) { classification in
                            if let ideas = ideasByClassification[classification], !ideas.isEmpty {
                                VStack(alignment: .leading, spacing: 16) {
                                    // Section title
                                    Text(classification.isEmpty ? "Uncategorized" : classification)
                                        .font(.system(size: 20, weight: .bold))
                                        .foregroundColor(colors.text)
                                        .padding(.horizontal, 16)
                                        .padding(.top, 24)
                                    
                                    // Ideas in this classification
                                    VStack(spacing: 0) {
                                        ForEach(ideas, id: \.id) { idea in
                                            Button(action: {
                                                // Haptic feedback for idea selection
                                                let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                                                impactFeedback.impactOccurred()
                                                selectedIdea = idea
                                                showEditIdeaView = true
                                            }) {
                                                ClassifiedIdeaCardView(idea: idea, colors: colors)
                                                .padding(.vertical, 16)
                                                .padding(.horizontal, 16)
                                                .background(Color.clear)
                                            }
                                            .buttonStyle(PlainButtonStyle())
                                            
                                            // Separator line (except for last item)
                                            if idea.id != ideas.last?.id {
                                                Divider()
                                                    .background(colors.textSecondary.opacity(0.1))
                                                    .padding(.horizontal, 16)
                                            }
                                        }
                                    }
                                    .background(colors.surface)
                                    .cornerRadius(12)
                                    .padding(.horizontal, 16)
                                }
                                .padding(.bottom, 24)
                            }
                        }
                        
                        // Empty state if no ideas
                        if ideas.isEmpty {
                            VStack(spacing: 12) {
                                Image(systemName: "lightbulb")
                                    .font(.system(size: 48))
                                    .foregroundColor(colors.textSecondary)
                                
                                Text("No ideas yet")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(colors.text)
                                
                                Text("Use the dump feature to add ideas to this box")
                                    .font(.system(size: 14))
                                    .foregroundColor(colors.textSecondary)
                                    .multilineTextAlignment(.center)
                            }
                            .padding(.vertical, 64)
                            .frame(maxWidth: .infinity)
                        }
                        
                        // Delete Button at bottom
                        VStack(spacing: 16) {
                            Divider()
                                .background(colors.textSecondary.opacity(0.2))
                                .padding(.horizontal, 16)
                            
                            Button(action: {
                                // Haptic feedback for delete button
                                let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                                impactFeedback.impactOccurred()
                                showDeleteConfirmation = true
                            }) {
                                HStack {
                                    Image(systemName: "trash")
                                        .font(.system(size: 16, weight: .medium))
                                    Text("Delete Box")
                                        .font(.system(size: 16, weight: .medium))
                                }
                                .foregroundColor(.red)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(Color.red.opacity(0.1))
                                .cornerRadius(8)
                            }
                            .padding(.horizontal, 16)
                        }
                        .padding(.top, 32)
                    }
                    .padding(.bottom, 32)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        // Haptic feedback for back button
                        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                        impactFeedback.impactOccurred()
                        onBack()
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(colors.accent)
                    }
                }
                
                ToolbarItem(placement: .principal) {
                    Text(box.name ?? "Unnamed Box")
                        .font(.headline)
                        .foregroundColor(colors.text)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        // Haptic feedback for edit box button
                        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                        impactFeedback.impactOccurred()
                        showEditBoxView = true
                    }) {
                        Image(systemName: "contact.sensor")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(colors.accent)
                    }
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .sheet(isPresented: $showEditIdeaView) {
            if let idea = selectedIdea {
                EditIdeaView(
                    idea: idea,
                    onBack: {
                        showEditIdeaView = false
                    },
                    onSaved: {
                        loadIdeasData() // Refresh data after editing
                    },
                    onIdeaDeleted: {
                        loadIdeasData() // Refresh data after deletion
                    }
                )
            }
        }
        .sheet(isPresented: $showEditBoxView) {
            EditBoxView(
                box: box,
                onBack: {
                    showEditBoxView = false
                },
                onSaved: {
                    // Box data will automatically update via Core Data
                }
            )
        }
        .confirmationDialog(
            "Are you sure you want to delete this box?", 
            isPresented: $showDeleteConfirmation, 
            titleVisibility: .visible
        ) {
            Button("Delete Box", role: .destructive) {
                deleteBox()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This will permanently delete the box and all its associated ideas. This action cannot be undone.")
        }
        .onAppear {
            loadIdeasData()
        }
    }
    
    // MARK: - Delete Functionality
    
    private func deleteBox() {
        // Haptic feedback for destructive action
        let notificationFeedback = UINotificationFeedbackGenerator()
        notificationFeedback.notificationOccurred(.warning)
        
        // Delete all associated ideas first (Core Data should handle this automatically due to cascade delete, but being explicit)
        for idea in ideas {
            viewContext.delete(idea)
        }
        
        // Delete the box
        viewContext.delete(box)
        
        // Save changes
        do {
            try viewContext.save()
            print("✅ Successfully deleted box: \(box.name ?? "Unnamed Box") and \(ideas.count) associated ideas")
            
            // Success haptic feedback
            let successFeedback = UINotificationFeedbackGenerator()
            successFeedback.notificationOccurred(.success)
            
            // Notify that box was deleted (to reset NewView selection)
            onBoxDeleted?()
            
            // Return to NewView
            onBack()
        } catch {
            print("❌ Failed to delete box: \(error)")
            
            // Error haptic feedback  
            let errorFeedback = UINotificationFeedbackGenerator()
            errorFeedback.notificationOccurred(.error)
            
            // TODO: Show error alert to user
        }
    }
    
    
    // MARK: - Data Loading
    private func loadIdeasData() {
        // Get recent ideas (latest 3)
        recentIdeas = Array(ideas.prefix(3))
        
        // Group ideas by classification
        ideasByClassification = Dictionary(grouping: Array(ideas)) { idea in
            idea.classification ?? ""
        }
    }
    
    // MARK: - Timestamp Helpers
    private func timeAgoString(from date: Date?) -> String {
        guard let date = date else { return "unknown" }
        
        let now = Date()
        let components = Calendar.current.dateComponents([.minute, .hour, .day, .weekOfYear, .month, .year], from: date, to: now)
        
        if let years = components.year, years > 0 {
            return "\(years)y"
        } else if let months = components.month, months > 0 {
            return "\(months)m"
        } else if let weeks = components.weekOfYear, weeks > 0 {
            return "\(weeks)w"
        } else if let days = components.day, days > 0 {
            return "\(days)d"
        } else if let hours = components.hour, hours > 0 {
            return "\(hours)h"
        } else if let minutes = components.minute, minutes > 0 {
            return "\(minutes)m"
        } else {
            return "now"
        }
    }
    
    private func timestampColor(for date: Date?) -> Color {
        guard let date = date else { return colors.textSecondary }
        
        let now = Date()
        let components = Calendar.current.dateComponents([.minute, .hour, .day, .weekOfYear, .month, .year], from: date, to: now)
        
        if let years = components.year, years > 0 {
            return colors.accent.opacity(0.7) // Similar to orange
        } else if let months = components.month, months > 0 {
            return colors.accent.opacity(0.7) // Similar to orange
        } else if let weeks = components.weekOfYear, weeks > 0 {
            return Color.green.opacity(0.8) // Green for weeks
        } else if let days = components.day, days > 0 {
            return Color.cyan.opacity(0.8) // Cyan for days
        } else if let hours = components.hour, hours > 0 {
            return Color.cyan.opacity(0.8) // Cyan for hours
        } else {
            return Color.cyan.opacity(0.8) // Cyan for minutes/now
        }
    }
}

// MARK: - Recent Idea Card (shows classification badge at top)
struct RecentIdeaCardView: View {
    let idea: Idea
    let colors: ColorPalette
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Classification at top
            HStack {
                if let classification = idea.classification, !classification.isEmpty {
                    Text(classification)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(colors.accent)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(colors.accent.opacity(0.1))
                        .cornerRadius(4)
                }
                
                Spacer()
                
                if let createdDate = idea.createdDate {
                    Text(timeAgoString(from: createdDate))
                        .font(.system(size: 12))
                        .foregroundColor(timestampColor(for: createdDate))
                }
            }
            
            // Title and summary with more horizontal space
            VStack(alignment: .leading, spacing: 4) {
                Text(idea.title ?? "Untitled Idea")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(colors.text)
                    .multilineTextAlignment(.leading)
                    .lineLimit(2)
                
                if let summary = idea.summary, !summary.isEmpty {
                    Text(summary)
                        .font(.system(size: 14))
                        .foregroundColor(colors.textSecondary)
                        .lineLimit(3)
                }
            }
        }
    }
    
    // Helper functions (duplicated for standalone component)
    private func timeAgoString(from date: Date?) -> String {
        guard let date = date else { return "unknown" }
        
        let now = Date()
        let components = Calendar.current.dateComponents([.minute, .hour, .day, .weekOfYear, .month, .year], from: date, to: now)
        
        if let years = components.year, years > 0 {
            return "\(years)y"
        } else if let months = components.month, months > 0 {
            return "\(months)m"
        } else if let weeks = components.weekOfYear, weeks > 0 {
            return "\(weeks)w"
        } else if let days = components.day, days > 0 {
            return "\(days)d"
        } else if let hours = components.hour, hours > 0 {
            return "\(hours)h"
        } else if let minutes = components.minute, minutes > 0 {
            return "\(minutes)m"
        } else {
            return "now"
        }
    }
    
    private func timestampColor(for date: Date?) -> Color {
        guard let date = date else { return colors.textSecondary }
        
        let now = Date()
        let components = Calendar.current.dateComponents([.minute, .hour, .day, .weekOfYear, .month, .year], from: date, to: now)
        
        if let years = components.year, years > 0 {
            return colors.accent.opacity(0.7)
        } else if let months = components.month, months > 0 {
            return colors.accent.opacity(0.7)
        } else if let weeks = components.weekOfYear, weeks > 0 {
            return Color.green.opacity(0.8)
        } else if let days = components.day, days > 0 {
            return Color.cyan.opacity(0.8)
        } else if let hours = components.hour, hours > 0 {
            return Color.cyan.opacity(0.8)
        } else {
            return Color.cyan.opacity(0.8)
        }
    }
}

// MARK: - Classified Idea Card (no classification badge, compact layout)
struct ClassifiedIdeaCardView: View {
    let idea: Idea
    let colors: ColorPalette
    
    var body: some View {
        HStack {
            // Title and summary with full width (no classification badge taking space)
            VStack(alignment: .leading, spacing: 4) {
                Text(idea.title ?? "Untitled Idea")
                    .font(.system(size: 16))
                    .foregroundColor(colors.text)
                    .multilineTextAlignment(.leading)
                    .lineLimit(2)
                
                if let summary = idea.summary, !summary.isEmpty {
                    Text(summary)
                        .font(.system(size: 14))
                        .foregroundColor(colors.textSecondary)
                        .lineLimit(2)
                }
            }
            
            Spacer()
            
            // Timestamp at right
            if let createdDate = idea.createdDate {
                Text(timeAgoString(from: createdDate))
                    .font(.system(size: 12))
                    .foregroundColor(timestampColor(for: createdDate))
            }
        }
    }
    
    // Helper functions (duplicated for standalone component)
    private func timeAgoString(from date: Date?) -> String {
        guard let date = date else { return "unknown" }
        
        let now = Date()
        let components = Calendar.current.dateComponents([.minute, .hour, .day, .weekOfYear, .month, .year], from: date, to: now)
        
        if let years = components.year, years > 0 {
            return "\(years)y"
        } else if let months = components.month, months > 0 {
            return "\(months)m"
        } else if let weeks = components.weekOfYear, weeks > 0 {
            return "\(weeks)w"
        } else if let days = components.day, days > 0 {
            return "\(days)d"
        } else if let hours = components.hour, hours > 0 {
            return "\(hours)h"
        } else if let minutes = components.minute, minutes > 0 {
            return "\(minutes)m"
        } else {
            return "now"
        }
    }
    
    private func timestampColor(for date: Date?) -> Color {
        guard let date = date else { return colors.textSecondary }
        
        let now = Date()
        let components = Calendar.current.dateComponents([.minute, .hour, .day, .weekOfYear, .month, .year], from: date, to: now)
        
        if let years = components.year, years > 0 {
            return colors.accent.opacity(0.7)
        } else if let months = components.month, months > 0 {
            return colors.accent.opacity(0.7)
        } else if let weeks = components.weekOfYear, weeks > 0 {
            return Color.green.opacity(0.8)
        } else if let days = components.day, days > 0 {
            return Color.cyan.opacity(0.8)
        } else if let hours = components.hour, hours > 0 {
            return Color.cyan.opacity(0.8)
        } else {
            return Color.cyan.opacity(0.8)
        }
    }
}

struct IdeaCardView: View {
    let idea: Idea
    let colors: ColorPalette
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Title and Classification
            HStack {
                Text(idea.title ?? "Untitled Idea")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(colors.text)
                
                Spacer()
                
                if let classification = idea.classification, !classification.isEmpty {
                    Text(classification)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(colors.accent)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(colors.accent.opacity(0.1))
                        .cornerRadius(6)
                }
            }
            
            // Summary
            if let summary = idea.summary, !summary.isEmpty {
                Text(summary)
                    .font(.system(size: 14))
                    .foregroundColor(colors.text)
                    .lineLimit(nil)
            }
            
            // Pros and Cons
            HStack(alignment: .top, spacing: 16) {
                if let pros = idea.pros, !pros.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 12))
                                .foregroundColor(.green)
                            Text("Pros")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(colors.textSecondary)
                        }
                        
                        Text(pros)
                            .font(.system(size: 12))
                            .foregroundColor(colors.text)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                
                if let cons = idea.cons, !cons.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Image(systemName: "minus.circle.fill")
                                .font(.system(size: 12))
                                .foregroundColor(.red)
                            Text("Cons")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(colors.textSecondary)
                        }
                        
                        Text(cons)
                            .font(.system(size: 12))
                            .foregroundColor(colors.text)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            
            // Date
            if let createdDate = idea.createdDate {
                Text(createdDate, style: .date)
                    .font(.system(size: 11))
                    .foregroundColor(colors.textSecondary)
            }
        }
        .padding(16)
        .background(colors.surface)
        .cornerRadius(12)
    }
}

#Preview {
    let context = PersistenceController.preview.container.viewContext
    let sampleBox = Box(context: context)
    sampleBox.name = "Sample Box"
    sampleBox.summary = "This is a sample box for testing the IdeaBoxView"
    sampleBox.id = UUID()
    sampleBox.createdDate = Date()
    
    return IdeaBoxView(box: sampleBox, onBack: {})
        .environment(\.colorPalette, ColorPalette.light)
}
