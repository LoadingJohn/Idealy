//
//  IdeaBoxView.swift
//  Idealy
//
//  Created by Claude Code on 10/8/2025.
//

import SwiftUI

struct IdeaBoxView: View {
    var body: some View {
        VStack {
            Text("Idea Box View")
                .font(.largeTitle)
                .padding()
            
            Text("Displays details of a Box and its Ideas")
                .foregroundColor(.secondary)
                .padding()
            
            Spacer()
        }
        .navigationTitle("Box Details")
    }
}

#Preview {
    NavigationView {
        IdeaBoxView()
    }
}