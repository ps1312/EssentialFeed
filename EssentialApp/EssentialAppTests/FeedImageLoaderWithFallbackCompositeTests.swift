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
                _ = self?.fallbackLoader.load(from: url, completion: completion)

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

        switch (receivedResult) {
        case .none:
            break

        default:
            XCTFail("Expected no results after task has been canceled, instead got \(String(describing: receivedResult))")

        }
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

        private final class ImageLoaderTaskSpy: FeedImageLoaderTask {
            func cancel() {}
        }

        func load(from url: URL, completion: @escaping (FeedImageLoader.Result) -> Void) -> FeedImageLoaderTask {
            let task = ImageLoaderTaskSpy()
            completions.append(completion)
            return task
        }

        func completeWith(data: Data, at index: Int = 0) {
            completions[index](.success(data))
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
