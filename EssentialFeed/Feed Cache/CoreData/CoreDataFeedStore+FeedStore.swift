import Foundation

extension CoreDataFeedStore: FeedStore {
    public func delete() throws {
        try performSync { context in
            try ManagedCache.wipe(from: context)
            try context.save()
        }
    }

    public func persist(images: [LocalFeedImage], timestamp: Date) throws {
        try delete()

        try performSync { context in
            let managedCache = ManagedCache(context: context)
            managedCache.timestamp = timestamp
            managedCache.feed = ManagedFeedImage.build(with: images, in: context)

            try context.save()
        }
    }

    public func retrieve() throws -> CacheRetrieveResult {
        var capturedResult: CacheRetrieveResult!
        try performSync { context in
            do {
                if let cache = try ManagedCache.find(in: context) {
                    capturedResult = .found(feed: cache.locals, timestamp: cache.timestamp)
                } else {
                    capturedResult = .empty
                }
            } catch {
                capturedResult = .failure(error)
            }
        }

        return capturedResult
    }
}
