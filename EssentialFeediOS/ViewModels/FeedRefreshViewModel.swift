import EssentialFeed

class FeedRefreshViewModel {
    typealias Observer<T> = ((T) -> Void)

    private let feedLoader: FeedLoader

    init (feedLoader: FeedLoader) {
        self.feedLoader = feedLoader
    }

    var onLoadingChange: Observer<Bool>?
    var onFeedChange: Observer<[FeedImage]>?

    func loadFeed() {
        onLoadingChange?(true)

        feedLoader.load { [weak self] result in
            if let feed = try? result.get() {
                self?.onFeedChange?(feed)
            }

            self?.onLoadingChange?(false)
        }
    }
}
