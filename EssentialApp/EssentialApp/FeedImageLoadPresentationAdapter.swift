import Foundation
import EssentialFeed
import EssentialFeediOS

final class FeedImageLoadPresentationAdapter<View: FeedImageView, Image>: FeedImageCellControllerDelegate where View.Image == Image {
    private let model: FeedImage
    private let imageLoader: FeedImageLoader
    private var task: FeedImageLoaderTask?

    var presenter: FeedImagePresenter<View, Image>?

    init(model: FeedImage, imageLoader: FeedImageLoader) {
        self.model = model
        self.imageLoader = imageLoader
    }

    func didRequestImageLoad() {
        presenter?.didStartLoadingImage(model: model)

        task = imageLoader.load(from: model.url) { [weak self] result in
            guard let self = self else { return }

            if let imageData = try? result.get() {
                self.presenter?.didFinishLoadingImage(model: self.model, data: imageData)
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
