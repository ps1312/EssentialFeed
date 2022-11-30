import XCTest
import EssentialFeed

class InMemoryFeedStoreTests: XCTestCase {
    // MARK: - FeedStore tests

    func test_init_doesNotHaveSideEffectsOnFeed() {
        let sut = makeSUT()
        expect(sut, toRetrieve: .empty)
    }

    func test_feedRetrieveAfterPersist_deliversLastCacheWithTimestamp() {
        let now = Date()
        let locals = uniqueImages().locals
        let sut = makeSUT(date: now)

        persist(in: sut, locals: locals, timestamp: now)
        expect(sut, toRetrieve: .found(feed: locals, timestamp: now))
    }

    func test_feedRetrieveAfterDelete_deliversEmptyAfterDeletingNonEmptyCache() {
        let now = Date()
        let locals = uniqueImages().locals
        let sut = makeSUT(date: now)

        persist(in: sut, locals: locals, timestamp: now)
        delete(from: sut)
        expect(sut, toRetrieve: .empty)
    }

    // MARK: - FeedImageStore tests

    func test_imageRetrieve_deliversEmptyOnEmptyCache() {
        let sut = makeSUT()

        expect(sut, toRetrieveImageCache: .empty, from: makeURL())
    }

    func test_imageRetrieve_deliversDataOnNonEmptyCache() {
        let url1 = makeURL(suffix: "specific-image")
        let data1 = Data("first data".utf8)

        let url2 = makeURL(suffix: "another-image")
        let data2 = Data("second data".utf8)

        let sut = makeSUT()

        insert(in: sut, data: data1, on: url1)
        insert(in: sut, data: data2, on: url2)

        expect(sut, toRetrieveImageCache: .found(data1), from: url1)
        expect(sut, toRetrieveImageCache: .found(data2), from: url2)
    }

    func makeSUT(date: Date = Date(), file: StaticString = #filePath, line: UInt = #line) -> InMemoryFeedStore {
        let sut = InMemoryFeedStore(currentDate: { date })
        testMemoryLeak(sut, file: file, line: line)
        return sut
    }

    // MARK: - FeedStore Helpers

    func persist(in sut: InMemoryFeedStore, locals: [LocalFeedImage], timestamp: Date) {
        let persistExp = expectation(description: "Wait for cache persistance")
        sut.persist(images: locals, timestamp: timestamp) { error in
            persistExp.fulfill()
        }
        wait(for: [persistExp], timeout: 5.0)
    }

    func delete(from sut: InMemoryFeedStore) {
        let deleteExp = expectation(description: "Wait for cache deletion")
        sut.delete { _ in
            deleteExp.fulfill()
        }
        wait(for: [deleteExp], timeout: 5.0)
    }

    func expect(_ sut: InMemoryFeedStore, toRetrieve expectedResult: CacheRetrieveResult, file: StaticString = #filePath, line: UInt = #line) {
        let exp = expectation(description: "wait for cache retrieval")

        sut.retrieve { receivedResult in
            switch(receivedResult, expectedResult) {
            case (.empty, .empty):
                break

            case let (.found(receivedFeed, receivedTimestamp), .found(expectedFeed, expectedTimestamp)):
                XCTAssertEqual(receivedFeed, expectedFeed, file: file, line: line)
                XCTAssertEqual(receivedTimestamp, expectedTimestamp, file: file, line: line)

            default:
                XCTFail("Expected \(expectedResult), received \(receivedResult)", file: file, line: line)

            }

            exp.fulfill()
        }

        wait(for: [exp], timeout: 5.0)
    }

    // MARK: - FeedImageStore Helpers

    func insert(in sut: InMemoryFeedStore, data: Data, on url: URL) {
        let insertExp = expectation(description: "Wait for image cache insertion")
        sut.insert(url: url, with: data) { _ in
            insertExp.fulfill()
        }
        wait(for: [insertExp], timeout: 5.0)
    }

    func expect(_ sut: InMemoryFeedStore, toRetrieveImageCache expectedResult: CacheImageRetrieveResult, from url: URL) {
        let exp = expectation(description: "Wait for image cache retrieval")

        sut.retrieve(from: url) { receivedResult in
            switch (receivedResult, expectedResult) {
            case (.empty, .empty):
                break

            case let (.found(receivedImageData), .found(expectedImageData)):
                XCTAssertEqual(expectedImageData, receivedImageData)

            default:
                XCTFail("Expected \(expectedResult), instead got \(receivedResult)")

            }
            exp.fulfill()
        }

        wait(for: [exp], timeout: 5.0)
    }
}
