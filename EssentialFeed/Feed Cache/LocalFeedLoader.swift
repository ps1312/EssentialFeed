import Foundation

public final class LocalFeedLoader {
    private let store: FeedStore
    private let currentDate: () -> Date

    public init(store: FeedStore, currentDate: @escaping () -> Date = Date.init) {
        self.store = store
        self.currentDate = currentDate
    }
}

extension LocalFeedLoader {
    public func save(feed: [FeedImage]) throws {
        try store.delete()
        try store.persist(images: feed.toLocal(), timestamp: currentDate())
    }
}

extension LocalFeedLoader {
    public typealias LoadResult = (Result<[FeedImage], Error>) -> Void

    public func load(completion: @escaping LoadResult) {
        do {
            let result = try store.retrieve()

            switch (result) {
            case let .failure(error):
                completion(.failure(error))
                
            case let .found(localFeed, timestamp) where FeedCachePolicy.validate(timestamp, against: self.currentDate()):
                completion(.success(localFeed.toModels()))
                
            case .found, .empty:
                completion(.success([]))
            }
        } catch {
            completion(.failure(error))
        }
    }
}

extension LocalFeedLoader {
    public typealias ValidateCacheResult = Result<Void, Error>

    public func validateCache(completion: @escaping (ValidateCacheResult) -> Void) {
        do {
            let result = try store.retrieve()

            switch (result) {
            case .failure:
                try store.delete()

            case let .found(_, timestamp) where !FeedCachePolicy.validate(timestamp, against: self.currentDate()):
                try store.delete()

            case .found, .empty:
                break
            }
        } catch {
            try? store.delete()
        }
    }

    private func finishDeleteWith(_ completion: @escaping (ValidateCacheResult) -> Void) -> (Error?) -> Void {
        return { error in
            if let deletionError = error {
                completion(.failure(deletionError))
            } else {
                completion(.success(()))
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
