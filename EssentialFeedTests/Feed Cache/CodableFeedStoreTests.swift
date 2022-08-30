import XCTest
import EssentialFeed

class CodableFeedStore {

    func retrieve(completion: (CacheRetrieveResult) -> Void) {
        completion(.empty)
    }

}

class CodableFeedStoreTests: XCTestCase {

    func test_retrieve_returnsEmptyOnNoCache() {
        let exp = expectation(description: "wait for retrieve to complete")
        let sut = CodableFeedStore()

        sut.retrieve { result in
            switch (result) {
            case .empty:
                break
            default:
                XCTFail("Expected retrieve to return empty, insteal got \(result)")
            }

            exp.fulfill()
        }

        wait(for: [exp], timeout: 1.0)
    }

}
