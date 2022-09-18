import EssentialFeed

final class FeedUIComposer {
    static func composeWith(feedLoader: FeedLoader, imageLoader: FeedImageLoader) -> FeedViewController {
        let feedController = FeedViewController()

        let refreshController = FeedRefreshViewController(feedLoader: feedLoader)
        refreshController.onFeedLoad = { [weak feedController] feed in
            feedController?.cellControllers = feed.map { FeedImageCellController(model: $0, imageLoader: imageLoader) }
        }
        feedController.refreshController = refreshController

        return feedController
    }
}
