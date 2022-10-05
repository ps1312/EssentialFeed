import Foundation

extension CoreDataFeedStore: FeedStore {
    public func delete(completion: @escaping DeletionCompletion) {
        perform { context in
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
        perform { context in
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
        perform { context in
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
