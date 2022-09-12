import Foundation
import EssentialFeed

final class FeedRefreshViewModel {
    private let feedLoader: FeedLoader

    init(feedLoader: FeedLoader) {
        self.feedLoader = feedLoader
    }

    var onChange: ((FeedRefreshViewModel) -> Void)?
    var onFeedLoad: (([FeedImage]) -> Void)?

    private(set) var isLoading = false {
        didSet { onChange?(self) }
    }

    func loadImages() {
        isLoading = true

        feedLoader.load { [weak self] result in
            if let feedImages = try? result.get() {
                self?.onFeedLoad?(feedImages)
            }

            self?.isLoading = false
        }
    }

}
