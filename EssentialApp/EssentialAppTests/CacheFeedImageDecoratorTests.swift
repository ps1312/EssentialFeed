import XCTest
import EssentialFeed
import EssentialApp

class CacheFeedImageDecoratorTests: XCTestCase, FeedImageLoaderTestCase {

    func test_load_deliversImageDataWhenLoadSucceeds() {
        let data = makeData()
        let (sut, loaderSpy, _) = makeSUT()

        expect(sut, toCompleteWith: .success(data), when: {
            loaderSpy.completeWith(data: data)
        })
    }

    func test_load_deliversErrorWhenImageLoadFails() {
        let error = makeNSError()
        let (sut, loaderSpy, _) = makeSUT()

        expect(sut, toCompleteWith: .failure(error), when: {
            loaderSpy.completeWith(error: error)
        })
    }

    func test_load_messagesFeedImageCacheWithImageWhenLoadSucceeds() {
        let url = makeURL()
        let data = makeData()
        let (sut, loaderSpy, cacheSpy) = makeSUT()

        _ = sut.load(from: makeURL()) { _ in }
        loaderSpy.completeWith(data: data)

        XCTAssertEqual(cacheSpy.messages, [.save(data, url)])
    }

    func test_loadCancel_messagesFeedImageLoaderToCancelLoading() {
        let url = makeURL()
        let (sut, loaderSpy, _) = makeSUT()

        let task = sut.load(from: url) { _ in }
        task.cancel()

        XCTAssertEqual(loaderSpy.canceledURLs, [url])
    }

    private func makeSUT(file: StaticString = #filePath, line: UInt = #line) -> (FeedImageLoaderCacheDecorator, FeedImageLoaderSpy, FeedImageCacheSpy) {
        let loaderSpy = FeedImageLoaderSpy()
        let cacheSpy = FeedImageCacheSpy()
        let sut = FeedImageLoaderCacheDecorator(imageLoader: loaderSpy, imageCache: cacheSpy)

        testMemoryLeak(loaderSpy, file: file, line: line)
        testMemoryLeak(cacheSpy, file: file, line: line)
        testMemoryLeak(sut, file: file, line: line)

        return (sut, loaderSpy, cacheSpy)
    }

    private final class FeedImageCacheSpy: FeedImageCache {
        enum Message: Equatable {
            case save(Data, URL)
        }
        var messages = [Message]()

        func save(url: URL, with data: Data, completion: @escaping (Error?) -> Void) {
            messages.append(.save(data, url))
        }
    }
}
