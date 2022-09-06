import Foundation
import CoreData

public class CoreDataFeedStore: FeedStore {

    private let container: NSPersistentContainer
    private let context: NSManagedObjectContext

    public init(storeURL: URL) throws {
        container = try NSPersistentContainer.create(storeURL: storeURL)
        context = container.newBackgroundContext()
    }

    public func delete(completion: @escaping DeletionCompletion) {
        context.perform { [context] in
            do {
                let request = NSFetchRequest<ManagedCache>(entityName: ManagedCache.entity().name!)
                request.returnsObjectsAsFaults = false
                let _ = try context.fetch(request).map(context.delete)

                completion(nil)
            } catch {}
        }
    }

    public func persist(images: [LocalFeedImage], timestamp: Date, completion: @escaping PersistCompletion) {
        context.perform { [context] in
            do {
                let request = NSFetchRequest<ManagedCache>(entityName: ManagedCache.entity().name!)
                request.returnsObjectsAsFaults = false
                let _ = try context.fetch(request).map(context.delete)

                let managedCache = ManagedCache(context: context)

                managedCache.timestamp = timestamp
                managedCache.feed = ManagedFeedImage.build(with: images, in: context)

                try context.save()

                completion(nil)
            } catch {}
        }

    }

    public func retrieve(completion: @escaping RetrieveCompletion) {
        let request = NSFetchRequest<ManagedCache>(entityName: ManagedCache.entity().name!)
        request.returnsObjectsAsFaults = false

        context.perform { [context] in
            do {
                if let cache = try context.fetch(request).first {
                    completion(.found(feed: cache.locals, timestamp: cache.timestamp))
                } else {
                    completion(.empty)
                }
            } catch {}
        }
    }

}

private extension NSPersistentContainer {
    struct CoreDataSetupFailure: Error {}

    static func create(storeURL: URL) throws -> NSPersistentContainer {
        let bundle = Bundle(for: CoreDataFeedStore.self)

        guard let modelURL = bundle.url(forResource: "FeedStore", withExtension: "momd") else {
            fatalError("Failed to find data model")
        }

        guard let mom = NSManagedObjectModel(contentsOf: modelURL) else {
            fatalError("Failed to create model from file: \(modelURL)")
        }

        let container = NSPersistentContainer(name: "FeedStore", managedObjectModel: mom)

        let description = NSPersistentStoreDescription(url: storeURL)
        container.persistentStoreDescriptions = [description]

        var error: Error?
        container.loadPersistentStores { error = $1 }
        try error.map { throw $0 }

        return container
    }
}
