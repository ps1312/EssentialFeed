import EssentialFeed

final class FeedLoadPresentationAdapter: FeedRefreshViewControllerDelegate {
    private let feedLoader: FeedLoader
    var presenter: FeedPresenter?

    init(feedLoader: FeedLoader) {
        self.feedLoader = feedLoader
    }

    func didRequestFeedLoad() {
         presenter?.didStartLoadingFeed()

        feedLoader.load { [weak self] result in
            if let feed = try? result.get() {
                self?.presenter?.didLoadFeed(feed)
            }

            self?.presenter?.didFinishLoadingFeed()
        }
    }
}
