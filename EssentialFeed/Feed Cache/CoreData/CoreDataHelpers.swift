import CoreData

extension NSPersistentContainer {
    struct CoreDataSetupFailure: Error {}

    static func create(modelName: String, storeURL: URL) throws -> NSPersistentContainer {
        let bundle = Bundle(for: CoreDataFeedStore.self)

        guard let modelURL = bundle.url(forResource: modelName  , withExtension: "momd") else {
            fatalError("Failed to find data model")
        }

        guard let mom = NSManagedObjectModel(contentsOf: modelURL) else {
            fatalError("Failed to create model from file: \(modelURL)")
        }

        let container = NSPersistentContainer(name: modelName, managedObjectModel: mom)

        let description = NSPersistentStoreDescription(url: storeURL)
        container.persistentStoreDescriptions = [description]

        var error: Error?
        container.loadPersistentStores { error = $1 }
        try error.map { throw $0 }

        return container
    }
}
