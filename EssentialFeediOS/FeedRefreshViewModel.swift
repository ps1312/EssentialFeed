import Foundation
import EssentialFeed

final class FeedRefreshViewModel {
    private let feedLoader: FeedLoader

    init(feedLoader: FeedLoader) {
        self.feedLoader = feedLoader
    }

    var onLoadingChanged: ((Bool) -> Void)?
    var onFeedLoad: (([FeedImage]) -> Void)?

    func loadImages() {
        onLoadingChanged?(true)

        feedLoader.load { [weak self] result in
            if let feedImages = try? result.get() {
                self?.onFeedLoad?(feedImages)
            }

            self?.onLoadingChanged?(false)
        }
    }

}
