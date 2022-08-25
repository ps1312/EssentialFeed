import XCTest
import EssentialFeed

class FeedStore {
    var deleteRequests = [(Error?) -> Void]()
    var deleteRequestsCount: Int { deleteRequests.count }

    var persistRequestsCount = 0

    func deleteCache(completion: @escaping (Error?) -> Void) {
        deleteRequests.append(completion)
    }

    func persistCache(_ items: [FeedItem]) {
        persistRequestsCount += 1
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

    func save(completion: @escaping (Error?) -> Void) {
        store.deleteCache { [unowned self] error in
            completion(error)
            self.store.persistCache([FeedItem]())
        }
    }

}

class LocalFeedLoaderTests: XCTestCase {

    func testInitDoesNotRequestCacheDeletion() {
        let (_, feedStore) = makeSUT()

        XCTAssertEqual(feedStore.deleteRequestsCount, 0)
    }

    func testSaveRequestsCurrentCacheDeletion() {
        let (sut, feedStore) = makeSUT()

        sut.save { _ in }

        XCTAssertEqual(feedStore.deleteRequestsCount, 1)
    }

    func testSaveDeliversErrorOnDeletionFailure() {
        let expectedError = makeNSError()
        let (sut, feedStore) = makeSUT()

        var capturedError: Error? = nil
        sut.save { capturedError = $0 }
        feedStore.completeDelete(with: expectedError)

        XCTAssertEqual(capturedError as? NSError, expectedError)
    }

    func testSaveRequestsCachePersistanceWithProvidedFeedItems() {
        let (sut, feedStore) = makeSUT()

        sut.save { _ in }
        feedStore.completeDeletionWithSuccess()

        XCTAssertEqual(feedStore.deleteRequestsCount, 1)
        XCTAssertEqual(feedStore.persistRequestsCount, 1)
    }

    // MARK: - Helpers

    private func makeSUT(file: StaticString = #filePath, line: UInt = #line) -> (LocalFeedLoader, FeedStore) {
        let feedStore = FeedStore()
        let sut = LocalFeedLoader(store: feedStore)

        testMemoryLeak(sut, file: file, line: line)
        testMemoryLeak(feedStore, file: file, line: line)

        return (sut, feedStore)
    }

}
