//
//  EditIdeaView.swift
//  Idealy
//
//  Created by Claude Code on 10/8/2025.
//

import SwiftUI

struct EditIdeaView: View {
    var body: some View {
        VStack {
            Text("Edit Idea")
                .font(.largeTitle)
                .padding()
            
            Text("Editing interface for an Idea")
                .foregroundColor(.secondary)
                .padding()
            
            Spacer()
        }
        .navigationTitle("Edit Idea")
    }
}

#Preview {
    NavigationView {
        EditIdeaView()
    }
}