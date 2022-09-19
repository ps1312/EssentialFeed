import EssentialFeed

final class FeedUIComposer {
    static func composeWith(feedLoader: FeedLoader, imageLoader: FeedImageLoader) -> FeedViewController {
        let feedController = FeedViewController()

        let feedRefreshViewModel = FeedRefreshViewModel(feedLoader: feedLoader)
        feedRefreshViewModel.onFeedChange = FeedUIComposer.adaptFeedImageToCellControllers(feedController, imageLoader)
        feedController.refreshController = FeedRefreshViewController(viewModel: feedRefreshViewModel)

        return feedController
    }

    static func adaptFeedImageToCellControllers(_ feedController: FeedViewController, _ imageLoader: FeedImageLoader) -> ([FeedImage]) -> Void {
        return { [weak feedController] feed in
            feedController?.cellControllers = feed.map { FeedImageCellController(model: $0, imageLoader: imageLoader) }
        }
    }
}
