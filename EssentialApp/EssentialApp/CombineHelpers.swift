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
        return Deferred {
            Future(self.load)
        }.eraseToAnyPublisher()
    }
}

extension FeedCache {
    func saveIgnoringResult(_ feed: [FeedImage]) {
        save(feed: feed) { _ in }
    }
}

extension Publisher where Output == [FeedImage] {
    func caching(to cache: FeedCache) -> AnyPublisher<Output, Failure> {
        handleEvents(receiveOutput: cache.saveIgnoringResult).eraseToAnyPublisher()
    }

    func caching(to cache: FeedCache, with existingImages: [FeedImage]) -> AnyPublisher<Output, Failure> {
        handleEvents(receiveOutput: { cache.saveIgnoringResult(existingImages + $0) }).eraseToAnyPublisher()
    }
}

extension FeedImageLoader {
    public typealias Publisher = AnyPublisher<Data, Error>

    public func loadImagePublisher(from url: URL) -> Publisher {
        var task: FeedImageLoaderTask?

        return Deferred {
            Future { completion in
                task = load(from: url, completion: completion)
            }
        }.handleEvents(receiveCancel: {
            task?.cancel()
        }).eraseToAnyPublisher()
    }
}

extension FeedImageCache {
    func saveIgnoringResult(_ url: URL, with data: Data) {
        save(url: url, with: data, completion: { _ in })
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

    func trace(url: URL, to logger: Logger) -> AnyPublisher<Output, Failure> {
        let start = CACurrentMediaTime()
        logger.trace("Started loading url \(url)")

        return handleEvents(receiveCompletion: { _ in
            let now = CACurrentMediaTime()
            logger.trace("Finished loading \(url) in: \(now - start) seconds")
        }).eraseToAnyPublisher()
    }
}
