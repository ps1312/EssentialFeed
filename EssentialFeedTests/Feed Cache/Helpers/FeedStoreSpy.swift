import Foundation
import EssentialFeed

class FeedStoreSpy: FeedStore {
    private var deleteRequests = [DeletionCompletion]()
    private var persistRequests = [PersistCompletion]()
    private var retrieveRequests = [RetrieveCompletion]()
    private var deleteResult: Error?
    private var persistResult: Error?
    private var retrieveResult: CacheRetrieveResult = .empty

    enum Message: Equatable {
        case delete
        case persist(images: [LocalFeedImage], timestamp: Date)
        case retrieve
    }

    var messages = [Message]()

    func delete() throws {
        messages.append(.delete)
        if let error = deleteResult {
            throw error
        }
    }

    func persist(images: [EssentialFeed.LocalFeedImage], timestamp: Date) throws {
        messages.append(.persist(images: images, timestamp: timestamp))
        if let error = persistResult {
            throw error
        }
    }

    func retrieve() throws -> EssentialFeed.CacheRetrieveResult {
        messages.append(.retrieve)
        return retrieveResult
    }

    func completeDelete(with error: Error, at index: Int = 0) {
        deleteResult = error
    }

    func completeDeletionWithSuccess(at index: Int = 0) {
        deleteResult = nil
    }

    func completePersist(with error: Error, at index: Int = 0) {
        persistResult = error
    }

    func completePersistWithSuccess(at index: Int = 0) {
        persistResult = nil
    }

    func completeRetrieve(with error: Error, at index: Int = 0) {
        retrieveResult = .failure(error)
    }

    func completeRetrieveWithEmptyCache(at index: Int = 0) {
        retrieveResult = .empty
    }

    func completeRetrieve(with feed: [LocalFeedImage], timestamp: Date, at index: Int = 0) {
        retrieveResult = .found(feed: feed, timestamp: timestamp)
    }

}
