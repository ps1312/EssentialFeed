import XCTest
import EssentialFeed

class InMemoryFeedStoreTests: XCTestCase {
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

    func makeSUT(date: Date = Date(), file: StaticString = #filePath, line: UInt = #line) -> InMemoryFeedStore {
        let sut = InMemoryFeedStore(currentDate: { date })
        testMemoryLeak(sut, file: file, line: line)
        return sut
    }

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
}
