import EssentialFeed
import UIKit

final class FeedUIComposer {
    static func composeWith(feedLoader: FeedLoader, imageLoader: FeedImageLoader) -> FeedViewController {
        // abstracts the communication between domain and presentation (by *adapting* the domain api output to presenter input)
        let feedRefreshDelegate = FeedRefreshDelegate(feedLoader: MainQueueDispatchDecorator<FeedLoader>(decoratee: feedLoader))

        // controls refresh and cells instantiation
        let feedController = FeedViewController.makeWith(delegate: feedRefreshDelegate, title: FeedPresenter.title)

        // adapts [FeedImage] to [FeedImageCellControllers]
        let feedViewAdapter = FeedViewAdapter(imageLoader: MainQueueDispatchDecorator(decoratee: imageLoader))

        // present views by using display() methods
        let feedPresenter = FeedPresenter(loadingView: WeakRefVirtualProxy(feedController), feedView: feedViewAdapter)

        // handle composition details... (by setting up the variables)
        feedViewAdapter.feedController = feedController
        feedRefreshDelegate.presenter = feedPresenter

        return feedController
    }
}

final class FeedRefreshDelegate: FeedRefreshViewControllerDelegate {
    private let feedLoader: FeedLoader
    var presenter: FeedPresenter?

    init(feedLoader: FeedLoader) {
        self.feedLoader = feedLoader
    }

    func didRequestFeedLoad() {
         presenter?.didStartLoadingFeed()

        feedLoader.load { [weak self] result in
            if let feed = try? result.get() {
                self?.presenter?.didLoadFeed(feed)
            }

            self?.presenter?.didFinishLoadingFeed()
        }
    }
}

private extension FeedViewController {
    static func makeWith(delegate: FeedRefreshViewControllerDelegate, title: String) -> FeedViewController {
        let bundle = Bundle(for: FeedUIComposer.self)
        let storyboard = UIStoryboard(name: "Feed", bundle: bundle)
        let feedController = storyboard.instantiateInitialViewController() as! FeedViewController
        feedController.title = title
        feedController.delegate = delegate

        return feedController
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

final class FeedImageLoadPresentationAdapter<View: FeedImageView, Image>: FeedImageCellControllerDelegate where View.Image == Image {
    private let model: FeedImage
    private let imageLoader: FeedImageLoader
    private let imageTransformer: (Data) -> Image?
    private var task: FeedImageLoaderTask?

    var presenter: FeedImagePresenter<View, Image>?

    init(model: FeedImage, imageLoader: FeedImageLoader, imageTransformer: @escaping (Data) -> Image?) {
        self.model = model
        self.imageLoader = imageLoader
        self.imageTransformer = imageTransformer
    }

    func didRequestImageLoad() {
        presenter?.didStartLoadingImage(model: model)

        task = imageLoader.load(from: model.url) { [weak self] result in
            guard let self = self else { return }

            if let imageData = try? result.get(), let image = self.imageTransformer(imageData) {
                self.presenter?.didFinishLoadingImage(model: self.model, image: image)
            } else {
                self.presenter?.didFinishLoadingImageWithError(model: self.model)
            }
        }

    }

    func didCancelImageLoad() {
        task?.cancel()
        task = nil
    }

}

