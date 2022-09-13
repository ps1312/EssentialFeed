import EssentialFeed

final class FeedUIComposer {
    static func composeWith(feedLoader: FeedLoader, imageLoader: FeedImageLoader) -> FeedViewController {
        let refreshViewModel = FeedViewModel(feedLoader: feedLoader)
        let refreshController = FeedRefreshViewController(viewModel: refreshViewModel)
        let feedViewController = FeedViewController()

        refreshViewModel.onFeedLoad = FeedUIComposer.adaptFeedImagesToCells(forwardingTo: feedViewController, imageLoader: imageLoader)
        feedViewController.refreshController = refreshController

        return feedViewController
    }

    private static func adaptFeedImagesToCells(forwardingTo feedViewController: FeedViewController, imageLoader: FeedImageLoader) -> ([FeedImage]) -> Void {
        return { [weak feedViewController] feedImages in
            feedViewController?.tableModel = feedImages.map { model in
                let feedImageViewModel = FeedImageViewModel(model: model, imageLoader: imageLoader)
                let cellController = FeedImageCellViewController(viewModel: feedImageViewModel)

                return cellController
            }
        }
    }
}
