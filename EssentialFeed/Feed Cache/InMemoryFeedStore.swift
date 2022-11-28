import Foundation

public class InMemoryFeedStore: FeedStore & FeedImageStore {
    private let currentDate: () -> Date

    var cache = [LocalFeedImage]()
    var images = [URL: Data]() {
        didSet {
            print("updated", images)
        }
    }

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
