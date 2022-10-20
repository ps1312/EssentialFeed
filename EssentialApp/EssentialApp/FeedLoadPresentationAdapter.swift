import Combine
import EssentialFeed
import EssentialFeediOS

final class FeedLoadPresentationAdapter: FeedRefreshViewControllerDelegate {
    private let feedLoader: () -> FeedLoader.Publisher
    private var cancellable: Cancellable?
    var presenter: FeedPresenter?

    init(feedLoader: @escaping () -> FeedLoader.Publisher) {
        self.feedLoader = feedLoader
    }

    func didRequestFeedLoad() {
        presenter?.didStartLoadingFeed()

        cancellable = feedLoader().sink(receiveCompletion: { [weak self] result in
            switch (result) {
            case .finished: break

            case .failure:
                self?.presenter?.didFinishLoadingFeedWithError()
            }
        }, receiveValue: { [weak self] feed in
            self?.presenter?.didLoadFeed(feed)
        })
    }
}
