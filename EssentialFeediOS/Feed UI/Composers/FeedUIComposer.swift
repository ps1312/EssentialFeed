import EssentialFeed
import UIKit

final class FeedUIComposer {
    static func composeWith(feedLoader: FeedLoader, imageLoader: FeedImageLoader) -> FeedViewController {
        let feedPresenter = FeedPresenter()

        let bundle = Bundle(for: FeedUIComposer.self)
        let storyboard = UIStoryboard(name: "Feed", bundle: bundle)
        let feedController = storyboard.instantiateInitialViewController() as! FeedViewController
        feedController.delegate = FeedRefreshDelegate(feedLoader: feedLoader, presenter: feedPresenter)
        feedController.title = FeedPresenter.title
        
        let feedViewAdapter = FeedViewAdapter(imageLoader: imageLoader)
        feedViewAdapter.feedController = feedController

        // add views to presenter
        feedPresenter.loadingView = WeakRefVirtualProxy(feedController)
        feedPresenter.feedView = feedViewAdapter

        return feedController
    }
}

final class FeedRefreshDelegate: FeedRefreshViewControllerDelegate {
    private let feedLoader: FeedLoader
    private let presenter: FeedPresenter

    init(feedLoader: FeedLoader, presenter: FeedPresenter) {
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
            let feedImagePresenter = FeedImagePresenter<WeakRefVirtualProxy<FeedImageCellController>, UIImage>()

            let cellControllerDelegate = FeedImageLoadPresentationAdapter<WeakRefVirtualProxy<FeedImageCellController>, UIImage>(
                model: model, imageLoader: imageLoader, imageTransformer: UIImage.init
            )
            cellControllerDelegate.presenter = feedImagePresenter

            let feedImageView = FeedImageCellController(delegate: cellControllerDelegate)
            feedImagePresenter.feedImageView = WeakRefVirtualProxy(feedImageView)

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
