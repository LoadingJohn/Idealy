//
//  AIModelType.swift
//  Idealy
//
//  Created by Claude Code on 17/8/2025.
//

import Foundation

enum AIModelType: String, CaseIterable {
    case appleIntelligence = "Apple Intelligence"
    case qwen = "Qwen2.5-1.5B"
    
    var displayName: String {
        return self.rawValue
    }
    
    static func from(string: String) -> AIModelType {
        return AIModelType(rawValue: string) ?? .qwen
    }
}