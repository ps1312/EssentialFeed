import XCTest
import EssentialFeed

class InMemoryFeedStoreTests: XCTestCase {
    func test_init_doesNotHaveSideEffects() {
        let sut = makeSUT()
        expect(sut, toRetrieve: .empty)
    }

    func test_retrieveAfterPersist_deliversLastCachedImagesWithTimestamp() {
        let now = Date()
        let locals = uniqueImages().locals
        let sut = makeSUT(date: now)

        let exp = expectation(description: "Wait for cache persistance")
        sut.persist(images: locals, timestamp: now) { error in
            exp.fulfill()
        }
        wait(for: [exp], timeout: 5.0)

        expect(sut, toRetrieve: .found(feed: locals, timestamp: now))
    }

    func makeSUT(date: Date = Date(), file: StaticString = #filePath, line: UInt = #line) -> InMemoryFeedStore {
        let sut = InMemoryFeedStore(currentDate: { date })
        testMemoryLeak(sut, file: file, line: line)
        return sut
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
                XCTFail("Expected \(expectedResult), received \(receivedResult)")

            }

            exp.fulfill()
        }

        wait(for: [exp], timeout: 5.0)
    }
}
