//
//  Box.swift
//  Idealy
//
//  Created by Claude Code on 10/8/2025.
//

import Foundation

struct BoxModel {
    let channels: String
    let costs: String
    let createdDate: Date
    let customerSegments: String
    let earlyAdopters: String
    let existingAlternatives: String
    let highLevelConcept: String
    let id: UUID
    let keyMetrics: String
    let modifiedDate: Date
    let name: String
    let problem: String
    let revenueStreams: String
    let solution: String
    let summary: String
    let unfairAdvantage: String
    let uniqueValueProposition: String
    
    init() {
        self.channels = ""
        self.costs = ""
        self.createdDate = Date()
        self.customerSegments = ""
        self.earlyAdopters = ""
        self.existingAlternatives = ""
        self.highLevelConcept = ""
        self.id = UUID()
        self.keyMetrics = ""
        self.modifiedDate = Date()
        self.name = ""
        self.problem = ""
        self.revenueStreams = ""
        self.solution = ""
        self.summary = ""
        self.unfairAdvantage = ""
        self.uniqueValueProposition = ""
    }
}