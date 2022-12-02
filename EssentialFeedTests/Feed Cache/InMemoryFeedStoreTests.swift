import XCTest
import EssentialFeed

class InMemoryFeedStoreTests: XCTestCase {
    // MARK: - FeedStore tests

    func test_init_doesNotHaveSideEffectsOnFeed() {
        let sut = makeSUT()
        expect(sut, toRetrieve: .empty)
    }

    func test_feedRetrieveAfterPersist_deliversLastCacheWithTimestamp() throws {
        let now = Date()
        let locals = uniqueImages().locals
        let sut = makeSUT(date: now)

        try sut.persist(images: locals, timestamp: now)
        expect(sut, toRetrieve: .found(feed: locals, timestamp: now))
    }

    func test_feedRetrieveAfterDelete_deliversEmptyAfterDeletingNonEmptyCache() throws {
        let now = Date()
        let locals = uniqueImages().locals
        let sut = makeSUT(date: now)

        try sut.persist(images: locals, timestamp: now)
        try sut.delete()
        expect(sut, toRetrieve: .empty)
    }

    // MARK: - FeedImageStore tests

    func test_imageRetrieve_deliversEmptyOnEmptyCache() {
        let sut = makeSUT()

        XCTAssertEqual(nil, try sut.retrieve(from: makeURL()))
    }

    func test_imageRetrieve_deliversDataOnNonEmptyCache() throws {
        let url1 = makeURL(suffix: "specific-image")
        let data1 = Data("first data".utf8)

        let url2 = makeURL(suffix: "another-image")
        let data2 = Data("second data".utf8)

        let sut = makeSUT()

        try sut.insert(url: url1, with: data1)
        try sut.insert(url: url2, with: data2)

        XCTAssertEqual(data1, try sut.retrieve(from: url1))
        XCTAssertEqual(data2, try sut.retrieve(from: url2))
    }

    func makeSUT(date: Date = Date(), file: StaticString = #filePath, line: UInt = #line) -> InMemoryFeedStore {
        let sut = InMemoryFeedStore(currentDate: { date })
        testMemoryLeak(sut, file: file, line: line)
        return sut
    }

    // MARK: - FeedStore Helpers

    func expect(_ sut: InMemoryFeedStore, toRetrieve expectedResult: CacheRetrieveResult, file: StaticString = #filePath, line: UInt = #line) {
        do {
            let receivedResult = try sut.retrieve()

            switch(receivedResult, expectedResult) {
            case (.empty, .empty):
                break

            case let (.found(receivedFeed, receivedTimestamp), .found(expectedFeed, expectedTimestamp)):
                XCTAssertEqual(receivedFeed, expectedFeed, file: file, line: line)
                XCTAssertEqual(receivedTimestamp, expectedTimestamp, file: file, line: line)

            default:
                XCTFail("Expected \(expectedResult), received \(receivedResult)", file: file, line: line)

            }
        } catch {
            XCTFail("Expected retrieve to not fail, got \(error)")
        }
    }

    // MARK: - FeedImageStore Helpers

    func expect(_ sut: InMemoryFeedStore, toRetrieveImageCache expectedResult: Data?, from url: URL, file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertEqual(expectedResult, try sut.retrieve(from: url))
    }
}
