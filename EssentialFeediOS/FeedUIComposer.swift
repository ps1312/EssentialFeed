import EssentialFeed
import UIKit

final class FeedUIComposer {
    static func composeWith(feedLoader: FeedLoader, imageLoader: FeedImageLoader) -> FeedViewController {
        let feedController = FeedViewController()
        let feedPresenter = FeedPresenter(feedLoader: feedLoader)
        let feedViewAdapter = FeedViewAdapter(imageLoader: imageLoader)

        let refreshController = FeedRefreshViewController(presenter: feedPresenter)

        feedViewAdapter.feedController = feedController

        feedPresenter.loadingView = refreshController
        feedPresenter.feedView = feedViewAdapter

        feedController.refreshController = refreshController

        return feedController
    }
}

final class FeedViewAdapter: FeedView {
    private let imageLoader: FeedImageLoader

    weak var feedController: FeedViewController?

    init(imageLoader: FeedImageLoader) {
        self.imageLoader = imageLoader
    }

    func display(feed: [FeedImage]) {
        feedController?.cellControllers = feed.map { model in
            let feedImageViewModel = FeedImageViewModel(model: model, imageLoader: imageLoader, imageTransformer: UIImage.init)
            return FeedImageCellController(viewModel: feedImageViewModel)
        }
    }
}
