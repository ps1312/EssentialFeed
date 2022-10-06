import XCTest
import EssentialFeed

class FeedImageLoaderWithFallbackComposite: FeedImageLoader {
    private let primaryLoader: FeedImageLoader
    private let fallbackLoader: FeedImageLoader

    init(primaryLoader: FeedImageLoader, fallbackLoader: FeedImageLoader) {
        self.primaryLoader = primaryLoader
        self.fallbackLoader = fallbackLoader
    }

    private final class CompositeImageLoaderTask: FeedImageLoaderTask {
        private var completion: ((FeedImageLoader.Result) -> Void)?
        var wrapped: FeedImageLoaderTask?

        init(_ completion: @escaping (FeedImageLoader.Result) -> Void) {
            self.completion = completion
        }

        func complete(_ result: FeedImageLoader.Result) {
            completion?(result)
        }

        func cancel() {
            wrapped?.cancel()
            preventFurtherCompletions()
        }

        func preventFurtherCompletions() {
            completion = nil
        }
    }

    func load(from url: URL, completion: @escaping (FeedImageLoader.Result) -> Void) -> FeedImageLoaderTask {
        let task = CompositeImageLoaderTask(completion)

        task.wrapped = primaryLoader.load(from: url) { [weak self] primaryResult in
            switch (primaryResult) {
            case .failure:
                task.wrapped = self?.fallbackLoader.load(from: url) { fallbackResult in
                    switch (fallbackResult) {
                    case (.success(let fallbackData)):
                        task.complete(.success(fallbackData))

                    case (.failure(let error)):
                        task.complete(.failure(error))

                    }
                }

            case .success(let primaryData):
                task.complete(.success(primaryData))
            }
        }

        return task
    }

}

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
        let fallbackData = makeData()
        let primaryLoader = ImageLoaderSpy()
        let fallbackLoader = ImageLoaderStub(.success(fallbackData))
        let sut = FeedImageLoaderWithFallbackComposite(primaryLoader: primaryLoader, fallbackLoader: fallbackLoader)

        let task = sut.load(from: url) { _ in }
        task.cancel()

        XCTAssertEqual(primaryLoader.canceledURLs, [url])
    }

    func test_fallbackLoadCancel_requestsTaskCancelation() {
        let url = makeURL()
        let primaryLoader = ImageLoaderSpy()
        let fallbackLoader = ImageLoaderSpy()
        let sut = FeedImageLoaderWithFallbackComposite(primaryLoader: primaryLoader, fallbackLoader: fallbackLoader)

        let task = sut.load(from: url) { _ in }
        primaryLoader.completeWith(error: makeNSError())
        task.cancel()

        XCTAssertEqual(fallbackLoader.canceledURLs, [url])
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

    private func expect(_ sut: FeedImageLoaderWithFallbackComposite, toCompleteWith expectedResult: FeedImageLoader.Result, file: StaticString = #filePath, line: UInt = #line) {
        let exp = expectation(description: "wait for image load to complete")

        _ = sut.load(from: makeURL()) { receivedResult in
            switch (receivedResult, expectedResult) {
            case let (.failure(receivedFailure), .failure(expectedFailure)):
                XCTAssertEqual(receivedFailure as NSError, expectedFailure as NSError, file: file, line: line)

            case let (.success(receivedData), .success(expectedData)):
                XCTAssertEqual(receivedData, expectedData, file: file, line: line)

            default:
                XCTFail("Expected load to succeed, instead got \(receivedResult)", file: file, line: line)

            }

            exp.fulfill()
        }

        wait(for: [exp], timeout: 1.0)
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

    final class ImageLoaderSpy: FeedImageLoader {
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

    final class ImageLoaderStub: FeedImageLoader {
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
