import XCTest
import EssentialFeed

class ValidateCacheUseCaseTests: XCTestCase {

    func test_init_doesNotMessageFeedStore() {
        let (_, store) = makeSUT()

        XCTAssertTrue(store.messages.isEmpty)
    }

    func test_validateCache_requestsDeletionWhenRetrievalFails() {
        let (sut, store) = makeSUT()

        store.completeRetrieve(with: makeNSError())
        sut.validateCache { _ in }

        XCTAssertEqual(store.messages, [.retrieve, .delete])
    }

    func test_validateCache_requestsDeletionWhenExpired() {
        let currentDate = Date()
        let expiredTimestamp = currentDate.minusFeedCacheMaxAge().adding(seconds: -1)
        let (sut, store) = makeSUT(currentDate: { currentDate })

        store.completeRetrieve(with: uniqueImages().locals, timestamp: expiredTimestamp)
        sut.validateCache { _ in }

        XCTAssertEqual(store.messages, [.retrieve, .delete])
    }

    func test_validateCache_requestsDeletionWhenCacheIsOnExpirationDate() {
        let currentDate = Date()
        let expirationTimestamp = currentDate.minusFeedCacheMaxAge()
        let (sut, store) = makeSUT(currentDate: { currentDate })

        store.completeRetrieve(with: uniqueImages().locals, timestamp: expirationTimestamp)
        sut.validateCache { _ in }

        XCTAssertEqual(store.messages, [.retrieve, .delete])
    }

    func test_validateCache_doesNotRequestDeletionWhenCacheIsNotExpired() {
        let currentDate = Date()
        let notExpiredTimestamp = currentDate.minusFeedCacheMaxAge().adding(seconds: 1)
        let (sut, store) = makeSUT(currentDate: { currentDate })

        sut.validateCache { _ in }
        store.completeRetrieve(with: uniqueImages().locals, timestamp: notExpiredTimestamp)

        XCTAssertEqual(store.messages, [.retrieve])
    }

    func test_validateCache_doesNotRequestDeletionWhenCacheIsEmpty() {
        let (sut, store) = makeSUT()

        sut.validateCache { _ in }
        store.completeRetrieveWithEmptyCache()

        XCTAssertEqual(store.messages, [.retrieve])
    }

    func test_validateCache_doesNotRequestDeletionAfterSUTHasBeenDeallocated() {
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

        validate(sut, toCompleteWith: .failure(error), when: {
            store.completeRetrieve(with: error)
            store.completeDelete(with: error)
        })
    }

    func test_validateCache_deliversErrorOnDeletionFailureAndExpiredCache() {
        let error = makeNSError()
        let expiredTimestamp = Date().minusFeedCacheMaxAge().adding(seconds: -1)
        let (sut, store) = makeSUT()

        validate(sut, toCompleteWith: .failure(error), when: {
            store.completeRetrieve(with: uniqueImages().locals, timestamp: expiredTimestamp)
            store.completeDelete(with: error)
        })
    }

    func test_validateCache_deliversSuccessWhenValidatingEmptyCache() {
        let (sut, store) = makeSUT()

        validate(sut, toCompleteWith: .success(()), when: {
            store.completeRetrieveWithEmptyCache()
        })
    }

    func test_validateCache_deliversSuccessWhenValidatingNonExpiredNonEmptyCache() {
        let (sut, store) = makeSUT()

        validate(sut, toCompleteWith: .success(()), when: {
            store.completeRetrieve(with: uniqueImages().locals, timestamp: Date())
        })
    }

    // MARK: - Helpers

    private func validate(_ sut: LocalFeedLoader, toCompleteWith expectedResult: LocalFeedLoader.ValidateCacheResult, when action: () -> Void, file: StaticString = #filePath, line: UInt = #line) {

        sut.validateCache { receivedResult in
            switch (receivedResult, expectedResult) {
            case (.success, .success):
                break

            case let (.failure(receivedFailure), .failure(expectedFailure)):
                XCTAssertEqual(receivedFailure as NSError, expectedFailure as NSError, file: file, line: line)

            default:
                XCTFail("Expected \(expectedResult), instead got \(receivedResult)", file: file, line: line)
            }
        }

        action()

    }

    private func makeSUT(currentDate: @escaping () -> Date = Date.init, file: StaticString = #filePath, line: UInt = #line) -> (LocalFeedLoader, FeedStoreSpy) {
        let feedStore = FeedStoreSpy()
        let sut = LocalFeedLoader(store: feedStore, currentDate: currentDate)

        testMemoryLeak(sut, file: file, line: line)
        testMemoryLeak(feedStore, file: file, line: line)

        return (sut, feedStore)
    }
}
