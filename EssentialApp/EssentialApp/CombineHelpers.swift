import UIKit
import OSLog
import Foundation
import Combine
import EssentialFeed

extension Paginated {
    func loadMorePublisher() -> AnyPublisher<Self, Error>? {
        guard let loadMore = loadMore else { return nil }

        return Deferred {
            Future(loadMore)
        }.eraseToAnyPublisher()
    }
}

extension LocalFeedLoader {
    public func loadPublisher() -> AnyPublisher<[FeedImage], Swift.Error> {
        Deferred {
            Future { completion in
                completion(Result { try self.load() })
            }
        }.eraseToAnyPublisher()
    }

    func saveIgnoringResult(_ feed: [FeedImage]) {

        do {
            try save(feed: feed)
        } catch {}
    }
}

extension Publisher where Output == [FeedImage] {
    func caching(to cache: LocalFeedLoader, with existingImages: [FeedImage]) -> AnyPublisher<Output, Failure> {
        handleEvents(receiveOutput: { cache.saveIgnoringResult(existingImages + $0) }).eraseToAnyPublisher()
    }
}

extension FeedImageLoader {
    public typealias Publisher = AnyPublisher<Data, Error>

    public func loadImagePublisher(from url: URL) -> Publisher {
        Deferred {
            Future { completion in
                completion(Result { try load(from: url) })
            }
        }.eraseToAnyPublisher()
    }
}

extension FeedImageCache {
    func saveIgnoringResult(_ url: URL, with data: Data) {
        do {
            try save(url: url, with: data)
        } catch {}
    }
}

extension Publisher where Output == Data {
    func caching(to cache: FeedImageCache, with url: URL) -> AnyPublisher<Output, Failure> {
        handleEvents(receiveOutput: { data in cache.saveIgnoringResult(url, with: data) }).eraseToAnyPublisher()
    }
}

extension Publisher {
    func fallback(to fallbackPublisher: @escaping () -> AnyPublisher<Output, Failure>) -> AnyPublisher<Output, Failure> {
        self.catch { _ in fallbackPublisher() }.eraseToAnyPublisher()
    }
}
