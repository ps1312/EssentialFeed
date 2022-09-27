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
            switch (result) {
            case .success(let feed):
                self?.presenter?.didLoadFeed(feed)

            case .failure:
                self?.presenter?.didFinishLoadingFeedWithError()
        
            }
        }
    }
}
