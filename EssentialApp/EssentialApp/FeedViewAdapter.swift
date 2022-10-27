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
            // abstracts the communication between domain and presentation (by *adapting the image load output to the presenter input)
            let cellControllerDelegate = FeedImageLoadPresentationAdapter<WeakRefVirtualProxy<FeedImageCellController>, UIImage>(
                model: model,
                imageLoader: imageLoader
            )

            // configures cell and requests for image load through a protocol
            let feedImageView = FeedImageCellController(delegate: cellControllerDelegate)

            // present views by using display() methods
            let feedImagePresenter = FeedImagePresenter<WeakRefVirtualProxy<FeedImageCellController>, UIImage>(
                feedImageView: WeakRefVirtualProxy(feedImageView),
                imageTransformer: UIImage.init
            )

            // handle composition details...
            cellControllerDelegate.presenter = feedImagePresenter

            return feedImageView
        }
    }
}
