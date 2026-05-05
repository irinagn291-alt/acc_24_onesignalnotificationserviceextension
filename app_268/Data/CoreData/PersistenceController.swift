import CoreData
import Foundation

enum PersistenceController {
    static let shared = PersistenceController.make()

    static func preview() -> PersistenceControllerPayload {
        make(inMemory: true)
    }

    private static func make(inMemory: Bool = false) -> PersistenceControllerPayload {
        let model = FoodScanManagedObjectModel.make()
        let container = NSPersistentContainer(name: "FoodScan", managedObjectModel: model)
        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        }
        if let d = container.persistentStoreDescriptions.first {
            d.setOption(true as NSNumber, forKey: NSMigratePersistentStoresAutomaticallyOption)
            d.setOption(true as NSNumber, forKey: NSInferMappingModelAutomaticallyOption)
        }
        container.loadPersistentStores { _, error in
            if let error {
                fatalError("Core Data error: \(error.localizedDescription)")
            }
        }
        let viewContext = container.viewContext
        viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        viewContext.automaticallyMergesChangesFromParent = true

        NotificationCenter.default.addObserver(
            forName: .NSManagedObjectContextDidSave,
            object: nil,
            queue: .main
        ) { notification in
            guard let saved = notification.object as? NSManagedObjectContext,
                  saved !== viewContext,
                  saved.persistentStoreCoordinator === viewContext.persistentStoreCoordinator
            else { return }
            viewContext.mergeChanges(fromContextDidSave: notification)
        }

        return PersistenceControllerPayload(container: container)
    }
}

struct PersistenceControllerPayload {
    let container: NSPersistentContainer

    var viewContext: NSManagedObjectContext {
        container.viewContext
    }

    func newBackgroundContext() -> NSManagedObjectContext {
        container.newBackgroundContext()
    }
}
