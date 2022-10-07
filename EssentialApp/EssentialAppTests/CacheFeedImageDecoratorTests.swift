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

class CacheFeedImageDecoratorTests: XCTestCase, FeedImageLoaderTestCase {

    func test_load_deliversImageDataWhenLoadSucceeds() {
        let data = makeData()
        let (sut, loaderSpy) = makeSUT()

        expect(sut, toCompleteWith: .success(data), when: {
            loaderSpy.completeWith(data: data)
        })
    }

    func test_load_deliversErrorWhenImageLoadFails() {
        let error = makeNSError()
        let (sut, loaderSpy) = makeSUT()

        expect(sut, toCompleteWith: .failure(error), when: {
            loaderSpy.completeWith(error: error)
        })
    }

    private func makeSUT(file: StaticString = #filePath, line: UInt = #line) -> (CacheFeedImageDecorator, FeedImageLoaderSpy) {
        let loaderSpy = FeedImageLoaderSpy()
        let sut = CacheFeedImageDecorator(imageLoader: loaderSpy)

        testMemoryLeak(loaderSpy, file: file, line: line)
        testMemoryLeak(sut, file: file, line: line)

        return (sut, loaderSpy)
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
