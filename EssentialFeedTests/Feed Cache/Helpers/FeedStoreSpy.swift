import Foundation
import EssentialFeed

class FeedStoreSpy: FeedStore {
    private var deleteRequests = [DeletionCompletion]()
    private var persistRequests = [PersistCompletion]()
    private var retrieveRequests = [RetrieveCompletion]()

    enum Message: Equatable {
        case delete
        case persist(images: [LocalFeedImage], timestamp: Date)
        case retrieve
    }

    var messages = [Message]()

    func delete(completion: @escaping DeletionCompletion) {
        deleteRequests.append(completion)
        messages.append(.delete)
    }

    func persist(images: [LocalFeedImage], timestamp: Date, completion: @escaping PersistCompletion) {
        persistRequests.append(completion)
        messages.append(.persist(images: images, timestamp: timestamp))
    }

    func retrieve(completion: @escaping RetrieveCompletion) {
        retrieveRequests.append(completion)
        messages.append(.retrieve)
    }

    func completeDelete(with error: Error, at index: Int = 0) {
        deleteRequests[index](error)
    }

    func completeDeletionWithSuccess(at index: Int = 0) {
        deleteRequests[index](nil)
    }

    func completePersist(with error: Error, at index: Int = 0) {
        persistRequests[index](error)
    }

    func completePersistWithSuccess(at index: Int = 0) {
        persistRequests[index](nil)
    }

    func completeRetrieve(with error: Error, at index: Int = 0) {
        retrieveRequests[index](.failure(error))
    }

    func completeRetrieveWithEmptyCache(at index: Int = 0) {
        retrieveRequests[index](.empty)
    }

    func completeRetrieve(with feed: [LocalFeedImage], at index: Int = 0) {
        retrieveRequests[index](.success(feed))
    }

}
