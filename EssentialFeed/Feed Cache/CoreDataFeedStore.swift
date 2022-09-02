import Foundation
import CoreData

public class CoreDataFeedStore: FeedStore {

    private let container: NSPersistentContainer
    private let context: NSManagedObjectContext

    public init() {
        let bundle = Bundle(for: CoreDataFeedStore.self)

        guard let modelURL = bundle.url(forResource: "FeedStore", withExtension: "momd") else {
            fatalError("Failed to find data model")
        }

        guard let mom = NSManagedObjectModel(contentsOf: modelURL) else {
            fatalError("Failed to create model from file: \(modelURL)")
        }

        container = NSPersistentContainer(name: "FeedStore", managedObjectModel: mom)

        var loadStoresErrors = [Error]()
        container.loadPersistentStores { _, error in
            if let error = error {
                loadStoresErrors.append(error)
            }
        }

        if !loadStoresErrors.isEmpty {
            fatalError("Failed to load persistent stores")
        }

        context = container.newBackgroundContext()
    }

    public func delete(completion: @escaping DeletionCompletion) {
        fatalError("Not implemented yet!")
    }

    public func persist(images: [LocalFeedImage], timestamp: Date, completion: @escaping PersistCompletion) {
        fatalError("Not implemented yet!")
    }

    public func retrieve(completion: @escaping RetrieveCompletion) {
        completion(.empty)
    }

}
