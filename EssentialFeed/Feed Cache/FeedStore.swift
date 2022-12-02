import Foundation

public enum CacheRetrieveResult {
    case empty
    case found(feed: [LocalFeedImage], timestamp: Date)
    case failure(Error)
}

public protocol FeedStore {
    typealias DeletionCompletion = (Error?) -> Void
    typealias PersistCompletion = (Error?) -> Void
    typealias RetrieveCompletion = (CacheRetrieveResult) -> Void

    func delete() throws
    func persist(images: [LocalFeedImage], timestamp: Date) throws
    func retrieve() throws -> CacheRetrieveResult
}
