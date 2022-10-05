import XCTest
import EssentialFeed

class ValidateCacheUseCaseTests: XCTestCase {

    func testInitDoesNotMessageFeedStore() {
        let (_, store) = makeSUT()

        XCTAssertTrue(store.messages.isEmpty)
    }

    func testValidateCacheRequestsDeletionWhenRetrievalFails() {
        let (sut, store) = makeSUT()

        sut.validateCache { _ in }
        store.completeRetrieve(with: makeNSError())

        XCTAssertEqual(store.messages, [.retrieve, .delete])
    }

    func testValidateCacheRequestsDeletionWhenExpired() {
        let currentDate = Date()
        let expiredTimestamp = currentDate.minusFeedCacheMaxAge().adding(seconds: -1)
        let (sut, store) = makeSUT(currentDate: { currentDate })

        sut.validateCache { _ in }
        store.completeRetrieve(with: uniqueImages().locals, timestamp: expiredTimestamp)

        XCTAssertEqual(store.messages, [.retrieve, .delete])
    }

    func testValidateCacheRequestsDeletionWhenCacheIsOnExpirationDate() {
        let currentDate = Date()
        let expirationTimestamp = currentDate.minusFeedCacheMaxAge()
        let (sut, store) = makeSUT(currentDate: { currentDate })

        sut.validateCache { _ in }
        store.completeRetrieve(with: uniqueImages().locals, timestamp: expirationTimestamp)

        XCTAssertEqual(store.messages, [.retrieve, .delete])
    }

    func testValidateCacheDoesNotRequestDeletionWhenCacheIsNotExpired() {
        let currentDate = Date()
        let notExpiredTimestamp = currentDate.minusFeedCacheMaxAge().adding(seconds: 1)
        let (sut, store) = makeSUT(currentDate: { currentDate })

        sut.validateCache { _ in }
        store.completeRetrieve(with: uniqueImages().locals, timestamp: notExpiredTimestamp)

        XCTAssertEqual(store.messages, [.retrieve])
    }

    func testValidateCacheDoesNotRequestDeletionWhenCacheIsEmpty() {
        let (sut, store) = makeSUT()

        sut.validateCache { _ in }
        store.completeRetrieveWithEmptyCache()

        XCTAssertEqual(store.messages, [.retrieve])
    }

    func testValidateCacheDoesNotRequestDeletionAfterSUTHasBeenDeallocated() {
        let store = FeedStoreSpy()
        var sut: LocalFeedLoader? = LocalFeedLoader(store: store)

        sut?.validateCache { _ in }
        sut = nil
        store.completeRetrieve(with: makeNSError())

        XCTAssertEqual(store.messages, [.retrieve])
    }

    func test_validateCache_deliversErrorOnDeletionFailureAfterRetrievalFailure() {
        let error = makeNSError()
        let (sut, store) = makeSUT()

        var capturedError: Error?
        sut.validateCache { capturedError = $0 }
        store.completeRetrieve(with: error)
        store.completeDelete(with: error)

        XCTAssertEqual(capturedError as? NSError, error)
    }

    func test_validateCache_deliversErrorOnDeletionFailureAndExpiredCache() {
        let error = makeNSError()
        let expiredTimestamp = Date().minusFeedCacheMaxAge().adding(seconds: -1)
        let (sut, store) = makeSUT()

        var capturedError: Error?
        sut.validateCache { capturedError = $0 }
        store.completeRetrieve(with: uniqueImages().locals, timestamp: expiredTimestamp)
        store.completeDelete(with: error)

        XCTAssertEqual(capturedError as? NSError, error)
    }

    // MARK: - Helpers

    private func makeSUT(currentDate: @escaping () -> Date = Date.init, file: StaticString = #filePath, line: UInt = #line) -> (LocalFeedLoader, FeedStoreSpy) {
        let feedStore = FeedStoreSpy()
        let sut = LocalFeedLoader(store: feedStore, currentDate: currentDate)

        testMemoryLeak(sut, file: file, line: line)
        testMemoryLeak(feedStore, file: file, line: line)

        return (sut, feedStore)
    }
}
