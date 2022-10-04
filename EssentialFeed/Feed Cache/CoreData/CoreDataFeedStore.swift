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
                try context.save()

                completion(nil)
            } catch {
                context.rollback()
                completion(error)
            }
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
            } catch {
                context.rollback()
                completion(error)
            }
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

extension CoreDataFeedStore: FeedImageStore {
    public struct NotFound: Error, Equatable {
        public init() {}
    }
    
    public func insert(url: URL, with data: Data, completion: @escaping InsertCompletion) {
        context.perform { [weak context] in
            do {
                let request = NSFetchRequest<ManagedFeedImage>(entityName: "ManagedFeedImage")
                request.predicate = NSPredicate(format: "url == %@", url.absoluteString)
                let cachedFeedImage = try request.execute().first
                cachedFeedImage?.data = data

                try context?.save()
                completion(nil)
            } catch {
                completion(error)
            }
        }
    }

    public func retrieve(from url: URL, completion: @escaping RetrievalCompletion) {
        context.perform {
            do {
                let request = NSFetchRequest<ManagedFeedImage>(entityName: "ManagedFeedImage")
                let feedImage = try request.execute().first

                guard let imageData = feedImage?.data else {
                    return completion(.empty)
                }

                completion(.found(imageData))
            } catch {
                completion(.failure(error))
            }
        }
    }
}
