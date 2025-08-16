//
//  IdealyApp.swift
//  Idealy
//
//  Created by John Underwood on 10/8/2025.
//

import SwiftUI
internal import CoreData

@main
struct IdealyApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
