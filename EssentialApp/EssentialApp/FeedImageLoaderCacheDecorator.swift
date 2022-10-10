import Foundation
import EssentialFeed

public final class FeedImageLoaderCacheDecorator: FeedImageLoader {
    private let imageLoader: FeedImageLoader
    private let imageCache: FeedImageCache

    public init(imageLoader: FeedImageLoader, imageCache: FeedImageCache) {
        self.imageLoader = imageLoader
        self.imageCache = imageCache
    }

    public func load(from url: URL, completion: @escaping (FeedImageLoader.Result) -> Void) -> FeedImageLoaderTask {
        return imageLoader.load(from: url) { [weak self] result in
            switch (result) {
            case .success(let data):
                self?.imageCache.save(url: url, with: data) { _ in }
                completion(.success(data))

            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

}
