import XCTest
import EssentialFeed
import EssentialApp

class CacheFeedDecoratorTests: XCTestCase, FeedLoaderTestCase {

    func test_load_deliversFeedWhenFeedLoaderSucceeds() {
        let feed = uniqueFeed()
        let (sut, loader, _) = makeSUT()

        expect(sut, toCompleteWith: .success(feed), when: {
            loader.completeWith(feed: feed)
        })
    }

    func test_load_deliversErrorWhenFeedLoaderFails() {
        let error = makeNSError()
        let (sut, loader, _) = makeSUT()

        expect(sut, toCompleteWith: .failure(error), when: {
            loader.completeWith(error: error)
        })
    }

    func test_load_messagesStoreToCacheFeedOnLoadSuccess() {
        let feed = uniqueFeed()
        let (sut, loader, cache) = makeSUT()

        sut.load { _ in }
        loader.completeWith(feed: feed)

        XCTAssertEqual(cache.messages, [.save(feed)])
    }

    func test_load_doesNotmessagesStoreToCacheFeedOnLoadFailure() {
        let (sut, loader, cache) = makeSUT()

        sut.load { _ in }
        loader.completeWith(error: makeNSError())

        XCTAssertEqual(cache.messages, [])
    }

    private func makeSUT(file: StaticString = #filePath, line: UInt = #line) -> (FeedLoaderCacheDecorator, FeedLoaderSpy, FeedCacheSpy) {
        let loader = FeedLoaderSpy()
        let cache = FeedCacheSpy()
        let sut = FeedLoaderCacheDecorator(decoratee: loader, feedCache: cache)

        testMemoryLeak(loader, file: file, line: line)
        testMemoryLeak(cache, file: file, line: line)
        testMemoryLeak(sut, file: file, line: line)

        return (sut, loader, cache)
    }

    private final class FeedCacheSpy: FeedCache {
        enum Message: Equatable {
            case save([FeedImage])
        }
        var messages = [Message]()

        func save(feed: [FeedImage], completion: @escaping LocalFeedLoader.SaveResult) {
            messages.append(.save(feed))
        }

    }

}
