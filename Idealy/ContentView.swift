//
//  ContentView.swift
//  Idealy
//
//  Created by John Underwood on 10/8/2025.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var themeManager = ThemeManager()
    @Environment(\.colorScheme) private var systemColorScheme
    
    var body: some View {
        NewView()
            .environment(\.colorPalette, themeManager.colorPalette(for: systemColorScheme))
            .environmentObject(themeManager)
            .preferredColorScheme(colorScheme)
    }
    
    private var colorScheme: ColorScheme? {
        switch themeManager.appearanceMode {
        case .light:
            return .light
        case .dark:
            return .dark
        case .system:
            return nil
        }
    }
}

#Preview {
    ContentView()
}
