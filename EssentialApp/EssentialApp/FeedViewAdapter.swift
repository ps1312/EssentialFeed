import UIKit
import EssentialFeed
import EssentialFeediOS

final class FeedViewAdapter: ResourceView {
    private let imageLoader: (URL) -> FeedImageLoader.Publisher
    weak var feedController: FeedViewController?

    init(imageLoader: @escaping (URL) -> FeedImageLoader.Publisher) {
        self.imageLoader = imageLoader
    }

    func display(_ viewModel: FeedViewModel) {
        feedController?.cellControllers = viewModel.feed.map { model in
            let cellControllerDelegate = FeedImageLoadPresentationAdapter<WeakRefVirtualProxy<FeedImageCellController>, UIImage>(
                model: model,
                imageLoader: imageLoader
            )

            let feedImageView = FeedImageCellController(delegate: cellControllerDelegate)

            let feedImagePresenter = FeedImagePresenter<WeakRefVirtualProxy<FeedImageCellController>, UIImage>(
                feedImageView: WeakRefVirtualProxy(feedImageView),
                imageTransformer: UIImage.init
            )

            cellControllerDelegate.presenter = feedImagePresenter

            return feedImageView
        }
    }
}
