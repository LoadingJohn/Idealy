//
//  EditBoxView.swift
//  Idealy
//
//  Created by Claude Code on 10/8/2025.
//

import SwiftUI

struct EditBoxView: View {
    var body: some View {
        VStack {
            Text("Edit Box")
                .font(.largeTitle)
                .padding()
            
            Text("Editing interface for a Box")
                .foregroundColor(.secondary)
                .padding()
            
            Spacer()
        }
        .navigationTitle("Edit Box")
    }
}

#Preview {
    NavigationView {
        EditBoxView()
    }
}