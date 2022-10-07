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

class CacheFeedDecoratorTests: XCTestCase {

    func test_load_deliversFeedWhenFeedLoaderSucceeds() {
        let feed = uniqueFeed()
        let loader = FeedLoaderSpy()
        let sut = CacheFeedDecorator(decoratee: loader)

        let exp = expectation(description: "wait for feed to load")
        sut.load { receivedResult in
            switch (receivedResult) {
            case .success(let receivedFeed):
                XCTAssertEqual(receivedFeed, feed)

            default:
                XCTFail("Expected feed load to succeed, instead got \(receivedResult)")
            }

            exp.fulfill()
        }

        loader.completeFeedLoad(with: feed)
        wait(for: [exp], timeout: 1.0)
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
