import Foundation
import CoreData

public class CoreDataFeedStore: FeedStore {
    private static let modelName: String = "FeedStore"
    private static let model = NSManagedObjectModel.with(name: modelName, in: Bundle(for: CoreDataFeedStore.self))

    private let container: NSPersistentContainer
    private let context: NSManagedObjectContext

    enum StoreError: Error {
            case modelNotFound
            case failedToLoadPersistentContainer(Error)
        }

    public init(storeURL: URL) throws {
        guard let model = CoreDataFeedStore.model else {
            throw StoreError.modelNotFound
        }

        do {
            container = try NSPersistentContainer.create(modelName: CoreDataFeedStore.modelName, model: model, storeURL: storeURL)
            context = container.newBackgroundContext()
        } catch {
            throw StoreError.failedToLoadPersistentContainer(error)
        }
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
    public func insert(url: URL, with data: Data, completion: @escaping InsertCompletion) {
        context.perform { [weak context] in
            do {
                let model = try ManagedFeedImage.findBy(url: url)
                model?.data = data

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
                guard let model = try ManagedFeedImage.findBy(url: url), let imageData = model.data else {
                    return completion(.empty)
                }

                completion(.found(imageData))
            } catch {
                completion(.failure(error))
            }
        }
    }
}
