import XCTest
import EssentialFeed

protocol FeedCache {
    func save(feed: [FeedImage], completion: @escaping LocalFeedLoader.SaveResult)
}

class CacheFeedDecorator: FeedLoader {
    private let decoratee: FeedLoader
    private let feedCache: FeedCache

    init(decoratee: FeedLoader, feedCache: FeedCache) {
        self.decoratee = decoratee
        self.feedCache = feedCache
    }

    func load(completion: @escaping (LoadFeedResult) -> Void) {
        decoratee.load { [weak self] result in
            switch (result) {
            case .success(let feed):
                self?.feedCache.save(feed: feed) { _ in }
                completion(.success(feed))

            case .failure(let error):
                completion(.failure(error))

            }
        }
    }

}

class CacheFeedDecoratorTests: XCTestCase, FeedLoaderTestCase {

    func test_load_deliversFeedWhenFeedLoaderSucceeds() {
        let feed = uniqueFeed()
        let (sut, loader, _) = makeSUT()

        expect(sut, toCompleteWith: .success(feed), when: {
            loader.completeFeedLoad(with: feed)
        })
    }

    func test_load_deliversErrorWhenFeedLoaderFails() {
        let error = makeNSError()
        let (sut, loader, _) = makeSUT()

        expect(sut, toCompleteWith: .failure(error), when: {
            loader.completeFeedLoad(with: error)
        })
    }

    func test_load_messagesStoreToCacheFeedOnLoadSuccess() {
        let feed = uniqueFeed()
        let (sut, loader, cache) = makeSUT()

        sut.load { _ in }

        loader.completeFeedLoad(with: feed)

        XCTAssertEqual(cache.messages, [.save(feed)])
    }

    private func makeSUT(file: StaticString = #filePath, line: UInt = #line) -> (CacheFeedDecorator, FeedLoaderSpy, FeedCacheSpy) {
        let loader = FeedLoaderSpy()
        let cache = FeedCacheSpy()
        let sut = CacheFeedDecorator(decoratee: loader, feedCache: cache)

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

    private final class FeedLoaderSpy: FeedLoader {
        var completions = [(LoadFeedResult) -> Void]()

        func load(completion: @escaping (LoadFeedResult) -> Void) {
            completions.append(completion)
        }

        func completeFeedLoad(with feed: [FeedImage], at index: Int = 0) {
            completions[index](.success(feed))
        }

        func completeFeedLoad(with error: Error, at index: Int = 0) {
            completions[index](.failure(error))
        }

    }

}
