import Foundation
import EssentialFeed

public final class FeedLoaderCacheDecorator: FeedLoader {
    private let decoratee: FeedLoader
    private let feedCache: FeedCache

    public init(decoratee: FeedLoader, feedCache: FeedCache) {
        self.decoratee = decoratee
        self.feedCache = feedCache
    }

    public func load(completion: @escaping (LoadFeedResult) -> Void) {
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
