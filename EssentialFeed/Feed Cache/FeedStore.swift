import Foundation

public enum CacheRetrieveResult {
    case empty
    case success(feed: [LocalFeedImage], timestamp: Date)
    case failure(Error)
}

public protocol FeedStore {
    typealias DeletionCompletion = (Error?) -> Void
    typealias PersistCompletion = (Error?) -> Void
    typealias RetrieveCompletion = (CacheRetrieveResult) -> Void

    func delete(completion: @escaping DeletionCompletion)
    func persist(images: [LocalFeedImage], timestamp: Date, completion: @escaping PersistCompletion)
    func retrieve(completion: @escaping RetrieveCompletion)
}
