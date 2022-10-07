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

        expect(sut, toCompleteWith: .success(data), when: {
            loaderSpy.completeWith(data: data)
        })
    }

    func test_load_deliversErrorWhenImageLoadFails() {
        let error = makeNSError()
        let loaderSpy = FeedImageLoaderSpy()
        let sut = CacheFeedImageDecorator(imageLoader: loaderSpy)

        expect(sut, toCompleteWith: .failure(error), when: {
            loaderSpy.completeWith(error: error)
        })
    }

    private func expect(_ sut: FeedImageLoader, toCompleteWith expectedResult: FeedImageLoader.Result, when action: () -> Void, file: StaticString = #filePath, line: UInt = #line) {
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

        action()

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

        func completeWith(error: Error, at index: Int = 0) {
            completions[index](.failure(error))
        }

    }

}
