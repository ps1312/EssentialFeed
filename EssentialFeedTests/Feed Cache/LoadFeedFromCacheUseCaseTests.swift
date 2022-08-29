
import XCTest
import EssentialFeed

class LoadFeedFromCacheUseCaseTests: XCTestCase {

    func testInitDoesNotRequestCacheDeletion() {
        let (_, storeSpy) = makeSUT()

        XCTAssertEqual(storeSpy.messages, [])
    }

    func testLoadRequestsCacheRetrieval() {
        let (sut, storeSpy) = makeSUT()

        sut.load { _ in }

        XCTAssertEqual(storeSpy.messages, [.retrieve])
    }

    func testLoadDeliversErrorOnRetrievalFailure() {
        let exp = expectation(description: "wait for load to complete")
        let expectedError = makeNSError()
        let (sut, storeSpy) = makeSUT()

        sut.load { receivedResult in
            switch (receivedResult) {
            case .failure(let receivedError):
                XCTAssertEqual(receivedError as NSError, expectedError)
            default:
                XCTFail("Expected failure, got \(receivedResult) instead.")
            }

            exp.fulfill()
        }

        storeSpy.completeRetrieve(with: expectedError)
        wait(for: [exp], timeout: 1.0)
    }

    func testLoadDeliversEmptyListWhenCacheIsEmpty() {
        let exp = expectation(description: "wait for load to complete")
        let (sut, storeSpy) = makeSUT()

        sut.load { receivedResult in
            switch (receivedResult) {
            case .success(let feedImages):
                XCTAssertEqual(feedImages, [])
            default:
                XCTFail("Expected success, got \(receivedResult) instead.")
            }

            exp.fulfill()
        }

        storeSpy.completeRetrieveWithEmptyCache()
        wait(for: [exp], timeout: 1.0)
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
