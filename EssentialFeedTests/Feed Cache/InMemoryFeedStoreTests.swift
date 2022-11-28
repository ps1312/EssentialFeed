import XCTest
import EssentialFeed

class InMemoryFeedStore {
    private let currentDate: () -> Date
    var cache = [LocalFeedImage]()

    init(currentDate: @escaping () -> Date = Date.init) {
        self.currentDate = currentDate
    }

    func retrieve(completion: @escaping FeedStore.RetrieveCompletion) {
        if cache.isEmpty {
            completion(.empty)
        } else {
            completion(.found(feed: cache, timestamp: currentDate()))
        }
    }

    func persist(images: [LocalFeedImage], timestamp: Date, completion: @escaping FeedStore.PersistCompletion) {
        cache = images
        completion(nil)
    }
}

class InMemoryFeedStoreTests: XCTestCase {
    func test_init_doesNotHaveSideEffects() {
        let sut = InMemoryFeedStore()
        expect(sut, toRetrieve: .empty)
    }

    func test_retrieveAfterPersist_deliversLastCachedImagesWithTimestamp() {
        let now = Date()
        let locals = uniqueImages().locals
        let sut = InMemoryFeedStore(currentDate: { now })

        let exp = expectation(description: "Wait for cache persistance")
        sut.persist(images: locals, timestamp: now) { error in
            exp.fulfill()
        }
        wait(for: [exp], timeout: 5.0)

        expect(sut, toRetrieve: .found(feed: locals, timestamp: now))
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
