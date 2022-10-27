import Combine
import EssentialFeed
import EssentialFeediOS

final class FeedLoadPresentationAdapter: FeedRefreshViewControllerDelegate {
    private let feedLoader: () -> AnyPublisher<[FeedImage], Error>
    private var cancellable: Cancellable?
    var presenter: LoadResourcePresenter<[FeedImage], FeedViewAdapter>?

    init(feedLoader: @escaping () -> AnyPublisher<[FeedImage], Error>) {
        self.feedLoader = feedLoader
    }

    func didRequestFeedLoad() {
        presenter?.didStartLoading()

        cancellable = feedLoader().sink(receiveCompletion: { [weak self] result in
            switch (result) {
            case .finished: break

            case .failure:
                self?.presenter?.didFinishLoadingWithError()
            }
        }, receiveValue: { [weak self] feed in
            self?.presenter?.didLoad(feed)
        })
    }
}
