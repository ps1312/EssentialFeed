import XCTest
import EssentialFeed

class ValidateCacheUseCaseTests: XCTestCase {

    func test_init_doesNotMessageFeedStore() {
        let (_, store) = makeSUT()

        XCTAssertTrue(store.messages.isEmpty)
    }

    func test_validateCache_requestsDeletionWhenRetrievalFails() throws {
        let (sut, store) = makeSUT()

        store.completeRetrieve(with: makeNSError())
        try sut.validateCache()

        XCTAssertEqual(store.messages, [.retrieve, .delete])
    }

    func test_validateCache_requestsDeletionWhenExpired() throws {
        let currentDate = Date()
        let expiredTimestamp = currentDate.minusFeedCacheMaxAge().adding(seconds: -1)
        let (sut, store) = makeSUT(currentDate: { currentDate })

        store.completeRetrieve(with: uniqueImages().locals, timestamp: expiredTimestamp)
        try sut.validateCache()

        XCTAssertEqual(store.messages, [.retrieve, .delete])
    }

    func test_validateCache_requestsDeletionWhenCacheIsOnExpirationDate() throws {
        let currentDate = Date()
        let expirationTimestamp = currentDate.minusFeedCacheMaxAge()
        let (sut, store) = makeSUT(currentDate: { currentDate })

        store.completeRetrieve(with: uniqueImages().locals, timestamp: expirationTimestamp)
        try sut.validateCache()

        XCTAssertEqual(store.messages, [.retrieve, .delete])
    }

    func test_validateCache_doesNotRequestDeletionWhenCacheIsNotExpired() throws {
        let currentDate = Date()
        let notExpiredTimestamp = currentDate.minusFeedCacheMaxAge().adding(seconds: 1)
        let (sut, store) = makeSUT(currentDate: { currentDate })

        try sut.validateCache()
        store.completeRetrieve(with: uniqueImages().locals, timestamp: notExpiredTimestamp)

        XCTAssertEqual(store.messages, [.retrieve])
    }

    func test_validateCache_doesNotRequestDeletionWhenCacheIsEmpty() throws {
        let (sut, store) = makeSUT()

        try sut.validateCache()
        store.completeRetrieveWithEmptyCache()

        XCTAssertEqual(store.messages, [.retrieve])
    }

    func test_validateCache_deliversErrorOnDeletionFailureAfterRetrievalFailure() throws {
        let expectedError = makeNSError()
        let (sut, store) = makeSUT()

        store.completeRetrieve(with: expectedError)
        store.completeDelete(with: expectedError)

        do {
            try sut.validateCache()
        } catch {
            XCTAssertEqual(error as NSError, expectedError)
        }
    }

    func test_validateCache_deliversErrorOnDeletionFailureAndExpiredCache() {
        let expectedError = makeNSError()
        let expiredTimestamp = Date().minusFeedCacheMaxAge().adding(seconds: -1)
        let (sut, store) = makeSUT()

        store.completeRetrieve(with: uniqueImages().locals, timestamp: expiredTimestamp)
        store.completeDelete(with: expectedError)

        do {
            try sut.validateCache()
        } catch {
            XCTAssertEqual(error as NSError, expectedError)
        }
    }

    func test_validateCache_deliversSuccessWhenValidatingEmptyCache() throws {
        let (sut, store) = makeSUT()

        store.completeRetrieveWithEmptyCache()

        try sut.validateCache()
    }

    func test_validateCache_deliversSuccessWhenValidatingNonExpiredNonEmptyCache() throws {
        let (sut, store) = makeSUT()

        store.completeRetrieve(with: uniqueImages().locals, timestamp: Date())

        try sut.validateCache()
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
