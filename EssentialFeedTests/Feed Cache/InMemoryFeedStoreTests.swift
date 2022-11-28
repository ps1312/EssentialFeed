import XCTest
import EssentialFeed

class InMemoryFeedStore {
    func retrieve(completion: @escaping FeedStore.RetrieveCompletion) {
        completion(.empty)
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
}
