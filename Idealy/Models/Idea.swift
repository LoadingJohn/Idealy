//
//  Idea.swift
//  Idealy
//
//  Created by Claude Code on 10/8/2025.
//

import Foundation

struct IdeaModel {
    let classification: String
    let cons: String
    let createdDate: Date
    let id: UUID
    let pros: String
    let relatedIdeas: [UUID]
    let summary: String
    let title: String
    
    init() {
        self.classification = ""
        self.cons = ""
        self.createdDate = Date()
        self.id = UUID()
        self.pros = ""
        self.relatedIdeas = []
        self.summary = ""
        self.title = ""
    }
}