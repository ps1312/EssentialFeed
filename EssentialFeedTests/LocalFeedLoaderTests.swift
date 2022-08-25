import XCTest
import EssentialFeed

protocol FeedStore {
    typealias DeletionCompletion = (Error?) -> Void
    typealias PersistCompletion = (Error?) -> Void

    func delete(completion: @escaping DeletionCompletion)
    func persist(items: [FeedItem], timestamp: Date, completion: @escaping PersistCompletion)
}

class FeedStoreSpy: FeedStore {
    var deleteRequests = [(Error?) -> Void]()
    var persistRequests = [(Error?) -> Void]()

    enum Message: Equatable {
        case delete
        case persist(items: [FeedItem], timestamp: Date)
    }

    var messages = [Message]()

    func delete(completion: @escaping DeletionCompletion) {
        deleteRequests.append(completion)
        messages.append(.delete)
    }

    func persist(items: [FeedItem], timestamp: Date, completion: @escaping PersistCompletion) {
        persistRequests.append(completion)
        messages.append(.persist(items: items, timestamp: timestamp))
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


class LocalFeedLoader {
    private let store: FeedStore
    private let currentDate: () -> Date

    init(store: FeedStore, currentDate: @escaping () -> Date = Date.init) {
        self.store = store
        self.currentDate = currentDate
    }

    func save(feed: [FeedItem], completion: @escaping (Error?) -> Void) {
        store.delete { [weak self] error in
            guard let self = self else { return }

            if let error = error {
                completion(error)
            } else {
                self.store.persist(items: feed, timestamp: self.currentDate()) { [weak self] persistError in
                    guard self != nil else { return }

                    completion(persistError)
                }
            }
        }
    }

}

class LocalFeedLoaderTests: XCTestCase {

    func testInitDoesNotRequestCacheDeletion() {
        let (_, feedStore) = makeSUT()

        XCTAssertEqual(feedStore.messages, [])
    }

    func testSaveRequestsCurrentCacheDeletion() {
        let (sut, feedStore) = makeSUT()

        sut.save(feed: [uniqueItem()]) { _ in }

        XCTAssertEqual(feedStore.messages, [.delete])
    }

    func testSaveDeliversErrorOnDeletionFailure() {
        let expectedError = makeNSError()
        let (sut, feedStore) = makeSUT()

        expect(sut, toCompleteWithError: expectedError, when: {
            feedStore.completeDelete(with: expectedError)
        })
    }

    func testSaveRequestsCachePersistenceWithProvidedFeedItemsAndTimestamp() {
        let expectedTimestamp = Date()
        let expectedFeedItems = [uniqueItem(), uniqueItem()]
        let (sut, feedStore) = makeSUT(currentDate: { expectedTimestamp })

        sut.save(feed: expectedFeedItems) { _ in }
        feedStore.completeDeletionWithSuccess()

        XCTAssertEqual(feedStore.messages, [.delete, .persist(items: expectedFeedItems, timestamp: expectedTimestamp)])
    }

    func testSaveDeliversErrorOnCachePersistenceFailure() {
        let expectedError = makeNSError()
        let (sut, feedStore) = makeSUT()

        expect(sut, toCompleteWithError: expectedError, when: {
            feedStore.completeDeletionWithSuccess()
            feedStore.completePersist(with: expectedError)
        })
    }

    func testSaveDoesNotDeliverErrorWhenNewCachePersistenceSucceeds() {
        let (sut, feedStore) = makeSUT()

        expect(sut, toCompleteWithError: nil, when: {
            feedStore.completeDeletionWithSuccess()
            feedStore.completePersistWithSuccess()
        })
    }

    func testSaveDoesNotCompleteDeletionWhenSUTHasBeenDeallocated() {
        let store = FeedStoreSpy()
        var sut: LocalFeedLoader? = LocalFeedLoader(store: store)

        var capturedError: Error? = nil
        sut?.save(feed: [uniqueItem()]) { capturedError = $0 }

        sut = nil
        store.completeDelete(with: makeNSError())

        XCTAssertNil(capturedError)
    }

    func testSaveDoesNotCompletePersistenceWhenSUTHasBeenDeallocated() {
        let store = FeedStoreSpy()
        var sut: LocalFeedLoader? = LocalFeedLoader(store: store)

        var capturedError: Error? = nil
        sut?.save(feed: [uniqueItem()]) { capturedError = $0 }
        store.completeDeletionWithSuccess()

        sut = nil
        store.completePersist(with: makeNSError())

        XCTAssertNil(capturedError)
    }

    // MARK: - Helpers

    private func makeSUT(currentDate: @escaping () -> Date = Date.init, file: StaticString = #filePath, line: UInt = #line) -> (LocalFeedLoader, FeedStoreSpy) {
        let feedStore = FeedStoreSpy()
        let sut = LocalFeedLoader(store: feedStore, currentDate: currentDate)

        testMemoryLeak(sut, file: file, line: line)
        testMemoryLeak(feedStore, file: file, line: line)

        return (sut, feedStore)
    }

    private func expect(_ sut: LocalFeedLoader, toCompleteWithError expectedError: NSError?, when action: () -> Void) {
        let exp = expectation(description: "waiting for cache saving completion")

        var capturedError: Error? = nil
        sut.save(feed: [uniqueItem()]) { error in
            capturedError = error
            exp.fulfill()
        }

        action()

        wait(for: [exp], timeout: 0.1)

        XCTAssertEqual(capturedError as? NSError, expectedError)

    }

    private func uniqueItem() -> FeedItem {
        return FeedItem(id: UUID(), description: "description", location: "location", imageURL: makeURL())
    }

}
