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

    func delete(completion: @escaping DeletionCompletion) {
        completion(deleteResult)
        messages.append(.delete)
    }

    func persist(images: [LocalFeedImage], timestamp: Date, completion: @escaping PersistCompletion) {
        completion(persistResult)
        messages.append(.persist(images: images, timestamp: timestamp))
    }

    func retrieve(completion: @escaping RetrieveCompletion) {
        completion(retrieveResult)
        messages.append(.retrieve)
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
