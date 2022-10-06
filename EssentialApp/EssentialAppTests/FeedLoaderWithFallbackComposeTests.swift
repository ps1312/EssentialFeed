import XCTest
import EssentialFeed
import EssentialApp

final class FeedLoaderWithFallbackComposeTests: XCTestCase {

    func test_FeedLoaderWithFallback_deliversPrimaryResultOnPrimaryLoadSuccess() {
        let primaryFeed = uniqueFeed()
        let fallbackFeed = uniqueFeed()
        let sut = makeSUT(primaryResult: .success(primaryFeed), fallbackResult: .success(fallbackFeed))

        expect(sut, toCompleteWith: .success(primaryFeed))
    }

    func test_FeedLoaderWithFallback_deliversFallbackResultOnPrimaryLoadFailureAndFallbackSuccess() {
        let fallbackFeed = uniqueFeed()
        let sut = makeSUT(primaryResult: .failure(makeNSError()), fallbackResult: .success(fallbackFeed))

        expect(sut, toCompleteWith: .success(fallbackFeed))
    }

    func test_FeedLoaderWithFallback_deliversErrorOnPrimaryAndFallbackLoadFailure() {
        let error = makeNSError()
        let sut = makeSUT(primaryResult: .failure(error), fallbackResult: .failure(error))

        expect(sut, toCompleteWith: .failure(error))
    }

    private func expect(_ sut: FeedLoaderWithFallbackComposite, toCompleteWith expectedResult: LoadFeedResult) {
        let exp = expectation(description: "wait for feed load to complete")

        sut.load { receivedResult in
            switch (receivedResult, expectedResult) {
            case let (.success(receivedFeed), .success(expectedFeed)):
                XCTAssertEqual(receivedFeed, expectedFeed)

            case let (.failure(receivedError), .failure(expectedError)):
                XCTAssertEqual(receivedError as NSError, expectedError as NSError)

            default:
                XCTFail("Expected \(expectedResult), instead got \(receivedResult)")
            }

            exp.fulfill()
        }

        wait(for: [exp], timeout: 1.0)
    }

    private func makeSUT(primaryResult: LoadFeedResult, fallbackResult: LoadFeedResult, file: StaticString = #filePath, line: UInt = #line) -> FeedLoaderWithFallbackComposite {
        let primaryLoader = LoaderStub(primaryResult)
        let fallbackLoader = LoaderStub(fallbackResult)
        let sut = FeedLoaderWithFallbackComposite(primary: primaryLoader, fallback: fallbackLoader)

        testMemoryLeak(sut, file: file, line: line)
        testMemoryLeak(primaryLoader, file: file, line: line)
        testMemoryLeak(fallbackLoader, file: file, line: line)

        return sut
    }

    private func testMemoryLeak(_ instance: AnyObject, file: StaticString = #filePath, line: UInt = #line) {
        addTeardownBlock { [weak instance] in
            XCTAssertNil(instance, "Instance is not deallocated after test ends. Possible memory leak", file: file, line: line)
        }
    }

    private func makeNSError() -> NSError {
        return NSError(domain: "Test", code: 1)
    }

    private func uniqueFeed() -> [FeedImage] {
        let url = URL(string: "https://www.any-url.com")!
        let feedImage1 = FeedImage(id: UUID(), description: nil, location: nil, url: url)
        let feedImage2 = FeedImage(id: UUID(), description: nil, location: nil, url: url)
        return [feedImage1, feedImage2]
    }

    private class LoaderStub: FeedLoader {
        private let result: LoadFeedResult

        init (_ result: LoadFeedResult) {
            self.result = result
        }

        func load(completion: @escaping (LoadFeedResult) -> Void) {
            completion(result)
        }
    }

}
