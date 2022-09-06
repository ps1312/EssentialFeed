import Foundation
import CoreData

public class CoreDataFeedStore: FeedStore {
    private let modelName: String = "FeedStore"
    private let container: NSPersistentContainer
    private let context: NSManagedObjectContext

    public init(storeURL: URL) throws {
        container = try NSPersistentContainer.create(modelName: modelName, storeURL: storeURL)
        context = container.newBackgroundContext()
    }

    public func delete(completion: @escaping DeletionCompletion) {
        context.perform { [context] in
            do {
                try ManagedCache.wipe(from: context)

                completion(nil)
            } catch {}
        }
    }

    public func persist(images: [LocalFeedImage], timestamp: Date, completion: @escaping PersistCompletion) {
        context.perform { [context] in
            do {
                try ManagedCache.wipe(from: context)

                let managedCache = ManagedCache(context: context)
                managedCache.timestamp = timestamp
                managedCache.feed = ManagedFeedImage.build(with: images, in: context)

                try context.save()

                completion(nil)
            } catch {}
        }

    }

    public func retrieve(completion: @escaping RetrieveCompletion) {
        context.perform { [context] in
            do {
                if let cache = try ManagedCache.find(in: context) {
                    completion(.found(feed: cache.locals, timestamp: cache.timestamp))
                } else {
                    completion(.empty)
                }
            } catch {
                completion(.failure(error))
            }
        }
    }

}
