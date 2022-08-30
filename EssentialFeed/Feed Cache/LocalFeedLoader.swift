import Foundation

public final class FeedCachePolicy {
    private init () {}

    private static let calendar = Calendar(identifier: .gregorian)

    static let maxCacheAgeInDays = 7

    static func validate(_ timestamp: Date, against date: Date) -> Bool {
        guard let maxCacheAge = calendar.date(byAdding: .day, value: maxCacheAgeInDays, to: timestamp) else { return false }

        return date < maxCacheAge
    }}

public final class LocalFeedLoader {
    private let store: FeedStore
    private let currentDate: () -> Date

    public init(store: FeedStore, currentDate: @escaping () -> Date = Date.init) {
        self.store = store
        self.currentDate = currentDate
    }
}

extension LocalFeedLoader {
    public typealias SaveResult = (Error?) -> Void

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

    private func cache(_ feed: [FeedImage], completion: @escaping SaveResult) {
        store.persist(images: feed.toLocal(), timestamp: currentDate()) { [weak self] error in
            guard self != nil else { return }
            completion(error)
        }
    }
}

extension LocalFeedLoader {
    public typealias LoadResult = (LoadFeedResult) -> Void

    public func load(completion: @escaping LoadResult) {
        store.retrieve { [weak self] result in
            guard let self = self else { return }

            switch (result) {
            case let .failure(error):
                completion(.failure(error))

            case let .found(localFeed, timestamp) where FeedCachePolicy.validate(timestamp, against: self.currentDate()):
                completion(.success(localFeed.toModels()))

            case .found, .empty:
                completion(.success([]))

            }
        }
    }
}

extension LocalFeedLoader {
    public func validateCache() {
        store.retrieve { [weak self] result in
            guard let self = self else { return }

            switch (result) {
            case .failure:
                self.store.delete { _ in }

            case let .found(_, timestamp) where !FeedCachePolicy.validate(timestamp, against: self.currentDate()):
                self.store.delete { _ in }

            case .found, .empty:
                break
            }
        }
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
