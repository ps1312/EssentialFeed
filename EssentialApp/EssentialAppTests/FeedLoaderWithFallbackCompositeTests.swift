import XCTest
import EssentialFeed
import EssentialApp

final class FeedLoaderWithFallbackCompositeTests: XCTestCase, FeedLoaderTestCase {

    func test_FeedLoaderWithFallback_deliversPrimaryResultOnPrimaryLoadSuccess() {
        let primaryFeed = uniqueFeed()
        let (sut, primaryLoader, _) = makeSUT()

        expect(sut, toCompleteWith: .success(primaryFeed), when: {
            primaryLoader.completeWith(feed: primaryFeed)
        })
    }

    func test_FeedLoaderWithFallback_deliversFallbackResultOnPrimaryLoadFailureAndFallbackSuccess() {
        let fallbackFeed = uniqueFeed()
        let (sut, primaryLoader, fallbackLoader) = makeSUT()

        expect(sut, toCompleteWith: .success(fallbackFeed), when: {
            primaryLoader.completeWith(error: makeNSError())
            fallbackLoader.completeWith(feed: fallbackFeed)
        })
    }

    func test_FeedLoaderWithFallback_deliversErrorOnPrimaryAndFallbackLoadFailure() {
        let error = makeNSError()
        let (sut, primaryLoader, fallbackLoader) = makeSUT()

        expect(sut, toCompleteWith: .failure(error), when: {
            primaryLoader.completeWith(error: makeNSError())
            fallbackLoader.completeWith(error: makeNSError())
        })
    }

    func test_primaryLoader_deliversNoResultsAfterInstanceHasBeenDeallocated() {
        let primaryLoader = LoaderSpy()
        let fallbackLoader = LoaderSpy()
        var sut: FeedLoaderWithFallbackComposite? = FeedLoaderWithFallbackComposite(primary: primaryLoader, fallback: fallbackLoader)

        var receivedResult: LoadFeedResult?
        sut?.load { receivedResult = $0 }
        sut = nil

        primaryLoader.completeWith(feed: uniqueFeed())

        XCTAssertNil(receivedResult, "Expected no results after primary task has been canceled, instead got \(String(describing: receivedResult))")
    }

    func test_fallbackLoader_deliversNoResultsAfterInstanceHasBeenDeallocated() {
        let primaryLoader = LoaderSpy()
        let fallbackLoader = LoaderSpy()
        var sut: FeedLoaderWithFallbackComposite? = FeedLoaderWithFallbackComposite(primary: primaryLoader, fallback: fallbackLoader)

        var receivedResult: LoadFeedResult?
        sut?.load { receivedResult = $0 }
        primaryLoader.completeWith(error: makeNSError())
        sut = nil
        fallbackLoader.completeWith(feed: uniqueFeed())

        XCTAssertNil(receivedResult, "Expected no results after fallback task has been canceled, instead got \(String(describing: receivedResult))")
    }

    private func makeSUT(file: StaticString = #filePath, line: UInt = #line) -> (sut: FeedLoaderWithFallbackComposite, primaryLoader: LoaderSpy, fallbackLoader: LoaderSpy) {
        let primaryLoader = LoaderSpy()
        let fallbackLoader = LoaderSpy()
        let sut = FeedLoaderWithFallbackComposite(primary: primaryLoader, fallback: fallbackLoader)

        testMemoryLeak(sut, file: file, line: line)
        testMemoryLeak(primaryLoader, file: file, line: line)
        testMemoryLeak(fallbackLoader, file: file, line: line)

        return (sut, primaryLoader, fallbackLoader)
    }

    private class LoaderSpy: FeedLoader {
        var completions = [(LoadFeedResult) -> Void]()

        func load(completion: @escaping (LoadFeedResult) -> Void) {
            completions.append(completion)
        }

        func completeWith(feed: [FeedImage], at index: Int = 0) {
            completions[index](.success(feed))
        }

        func completeWith(error: Error, at index: Int = 0) {
            completions[index](.failure(error))
        }
    }

}
