import XCTest
import EssentialFeed

class CacheFeedUseCaseTests: XCTestCase {
    func test_init_doesNotRequestCacheDeletion() {
        let (_, feedStore) = makeSUT()

        XCTAssertEqual(feedStore.messages, [])
    }

    func test_save_requestsCurrentCacheDeletion() {
        let (sut, feedStore) = makeSUT()

        sut.save(feed: uniqueImages().models) { _ in }

        XCTAssertEqual(feedStore.messages, [.delete])
    }

    func test_save_deliversErrorOnDeletionFailure() {
        let expectedError = makeNSError()
        let (sut, feedStore) = makeSUT()

        expect(sut, toCompleteWithError: expectedError, when: {
            feedStore.completeDelete(with: expectedError)
        })
    }

    func test_save_requestsCachePersistenceWithProvidedFeedImagesAndTimestamp() {
        let expectedTimestamp = Date()
        let (models, locals) = uniqueImages()
        let (sut, feedStore) = makeSUT(currentDate: { expectedTimestamp })

        sut.save(feed: models) { _ in }
        feedStore.completeDeletionWithSuccess()

        XCTAssertEqual(feedStore.messages, [.delete, .persist(images: locals, timestamp: expectedTimestamp)])
    }

    func test_save_deliversErrorOnCachePersistenceFailure() {
        let expectedError = makeNSError()
        let (sut, feedStore) = makeSUT()

        expect(sut, toCompleteWithError: expectedError, when: {
            feedStore.completeDeletionWithSuccess()
            feedStore.completePersist(with: expectedError)
        })
    }

    func test_save_doesNotDeliverErrorWhenNewCachePersistenceSucceeds() {
        let (sut, feedStore) = makeSUT()

        expect(sut, toCompleteWithError: nil, when: {
            feedStore.completeDeletionWithSuccess()
            feedStore.completePersistWithSuccess()
        })
    }

    func test_save_doesNotCompleteDeletionWhenSUTHasBeenDeallocated() {
        let store = FeedStoreSpy()
        var sut: LocalFeedLoader? = LocalFeedLoader(store: store)

        var capturedError: Error? = nil
        sut?.save(feed: uniqueImages().models) { capturedError = $0 }

        sut = nil
        store.completeDelete(with: makeNSError())

        XCTAssertNil(capturedError)
    }

    func test_save_doesNotCompletePersistenceWhenSUTHasBeenDeallocated() {
        let store = FeedStoreSpy()
        var sut: LocalFeedLoader? = LocalFeedLoader(store: store)

        var capturedError: Error? = nil
        sut?.save(feed: uniqueImages().models) { capturedError = $0 }
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
        sut.save(feed: uniqueImages().models) { error in
            capturedError = error
            exp.fulfill()
        }

        action()

        wait(for: [exp], timeout: 1.0)

        XCTAssertEqual(capturedError as? NSError, expectedError)
    }

}
