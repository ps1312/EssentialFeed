import XCTest
import EssentialFeed

extension FeedStoreSpecs where Self: XCTestCase {
    @discardableResult
    func delete(_ sut: FeedStore) -> Error? {
        let exp = expectation(description: "wait for deletion to complete")

        var deleteError: Error? = nil
        sut.delete { error in
            deleteError = error
            exp.fulfill()
        }
        wait(for: [exp], timeout: 1.0)

        return deleteError
    }

    @discardableResult
    func insert(_ sut: FeedStore, feed: [LocalFeedImage], timestamp: Date) -> Error? {
        let exp = expectation(description: "wait for insertion to complete")

        var persistError: Error? = nil
        sut.persist(images: feed, timestamp: timestamp) { error in
            persistError = error
            exp.fulfill()
        }

        wait(for: [exp], timeout: 1.0)

        return persistError
    }

    func expect(_ sut: FeedStore, toRetrieveTwice expectedResult: CacheRetrieveResult, file: StaticString = #filePath, line: UInt = #line) {
        expect(sut, toRetrieve: expectedResult, file: file, line: line)
        expect(sut, toRetrieve: expectedResult, file: file, line: line)
    }

    func expect(_ sut: FeedStore, toRetrieve expectedResult: CacheRetrieveResult, file: StaticString = #filePath, line: UInt = #line) {
        let exp = expectation(description: "wait for insertion and retrieval to complete")

        sut.retrieve { receivedResult in
            switch (receivedResult, expectedResult) {
            case (.empty, .empty), (.failure, .failure):
                break

            case let (.found(receivedFeed, receivedTimestamp), .found(expectedFeed, expectedTimestamp)):
                XCTAssertEqual(receivedFeed, expectedFeed)
                XCTAssertEqual(receivedTimestamp, expectedTimestamp)

            default:
                XCTFail("Expected results to match, instead got \(receivedResult) and \(expectedResult)", file: file, line: line)
            }

            exp.fulfill()
        }

        wait(for: [exp], timeout: 1.0)
    }
}
