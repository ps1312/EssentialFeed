import Foundation
import EssentialFeed

final class FeedViewModel {
    typealias Observer<T> = (T) -> Void

    private let feedLoader: FeedLoader

    init(feedLoader: FeedLoader) {
        self.feedLoader = feedLoader
    }

    var onLoadingChanged: Observer<Bool>?
    var onFeedLoad: Observer<[FeedImage]>?

    func loadFeed() {
        onLoadingChanged?(true)

        feedLoader.load { [weak self] result in
            if let feedImages = try? result.get() {
                self?.onFeedLoad?(feedImages)
            }

            self?.onLoadingChanged?(false)
        }
    }

}
