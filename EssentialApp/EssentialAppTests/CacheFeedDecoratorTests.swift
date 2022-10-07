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
        let loader = FeedLoaderSpy()
        let sut = CacheFeedDecorator(decoratee: loader)

        expect(sut, toCompleteWith: .success(feed), when: {
            loader.completeFeedLoad(with: feed)
        })
    }

    private final class FeedLoaderSpy: FeedLoader {
        var completions = [(LoadFeedResult) -> Void]()

        func load(completion: @escaping (LoadFeedResult) -> Void) {
            completions.append(completion)
        }

        func completeFeedLoad(with feed: [FeedImage], at index: Int = 0) {
            completions[index](.success(feed))
        }

    }

}
