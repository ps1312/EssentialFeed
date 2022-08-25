import XCTest
import EssentialFeed

class FeedStore {
    var deleteRequests = [(Error?) -> Void]()
    var persistRequests = [(Error?) -> Void]()

    enum Message: Equatable {
        case delete
        case persist([FeedItem])
    }

    var messages = [Message]()

    func deleteCache(completion: @escaping (Error?) -> Void) {
        deleteRequests.append(completion)
        messages.append(.delete)
    }

    func persistCache(_ items: [FeedItem], completion: @escaping (Error?) -> Void) {
        persistRequests.append(completion)
        messages.append(.persist(items))
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

    init(store: FeedStore) {
        self.store = store
    }

    func save(feed: [FeedItem], completion: @escaping (Error?) -> Void) {
        store.deleteCache { [unowned self] error in
            if let error = error {
                completion(error)
            } else {
                self.store.persistCache(feed, completion: completion)
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

    func testSaveRequestsCachePersistenceWithProvidedFeedItems() {
        let expectedFeedItems = [uniqueItem(), uniqueItem()]
        let (sut, feedStore) = makeSUT()

        sut.save(feed: expectedFeedItems) { _ in }
        feedStore.completeDeletionWithSuccess()

        XCTAssertEqual(feedStore.messages, [.delete, .persist(expectedFeedItems)])
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
        let exp = expectation(description: "wait for cache saving completion")
        let (sut, feedStore) = makeSUT()

        var capturedError: Error? = nil
        sut.save(feed: [uniqueItem()]) { receivedError in
            capturedError = receivedError
            exp.fulfill()
        }
        feedStore.completeDeletionWithSuccess()
        feedStore.completePersistWithSuccess()

        wait(for: [exp], timeout: 0.1)

        XCTAssertNil(capturedError)
    }

    // MARK: - Helpers

    private func makeSUT(file: StaticString = #filePath, line: UInt = #line) -> (LocalFeedLoader, FeedStore) {
        let feedStore = FeedStore()
        let sut = LocalFeedLoader(store: feedStore)

        testMemoryLeak(sut, file: file, line: line)
        testMemoryLeak(feedStore, file: file, line: line)

        return (sut, feedStore)
    }

    private func expect(_ sut: LocalFeedLoader, toCompleteWithError expectedError: NSError, when action: () -> Void) {
        let exp = expectation(description: "waiting for cache saving completion")
        let (sut, feedStore) = makeSUT()

        var capturedError: Error? = nil
        sut.save(feed: [uniqueItem()]) {
            capturedError = $0
            exp.fulfill()
        }
        feedStore.completeDeletionWithSuccess()
        feedStore.completePersist(with: expectedError)

        wait(for: [exp], timeout: 0.1)

        XCTAssertEqual(capturedError as? NSError, expectedError)

    }

    private func uniqueItem() -> FeedItem {
        return FeedItem(id: UUID(), description: "description", location: "location", imageURL: makeURL())
    }

}
