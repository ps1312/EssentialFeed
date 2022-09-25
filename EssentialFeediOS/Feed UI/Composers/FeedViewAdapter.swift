import EssentialFeed
import UIKit

final class FeedViewAdapter: FeedView {
    private let imageLoader: FeedImageLoader
    weak var feedController: FeedViewController?

    init(imageLoader: FeedImageLoader) {
        self.imageLoader = imageLoader
    }

    func display(_ viewModel: FeedViewModel) {
        feedController?.cellControllers = viewModel.feed.map { model in
            // abstracts the communication between domain and presentation (by *adapting the image load output to the presenter input)
            let cellControllerDelegate = FeedImageLoadPresentationAdapter<WeakRefVirtualProxy<FeedImageCellController>, UIImage>(
                model: model,
                imageLoader: imageLoader,
                imageTransformer: UIImage.init
            )

            // configures cell and requests for image load through a protocol
            let feedImageView = FeedImageCellController(delegate: cellControllerDelegate)

            // present views by using display() methods
            let feedImagePresenter = FeedImagePresenter<WeakRefVirtualProxy<FeedImageCellController>, UIImage>(
                feedImageView: WeakRefVirtualProxy(feedImageView)
            )

            // handle composition details...
            cellControllerDelegate.presenter = feedImagePresenter

            return feedImageView
        }
    }
}
