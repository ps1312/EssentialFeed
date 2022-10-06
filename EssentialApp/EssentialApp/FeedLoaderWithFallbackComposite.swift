import Foundation
import EssentialFeed

public final class FeedLoaderWithFallbackComposite: FeedLoader {
    private let primary: FeedLoader
    private let fallback: FeedLoader

    public init(primary: FeedLoader, fallback: FeedLoader) {
        self.primary = primary
        self.fallback = fallback
    }

    public func load(completion: @escaping (LoadFeedResult) -> Void) {
        primary.load { [weak self] primaryResult in
            switch (primaryResult) {
            case .success(let primaryFeed):
                completion(.success(primaryFeed))

            case .failure:
                self?.fallback.load(completion: completion)

            }
        }
    }
}
