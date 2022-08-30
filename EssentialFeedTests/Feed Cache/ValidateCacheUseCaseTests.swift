import XCTest
import EssentialFeed

class ValidateCacheUseCaseTests: XCTestCase {

    func testInitDoesNotMessageFeedStore() {
        let (_, store) = makeSUT()

        XCTAssertTrue(store.messages.isEmpty)
    }

    func testValidateCacheRequestsDeletionWhenRetrievalFails() {
        let (sut, store) = makeSUT()

        sut.validateCache()
        store.completeRetrieve(with: makeNSError())

        XCTAssertEqual(store.messages, [.retrieve, .delete])
    }

    func testValidateCacheRequestsDeletionWhenOlderThanSevenDays() {
        let currentDate = Date()
        let olderThanSevenDaysTimestamp = currentDate.adding(days: -7).adding(seconds: -1)
        let (sut, store) = makeSUT(currentDate: { currentDate })

        sut.validateCache()
        store.completeRetrieve(with: uniqueImages().locals, timestamp: olderThanSevenDaysTimestamp)

        XCTAssertEqual(store.messages, [.retrieve, .delete])
    }

    func testValidateCacheRequestsDeletionWhenCacheIsSevenDaysOld() {
        let currentDate = Date()
        let sevenDaysTimestamp = currentDate.adding(days: -7)
        let (sut, store) = makeSUT(currentDate: { currentDate })

        sut.validateCache()
        store.completeRetrieve(with: uniqueImages().locals, timestamp: sevenDaysTimestamp)

        XCTAssertEqual(store.messages, [.retrieve, .delete])
    }

    func testValidateCacheDoesNotRequestDeletionWhenCacheIsLessThanSevenDaysOld() {
        let currentDate = Date()
        let lessThanSevenDaysTimestamp = currentDate.adding(days: -7).adding(seconds: 1)
        let (sut, store) = makeSUT(currentDate: { currentDate })

        sut.validateCache()
        store.completeRetrieve(with: uniqueImages().locals, timestamp: lessThanSevenDaysTimestamp)

        XCTAssertEqual(store.messages, [.retrieve])
    }

    func testValidateCacheDoesNotRequestDeletionWhenCacheIsEmpty() {
        let (sut, store) = makeSUT()

        sut.validateCache()
        store.completeRetrieveWithEmptyCache()

        XCTAssertEqual(store.messages, [.retrieve])
    }

    func testValidateCacheDoesNotRequestDeletionAfterSUTHasBeenDeallocated() {
        let store = FeedStoreSpy()
        var sut: LocalFeedLoader? = LocalFeedLoader(store: store)

        sut?.validateCache()
        sut = nil
        store.completeRetrieve(with: makeNSError())

        XCTAssertEqual(store.messages, [.retrieve])
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
