
import XCTest
import EssentialFeed

class LoadFeedFromCacheUseCaseTests: XCTestCase {

    func test_init_doesNotRequestCacheDeletion() {
        let (_, storeSpy) = makeSUT()

        XCTAssertEqual(storeSpy.messages, [])
    }

    func test_load_requestsCacheRetrieval() throws {
        let (sut, storeSpy) = makeSUT()

        _ = try sut.load()

        XCTAssertEqual(storeSpy.messages, [.retrieve])
    }

    func test_load_deliversErrorOnRetrievalFailure() {
        let (sut, storeSpy) = makeSUT()

        storeSpy.completeRetrieve(with: makeNSError())

        XCTAssertThrowsError(try sut.load())
    }

    func test_load_deliversEmptyListWhenCacheIsEmpty() {
        let (sut, storeSpy) = makeSUT()

        storeSpy.completeRetrieveWithEmptyCache()

        XCTAssertEqual([], try sut.load())
    }

    func test_load_deliversFeedImagesWhenCacheIsNotExpired() {
        let currentDate = Date()
        let notExpiredTimestamp = currentDate.minusFeedCacheMaxAge().adding(seconds: 1)
        let expectedFeed = uniqueImages()
        let (sut, storeSpy) = makeSUT()

        storeSpy.completeRetrieve(with: expectedFeed.locals, timestamp: notExpiredTimestamp)

        XCTAssertEqual(expectedFeed.models, try sut.load())
    }

    func test_load_deliversEmptyListWhenCacheIsExpired() {
        let currentDate = Date()
        let expiredTimestamp = currentDate.minusFeedCacheMaxAge().adding(seconds: -1)
        let (sut, storeSpy) = makeSUT(currentDate: { currentDate })

        storeSpy.completeRetrieve(with: uniqueImages().locals, timestamp: expiredTimestamp)

        XCTAssertEqual([], try sut.load())
    }

    func test_load_deliversEmptyFeedImagesArrayWhenCacheIsOnExpirationDate() {
        let currentDate = Date()
        let expirationTimestamp = currentDate.minusFeedCacheMaxAge()
        let (sut, storeSpy) = makeSUT(currentDate: { currentDate })

        storeSpy.completeRetrieve(with: uniqueImages().locals, timestamp: expirationTimestamp)

        XCTAssertEqual([], try sut.load())
    }

    func test_load_hasNoSideEffectsWhenRetrieveFails() throws {
        let (sut, storeSpy) = makeSUT()

        storeSpy.completeRetrieve(with: makeNSError())
        do {
            _ = try sut.load()
        } catch {}

        XCTAssertEqual(storeSpy.messages, [.retrieve])
    }

    func test_load_hasNoSideEffectsWhenCacheIsExpired() throws {
        let currentDate = Date()
        let expiredTimestamp = currentDate.minusFeedCacheMaxAge().adding(seconds: -1)
        let (sut, storeSpy) = makeSUT(currentDate: { currentDate })

        storeSpy.completeRetrieve(with: uniqueImages().locals, timestamp: expiredTimestamp)
        _ = try sut.load()

        XCTAssertEqual(storeSpy.messages, [.retrieve])
    }

    func test_load_hasNoSideEffectsWhenCacheIsOnExpirationDate() throws {
        let currentDate = Date()
        let expirationTimestamp = currentDate.minusFeedCacheMaxAge()
        let (sut, storeSpy) = makeSUT(currentDate: { currentDate })

        storeSpy.completeRetrieve(with: uniqueImages().locals, timestamp: expirationTimestamp)
        _ = try sut.load()

        XCTAssertEqual(storeSpy.messages, [.retrieve])
    }

    func test_load_doesNotDeleteCacheWhenNotExpired() throws {
        let currentDate = Date()
        let notExpiredTimestamp = currentDate.minusFeedCacheMaxAge().adding(seconds: 1)
        let (sut, storeSpy) = makeSUT(currentDate: { currentDate })

        storeSpy.completeRetrieve(with: uniqueImages().locals, timestamp: notExpiredTimestamp)
        _ = try sut.load()

        XCTAssertEqual(storeSpy.messages, [.retrieve])

    }

    func test_load_doesNotDeleteCacheWhenAlreadyEmpty() throws {
        let (sut, storeSpy) = makeSUT()

        storeSpy.completeRetrieveWithEmptyCache()
        _ = try sut.load()

        XCTAssertEqual(storeSpy.messages, [.retrieve])
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
