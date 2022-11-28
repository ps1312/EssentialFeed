import Foundation

public class InMemoryFeedStore {
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
}
