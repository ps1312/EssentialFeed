import XCTest
import EssentialFeed

class InMemoryFeedStore {
    var cache = [LocalFeedImage]()

    func retrieve(completion: @escaping FeedStore.RetrieveCompletion) {
        if cache.isEmpty {
            completion(.empty)
        } else {
            completion(.found(feed: cache, timestamp: Date()))
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

        let exp = expectation(description: "Wait for cache retrieval")
        sut.retrieve { received in
            switch (received) {
            case .empty:
                break
            default:
                XCTFail("Expected retrieve to return .empty, got \(received)")
            }

            exp.fulfill()
        }

        wait(for: [exp], timeout: 5.0)
    }

    func test_retrieveAfterPersist_deliversLastCachedImages() {
        let locals = uniqueImages().locals

        let now = Date()
        let sut = InMemoryFeedStore()

        let exp = expectation(description: "Wait for cache persistance")
        sut.persist(images: locals, timestamp: now) { error in
            exp.fulfill()
        }

        let exp1 = expectation(description: "Wait for cache retrieve")
        sut.retrieve { received in
            switch (received) {
            case let .found(feed, _):
                XCTAssertEqual(feed, locals)
            default:
                XCTFail("Expected retrieve to return .empty, got \(received)")
            }

            exp1.fulfill()
        }
        wait(for: [exp, exp1], timeout: 5.0)
    }
}
