import EssentialFeed
import UIKit

final class FeedUIComposer {
    static func composeWith(feedLoader: FeedLoader, imageLoader: FeedImageLoader) -> FeedViewController {
        let feedController = FeedViewController()
        let feedPresenter = FeedPresenter()
        let feedViewAdapter = FeedViewAdapter(imageLoader: imageLoader)

        let refreshController = FeedRefreshViewController(
            delegate: FeedRefreshDelegate(feedLoader: feedLoader, presenter: feedPresenter)
        )

        feedViewAdapter.feedController = feedController

        feedPresenter.loadingView = WeakRefVirtualProxy(refreshController)
        feedPresenter.feedView = feedViewAdapter

        feedController.refreshController = refreshController

        return feedController
    }
}

final class FeedRefreshDelegate: FeedRefreshViewControllerDelegate {
    private let feedLoader: FeedLoader
    private let presenter: FeedPresenterDelegate

    init(feedLoader: FeedLoader, presenter: FeedPresenterDelegate) {
        self.feedLoader = feedLoader
        self.presenter = presenter
    }

    func didRequestFeedLoad() {
         presenter.didStartLoadingFeed()

        feedLoader.load { [weak self] result in
            if let feed = try? result.get() {
                self?.presenter.didLoadFeed(feed)
            }

            self?.presenter.didFinishLoadingFeed()
        }
    }
}

final class FeedViewAdapter: FeedView {
    private let imageLoader: FeedImageLoader
    weak var feedController: FeedViewController?

    init(imageLoader: FeedImageLoader) {
        self.imageLoader = imageLoader
    }

    func display(_ viewModel: FeedViewModel) {
        feedController?.cellControllers = viewModel.feed.map { model in
            let feedImagePresenter = FeedImagePresenter<WeakRefVirtualProxy<FeedImageCellController>, UIImage>(model: model, imageLoader: imageLoader, imageTransformer: UIImage.init)

            let feedImageView = FeedImageCellController(presenter: feedImagePresenter)
            feedImagePresenter.feedImageView = WeakRefVirtualProxy(feedImageView)

            return feedImageView
        }
    }
}

class WeakRefVirtualProxy<T: AnyObject> {
    private weak var object: T?

    init(_ object: T) {
        self.object = object
    }
}

extension WeakRefVirtualProxy: FeedLoadingView where T: FeedLoadingView {
    func display(_ viewModel: FeedLoadingViewModel) {
        object?.display(viewModel)
    }
}

extension WeakRefVirtualProxy: FeedImageView where T: FeedImageView, T.Image == UIImage {
    func display(_ viewModel: FeedImageViewModel<UIImage>) {
        object?.display(viewModel)
    }
}
