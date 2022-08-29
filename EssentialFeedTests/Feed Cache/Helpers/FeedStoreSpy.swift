import Foundation
import EssentialFeed

class FeedStoreSpy: FeedStore {
    private var deleteRequests = [(Error?) -> Void]()
    private var persistRequests = [(Error?) -> Void]()

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

    func retrieve() {
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

}
