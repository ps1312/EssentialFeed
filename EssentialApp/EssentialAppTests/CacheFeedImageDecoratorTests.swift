import XCTest
import EssentialFeed

class CacheFeedImageDecorator: FeedImageLoader {
    private let imageLoader: FeedImageLoader

    init(imageLoader: FeedImageLoader) {
        self.imageLoader = imageLoader
    }

    func load(from url: URL, completion: @escaping (FeedImageLoader.Result) -> Void) -> FeedImageLoaderTask {
        return imageLoader.load(from: url, completion: completion)
    }

}

class CacheFeedImageDecoratorTests: XCTestCase, FeedLoaderTestCase {

    func test_load_deliversImageDataWhenLoadSucceeds() {
        let data = makeData()
        let loaderSpy = FeedImageLoaderSpy()
        let sut = CacheFeedImageDecorator(imageLoader: loaderSpy)

        let exp = expectation(description: "wait for image load to complete")
        _ = sut.load(from: makeURL()) { receivedResult in
            switch (receivedResult) {
            case .success(let receivedData):
                XCTAssertEqual(receivedData, data)

            default:
                XCTFail("Expected image load to succeed, instead got \(receivedResult)")

            }
            exp.fulfill()
        }

        loaderSpy.completeWith(data: data)

        wait(for: [exp], timeout: 1.0)
    }

    private final class FeedImageLoaderSpy: FeedImageLoader {
        var completions = [(FeedImageLoader.Result) -> Void]()

        private final class Task: FeedImageLoaderTask {
            func cancel() {}
        }

        func load(from url: URL, completion: @escaping (FeedImageLoader.Result) -> Void) -> FeedImageLoaderTask {
            completions.append(completion)
            return Task()
        }

        func completeWith(data: Data, at index: Int = 0) {
            completions[index](.success(data))
        }

    }

}
