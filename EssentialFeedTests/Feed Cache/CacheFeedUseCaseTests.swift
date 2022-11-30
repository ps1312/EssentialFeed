import XCTest
import EssentialFeed

class CacheFeedUseCaseTests: XCTestCase {
    func test_init_doesNotRequestCacheDeletion() {
        let (_, feedStore) = makeSUT()

        XCTAssertEqual(feedStore.messages, [])
    }

    func test_save_deliversErrorOnDeletionFailure() {
        let expectedError = makeNSError()
        let (sut, feedStore) = makeSUT()

        expect(sut, toCompleteWithError: expectedError, when: {
            feedStore.completeDelete(with: expectedError)
        })
    }

    func test_save_requestsCachePersistenceWithProvidedFeedImagesAndTimestamp() throws {
        let expectedTimestamp = Date()
        let (models, locals) = uniqueImages()
        let (sut, feedStore) = makeSUT(currentDate: { expectedTimestamp })

        feedStore.completeDeletionWithSuccess()
        feedStore.completePersistWithSuccess()
        try sut.save(feed: models)

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

    // MARK: - Helpers

    private func makeSUT(currentDate: @escaping () -> Date = Date.init, file: StaticString = #filePath, line: UInt = #line) -> (LocalFeedLoader, FeedStoreSpy) {
        let feedStore = FeedStoreSpy()
        let sut = LocalFeedLoader(store: feedStore, currentDate: currentDate)

        testMemoryLeak(sut, file: file, line: line)
        testMemoryLeak(feedStore, file: file, line: line)

        return (sut, feedStore)
    }

    private func expect(_ sut: LocalFeedLoader, toCompleteWithError expectedError: NSError?, when action: () -> Void, file: StaticString = #filePath, line: UInt = #line) {
        action()

        var capturedError: Error? = nil
        do {
            try sut.save(feed: uniqueImages().models)
        } catch {
            capturedError = error
        }

        XCTAssertEqual(capturedError as? NSError, expectedError, file: file, line: line)
    }

}
