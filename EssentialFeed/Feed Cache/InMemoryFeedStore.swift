import Foundation

public class InMemoryFeedStore: FeedStore {
    private let currentDate: () -> Date
    var cache = [LocalFeedImage]()

    public init(currentDate: @escaping () -> Date = Date.init) {
        self.currentDate = currentDate
    }

    public func retrieve(completion: @escaping FeedStore.RetrieveCompletion) {
        if cache.isEmpty {
            completion(.empty)
        } else {
            completion(.found(feed: cache, timestamp: currentDate()))
        }
    }

    public func persist(images: [LocalFeedImage], timestamp: Date, completion: @escaping FeedStore.PersistCompletion) {
        cache = images
        completion(nil)
    }

    public func delete(completion: @escaping FeedStore.DeletionCompletion) {
        cache = []
        completion(nil)
    }
}
