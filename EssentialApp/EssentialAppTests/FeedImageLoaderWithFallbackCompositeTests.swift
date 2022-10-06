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
//        let fallbackData = makeData()
        let primaryLoader = ImageLoaderStub()
        let fallbackLoader = ImageLoaderStub()
        let sut = FeedImageLoaderWithFallbackComposite(primaryLoader: primaryLoader, fallbackLoader: fallbackLoader)

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

    final class ImageLoaderStub: FeedImageLoader {
        private final class StubbedImageLoaderTask: FeedImageLoaderTask {

            func cancel() {

            }

        }

        func load(from url: URL, completion: @escaping (FeedImageLoader.Result) -> Void) -> FeedImageLoaderTask {
            let task =  StubbedImageLoaderTask()
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
