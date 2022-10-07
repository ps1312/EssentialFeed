import XCTest
import EssentialFeed

class CacheFeedDecorator: FeedLoader {
    private let decoratee: FeedLoader

    init(decoratee: FeedLoader) {
        self.decoratee = decoratee
    }

    func load(completion: @escaping (LoadFeedResult) -> Void) {
        decoratee.load(completion: completion)
    }

}

class CacheFeedDecoratorTests: XCTestCase, FeedLoaderTestCase {

    func test_load_deliversFeedWhenFeedLoaderSucceeds() {
        let feed = uniqueFeed()
        let (sut, loader) = makeSUT()

        expect(sut, toCompleteWith: .success(feed), when: {
            loader.completeFeedLoad(with: feed)
        })
    }

    func test_load_deliversErrorWhenFeedLoaderFails() {
        let error = makeNSError()
        let (sut, loader) = makeSUT()

        expect(sut, toCompleteWith: .failure(error), when: {
            loader.completeFeedLoad(with: error)
        })
    }

    private func makeSUT() -> (CacheFeedDecorator, FeedLoaderSpy) {
        let loader = FeedLoaderSpy()
        let sut = CacheFeedDecorator(decoratee: loader)
        return (sut, loader)
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
