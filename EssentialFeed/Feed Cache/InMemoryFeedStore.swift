import Foundation

public class InMemoryFeedStore: FeedStore & FeedImageStore {
    private let currentDate: () -> Date

    var cache = [LocalFeedImage]()
    var images = [URL: Data]()

    public init(currentDate: @escaping () -> Date = Date.init) {
        self.currentDate = currentDate
    }

    public func retrieve(completion: @escaping FeedStore.RetrieveCompletion) {}
    public func persist(images: [LocalFeedImage], timestamp: Date, completion: @escaping FeedStore.PersistCompletion) {}
    public func delete(completion: @escaping DeletionCompletion) {}

    public func retrieve() throws -> CacheRetrieveResult {
        if cache.isEmpty {
            return .empty
        } else {
            return .found(feed: cache, timestamp: currentDate())
        }
    }

    public func persist(images: [LocalFeedImage], timestamp: Date) throws {
        cache = images
    }

    public func delete() throws {
        cache = []
    }
}

extension InMemoryFeedStore {
    public func retrieve(from url: URL, completion: @escaping FeedImageStore.RetrievalCompletion) {
        if let image = images[url] {
            completion(.found(image))
        } else {
            completion(.empty)
        }
    }

    public func insert(url: URL, with data: Data, completion: @escaping FeedImageStore.InsertCompletion) {
        images[url] = data
        completion(nil)
    }

}
