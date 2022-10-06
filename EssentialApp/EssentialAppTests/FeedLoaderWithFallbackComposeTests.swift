import XCTest
import EssentialFeed

final class FeedLoaderWithFallbackComposite: FeedLoader {
    private let primary: FeedLoader
    private let fallback: FeedLoader

    init (primary: FeedLoader, fallback: FeedLoader) {
        self.primary = primary
        self.fallback = fallback
    }

    func load(completion: @escaping (LoadFeedResult) -> Void) {
        primary.load { [weak self] primaryResult in
            switch (primaryResult) {
            case .success(let primaryFeed):
                completion(.success(primaryFeed))

            case .failure:
                self?.fallback.load(completion: completion)

            }
        }
    }
}

final class FeedLoaderWithFallbackComposeTests: XCTestCase {

    func test_FeedLoaderWithFallback_deliversPrimaryResultOnPrimaryLoadSuccess() {
        let primaryFeed = uniqueFeed()
        let fallbackFeed = uniqueFeed()
        let sut = makeSUT(primaryResult: .success(primaryFeed), fallbackResult: .success(fallbackFeed))

        let exp = expectation(description: "wait for feed load to complete")
        sut.load { result in
            switch (result) {
            case .success(let receivedFeed):
                XCTAssertEqual(receivedFeed, primaryFeed)

            default:
                XCTFail("Expected feed load to succeed, instead got \(result)")
            }

            exp.fulfill()
        }

        wait(for: [exp], timeout: 1.0)
    }

    func test_FeedLoaderWithFallback_deliversFallbackResultOnPrimaryLoadFailureAndFallbackSuccess() {
        let fallbackFeed = uniqueFeed()
        let sut = makeSUT(primaryResult: .failure(makeNSError()), fallbackResult: .success(fallbackFeed))

        let exp = expectation(description: "wait for feed load to complete")
        sut.load { result in
            switch (result) {
            case .success(let receivedFeed):
                XCTAssertEqual(receivedFeed, fallbackFeed)

            default:
                XCTFail("Expected feed load to succeed, instead got \(result)")
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
