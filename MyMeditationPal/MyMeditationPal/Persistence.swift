//
//  Persistence.swift
//  MyMeditationPal
//
//  Created by Aaron Van Doren on 1/18/26.
//

import CoreData

struct PersistenceController {
    static let shared = PersistenceController()

    @MainActor
    static let preview: PersistenceController = {
        let result = PersistenceController(inMemory: true)
        let viewContext = result.container.viewContext
        
        // Create sample data for preview
        let calendar = Calendar.current
        for dayOffset in 0..<7 {
            let completion = DailyCompletion(context: viewContext)
            completion.date = calendar.startOfDay(for: calendar.date(byAdding: .day, value: -dayOffset, to: Date())!)
            completion.meditationCompleted = dayOffset % 2 == 0
            completion.coherentBreathingCompleted = dayOffset % 3 == 0
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
        container = NSPersistentContainer(name: "MyMeditationPal")
        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        }
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        container.viewContext.automaticallyMergesChangesFromParent = true
    }
}
