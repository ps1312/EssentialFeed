import Foundation
import EssentialFeed

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
