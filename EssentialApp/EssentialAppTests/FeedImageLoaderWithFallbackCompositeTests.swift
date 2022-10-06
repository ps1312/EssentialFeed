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
        func cancel() {

        }
    }

    func load(from url: URL, completion: @escaping (FeedImageLoader.Result) -> Void) -> FeedImageLoaderTask {
        let task = CompositeImageLoaderTask()
        _ = primaryLoader.load(from: url, completion: completion)
        return task
    }

}

class FeedImageLoaderWithFallbackCompositeTests: XCTestCase {

    func test_FeedImageLoaderWithFallback_deliversPrimaryResultOnPrimaryLoadSuccess() {
        let primaryData = makeData()
        let fallbackData = makeData()
        let sut = makeSUT(primaryResult: .success(primaryData), fallbackResult: .success(fallbackData))

        let exp = expectation(description: "wait for image load to complete")
        _ = sut.load(from: makeURL()) { receivedResult in
            switch (receivedResult) {
            case .success(let receivedData):
                XCTAssertEqual(receivedData, primaryData)

            default:
                XCTFail("Expected load to succeed, instead got \(receivedResult)")

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

    private func testMemoryLeak(_ instance: AnyObject, file: StaticString = #filePath, line: UInt = #line) {
        addTeardownBlock { [weak instance] in
            XCTAssertNil(instance, "Instance is not deallocated after test ends. Possible memory leak", file: file, line: line)
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
            let task =  StubbedImageLoaderTask()
            completion(result)
            return task
        }
    }

    func makeURL(suffix: String = "") -> URL {
        return URL(string: "https://www.a-url\(suffix).com")!
    }

    private func makeData() -> Data {
        return Data(UUID().uuidString.utf8)
    }

}
