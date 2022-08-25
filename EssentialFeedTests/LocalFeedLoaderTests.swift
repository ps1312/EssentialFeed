import XCTest
import EssentialFeed

class FeedStore {
    var deleteRequests = [(Error?) -> Void]()

    enum Message: Equatable {
        case delete
        case persist([FeedItem])
    }

    var messages = [Message]()

    func deleteCache(completion: @escaping (Error?) -> Void) {
        deleteRequests.append(completion)
        messages.append(.delete)
    }

    func persistCache(_ items: [FeedItem]) {
        messages.append(.persist(items))
    }

    func completeDelete(with error: Error, at index: Int = 0) {
        deleteRequests[index](error)
    }

    func completeDeletionWithSuccess(at index: Int = 0) {
        deleteRequests[index](nil)
    }
}

class LocalFeedLoader {
    private let store: FeedStore

    init(store: FeedStore) {
        self.store = store
    }

    func save(feed: [FeedItem], completion: @escaping (Error?) -> Void) {
        store.deleteCache { [unowned self] error in
            completion(error)
            self.store.persistCache(feed)
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

        var capturedError: Error? = nil
        sut.save(feed: [uniqueItem()]) { capturedError = $0 }
        feedStore.completeDelete(with: expectedError)

        XCTAssertEqual(capturedError as? NSError, expectedError)
    }

    func testSaveRequestsCachePersistanceWithProvidedFeedItems() {
        let expectedFeedItems = [uniqueItem(), uniqueItem()]
        let (sut, feedStore) = makeSUT()

        sut.save(feed: expectedFeedItems) { _ in }
        feedStore.completeDeletionWithSuccess()

        XCTAssertEqual(feedStore.messages, [.delete, .persist(expectedFeedItems)])
    }

    // MARK: - Helpers

    private func makeSUT(file: StaticString = #filePath, line: UInt = #line) -> (LocalFeedLoader, FeedStore) {
        let feedStore = FeedStore()
        let sut = LocalFeedLoader(store: feedStore)

        testMemoryLeak(sut, file: file, line: line)
        testMemoryLeak(feedStore, file: file, line: line)

        return (sut, feedStore)
    }

    private func uniqueItem() -> FeedItem {
        return FeedItem(id: UUID(), description: "description", location: "location", imageURL: makeURL())
    }

}
