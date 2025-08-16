//
//  ColorPalette.swift
//  Idealy
//
//  Created by Claude Code on 10/8/2025.
//

import SwiftUI
import Combine

enum AppearanceMode: String, CaseIterable {
    case system = "System"
    case light = "Light"
    case dark = "Dark"
}

struct ColorPalette {
    let background: Color
    let surface: Color
    let primary: Color
    let secondary: Color
    let accent: Color
    let text: Color
    let textSecondary: Color
    let border: Color
    
    static let light = ColorPalette(
        background: Color.white,
        surface: Color(UIColor.systemBackground),
        primary: Color.blue,
        secondary: Color.gray,
        accent: Color.blue,
        text: Color.black,
        textSecondary: Color.gray,
        border: Color.gray.opacity(0.3)
    )
    
    static let dark = ColorPalette(
        background: Color(hex: "#101010"),
        surface: Color(hex: "#1A1A1A"),
        primary: Color.white,
        secondary: Color(hex: "#CCCCCC"),
        accent: Color.blue,
        text: Color.white,
        textSecondary: Color(hex: "#CCCCCC"),
        border: Color.black.opacity(0.3)
    )
}

class ThemeManager: ObservableObject {
    
    @Published var appearanceMode: AppearanceMode = .system {
        didSet {
            UserDefaults.standard.set(appearanceMode.rawValue, forKey: "appearanceMode")
        }
    }
    
    init() {
        if let savedMode = UserDefaults.standard.string(forKey: "appearanceMode"),
           let mode = AppearanceMode(rawValue: savedMode) {
            self.appearanceMode = mode
        }
    }
    
    func colorPalette(for colorScheme: ColorScheme?) -> ColorPalette {
        switch appearanceMode {
        case .light:
            return .light
        case .dark:
            return .dark
        case .system:
            return (colorScheme == .dark) ? .dark : .light
        }
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

struct ThemeEnvironmentKey: EnvironmentKey {
    static let defaultValue = ColorPalette.light
}

extension EnvironmentValues {
    var colorPalette: ColorPalette {
        get { self[ThemeEnvironmentKey.self] }
        set { self[ThemeEnvironmentKey.self] = newValue }
    }
}
