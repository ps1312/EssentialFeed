import XCTest
import EssentialFeed
import EssentialApp

class FeedImageLoaderWithFallbackCompositeTests: XCTestCase {

    func test_FeedImageLoaderWithFallback_deliversPrimaryResultOnPrimaryLoadSuccess() {
        let primaryData = makeData()
        let fallbackData = makeData()
        let sut = makeSUT(primaryResult: .success(primaryData), fallbackResult: .success(fallbackData))

        expect(sut, toCompleteWith: .success(primaryData))
    }

    func test_FeedImageLoaderWithFallback_deliversFallbackResultOnPrimaryLoadFailure() {
        let fallbackData = makeData()
        let sut = makeSUT(primaryResult: .failure(makeNSError()), fallbackResult: .success(fallbackData))

        expect(sut, toCompleteWith: .success(fallbackData))
    }

    func test_FeedImageLoaderWithFallback_deliversErrorOnPrimaryAndFallbackLoadFailures() {
        let error = makeNSError()
        let sut = makeSUT(primaryResult: .failure(error), fallbackResult: .failure(error))

        expect(sut, toCompleteWith: .failure(error))
    }

    func test_primaryLoad_deliversNoResultsAfterInstanceHasBeenDeallocated() {
        let primaryLoader = ImageLoaderSpy()
        let fallbackLoader = ImageLoaderSpy()
        var sut: FeedImageLoaderWithFallbackComposite? = FeedImageLoaderWithFallbackComposite(primaryLoader: primaryLoader, fallbackLoader: fallbackLoader)

        var receivedResult: FeedImageLoader.Result?
        _ = sut?.load(from: makeURL()) { receivedResult = $0 }
        sut = nil
        primaryLoader.completeWith(data: makeData())

        XCTAssertNil(receivedResult, "Expected no results in primary task after instance has been deallocated")
    }

    func test_fallbackLoad_deliversNoResultsAfterInstanceHasBeenDeallocated() {
        let primaryLoader = ImageLoaderSpy()
        let fallbackLoader = ImageLoaderSpy()
        var sut: FeedImageLoaderWithFallbackComposite? = FeedImageLoaderWithFallbackComposite(primaryLoader: primaryLoader, fallbackLoader: fallbackLoader)

        var receivedResult: FeedImageLoader.Result?
        _ = sut?.load(from: makeURL()) { receivedResult = $0 }
        primaryLoader.completeWith(error: makeNSError())
        sut = nil
        fallbackLoader.completeWith(data: makeData())

        XCTAssertNil(receivedResult, "Expected no results in fallback task after instance has been deallocated")
    }

    func test_primaryLoadCancel_deliversNoResult() {
        let primaryData = makeData()
        let fallbackData = makeData()
        let primaryLoader = ImageLoaderSpy()
        let fallbackLoader = ImageLoaderStub(.success(fallbackData))
        let sut = FeedImageLoaderWithFallbackComposite(primaryLoader: primaryLoader, fallbackLoader: fallbackLoader)

        var receivedResult: FeedImageLoader.Result?
        let task = sut.load(from: makeURL()) { receivedResult = $0 }
        task.cancel()

        primaryLoader.completeWith(data: primaryData)

        XCTAssertNil(receivedResult, "Expected no results after primary task has been canceled, instead got \(String(describing: receivedResult))")
    }

    func test_primaryLoadCancel_requestsTaskCancelation() {
        let url = makeURL()
        let primaryLoader = ImageLoaderSpy()
        let fallbackLoader = ImageLoaderSpy()
        let sut = FeedImageLoaderWithFallbackComposite(primaryLoader: primaryLoader, fallbackLoader: fallbackLoader)

        let task = sut.load(from: url) { _ in }
        task.cancel()

        XCTAssertEqual(primaryLoader.canceledURLs, [url], "Expected canceled task onlys on primary loader")
        XCTAssertEqual(fallbackLoader.canceledURLs, [], "Expected no canceled tasks on fallback loader")
    }

    func test_fallbackLoadCancel_requestsTaskCancelation() {
        let url = makeURL()
        let primaryLoader = ImageLoaderSpy()
        let fallbackLoader = ImageLoaderSpy()
        let sut = FeedImageLoaderWithFallbackComposite(primaryLoader: primaryLoader, fallbackLoader: fallbackLoader)

        let task = sut.load(from: url) { _ in }
        primaryLoader.completeWith(error: makeNSError())
        task.cancel()

        XCTAssertEqual(primaryLoader.canceledURLs, [], "Expected no canceled tasks on primary loader")
        XCTAssertEqual(fallbackLoader.canceledURLs, [url], "Expected canceled tasks only on fallback loader")
    }

    func test_fallbackLoadCancel_deliversNoResultsAfterFallbackLoadIsCanceled() {
        let primaryLoader = ImageLoaderSpy()
        let fallbackLoader = ImageLoaderSpy()
        let sut = FeedImageLoaderWithFallbackComposite(primaryLoader: primaryLoader, fallbackLoader: fallbackLoader)

        var receivedResult: FeedImageLoader.Result?
        let task = sut.load(from: makeURL()) { receivedResult = $0 }

        primaryLoader.completeWith(error: makeNSError())
        task.cancel()
        fallbackLoader.completeWith(data: makeData())

        XCTAssertNil(receivedResult, "Expected no results after fallback task has been canceled, instead got \(String(describing: receivedResult))")
    }

    private func makeSUT(primaryResult: FeedImageLoader.Result, fallbackResult: FeedImageLoader.Result, file: StaticString = #filePath, line: UInt = #line) -> FeedImageLoaderWithFallbackComposite {
        let primaryLoader = ImageLoaderStub(primaryResult)
        let fallbackLoader = ImageLoaderStub(fallbackResult)
        let sut = FeedImageLoaderWithFallbackComposite(primaryLoader: primaryLoader, fallbackLoader: fallbackLoader)

        testMemoryLeak(primaryLoader, file: file, line: line)
        testMemoryLeak(fallbackLoader, file: file, line: line)
        testMemoryLeak(sut, file: file, line: line)

        return sut
    }

    private final class ImageLoaderSpy: FeedImageLoader {
        var completions = [(FeedImageLoader.Result) -> Void]()
        var canceledURLs = [URL]()

        private final class ImageLoaderTaskSpy: FeedImageLoaderTask {
            var onCancel: (() -> Void)?

            func cancel() {
                onCancel?()
            }
        }

        func load(from url: URL, completion: @escaping (FeedImageLoader.Result) -> Void) -> FeedImageLoaderTask {
            let task = ImageLoaderTaskSpy()
            completions.append(completion)
            task.onCancel = { self.canceledURLs.append(url) }
            return task
        }

        func completeWith(data: Data, at index: Int = 0) {
            completions[index](.success(data))
        }

        func completeWith(error: Error, at index: Int = 0) {
            completions[index](.failure(error))
        }
    }

    private final class ImageLoaderStub: FeedImageLoader {
        private let result: FeedImageLoader.Result

        init(_ primaryResult: FeedImageLoader.Result) {
            self.result = primaryResult
        }

        private final class StubbedImageLoaderTask: FeedImageLoaderTask {
            func cancel() {}
        }

        func load(from url: URL, completion: @escaping (FeedImageLoader.Result) -> Void) -> FeedImageLoaderTask {
            let task = StubbedImageLoaderTask()
            completion(result)
            return task
        }
    }

}
