//
//  Persistence.swift
//  Idealy
//
//  Created by John Underwood on 10/8/2025.
//

internal import CoreData

struct PersistenceController {
    static let shared = PersistenceController()

    @MainActor
    static let preview: PersistenceController = {
        let result = PersistenceController(inMemory: true)
        let viewContext = result.container.viewContext
        
        // Create sample boxes
        for i in 0..<3 {
            let newBox = Box(context: viewContext)
            newBox.id = UUID()
            newBox.name = "Sample Box \(i + 1)"
            newBox.createdDate = Date()
            newBox.modifiedDate = Date()
            newBox.problem = "Sample problem description"
            newBox.solution = "Sample solution description"
            newBox.summary = "Sample box summary"
            newBox.highLevelConcept = "Sample high-level concept"
            
            // Create sample ideas for each box
            for j in 0..<2 {
                let newIdea = Idea(context: viewContext)
                newIdea.id = UUID()
                newIdea.title = "Idea \(j + 1) for Box \(i + 1)"
                newIdea.createdDate = Date()
                newIdea.summary = "Sample idea summary"
                newIdea.classification = "Sample"
                newIdea.pros = "Sample pros"
                newIdea.cons = "Sample cons"
                newIdea.box = newBox
            }
        }
        
        do {
            try viewContext.save()
        } catch {
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
        return result
    }()

    let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "Idealy")
        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        }
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.

                /*
                 Typical reasons for an error here include:
                 * The parent directory does not exist, cannot be created, or disallows writing.
                 * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                 * The device is out of space.
                 * The store could not be migrated to the current model version.
                 Check the error message to determine what the actual problem was.
                 */
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        container.viewContext.automaticallyMergesChangesFromParent = true
    }
}
