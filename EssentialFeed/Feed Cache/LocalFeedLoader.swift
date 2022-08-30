import Foundation

public final class LocalFeedLoader {
    private let store: FeedStore
    private let currentDate: () -> Date
    private let calendar = Calendar(identifier: .gregorian)

    public typealias SaveResult = (Error?) -> Void
    public typealias LoadResult = (LoadFeedResult) -> Void

    public init(store: FeedStore, currentDate: @escaping () -> Date = Date.init) {
        self.store = store
        self.currentDate = currentDate
    }

    public func save(feed: [FeedImage], completion: @escaping SaveResult) {
        store.delete { [weak self] error in
            guard let self = self else { return }

            if let cacheDeleteError = error {
                completion(cacheDeleteError)
            } else {
                self.cache(feed, completion: completion)
            }
        }
    }

    public func load(completion: @escaping LoadResult) {
        store.retrieve { [unowned self] result in
            switch (result) {
            case let .failure(error):
                completion(.failure(error))
            case let .found(localFeed, timestamp) where self.validate(timestamp):
                completion(.success(localFeed.toModels()))
            case .found, .empty:
                completion(.success([]))
            }
        }
    }

    private func cache(_ feed: [FeedImage], completion: @escaping SaveResult) {
        store.persist(images: feed.toLocal(), timestamp: currentDate()) { [weak self] error in
            guard self != nil else { return }
            completion(error)
        }
    }

    private let maxCacheAgeInDays = 7
    private func validate(_ timestamp: Date) -> Bool {
        guard let maxCacheAge = calendar.date(byAdding: .day, value: maxCacheAgeInDays, to: timestamp) else { return false }

        return currentDate() < maxCacheAge
    }

}

private extension Array where Element == FeedImage {
    func toLocal() -> [LocalFeedImage] {
        return map { LocalFeedImage(id: $0.id, description: $0.description, location: $0.location, url: $0.url) }
    }
}

private extension Array where Element == LocalFeedImage {
    func toModels() -> [FeedImage] {
        return map { FeedImage(id: $0.id, description: $0.description, location: $0.location, url: $0.url) }
    }
}
