import Foundation
import Combine
import EssentialFeed
import EssentialFeediOS

final class FeedImageLoadPresentationAdapter<View: FeedImageView, Image>: FeedImageCellControllerDelegate where View.Image == Image {
    private let model: FeedImage
    private let imageLoader: (URL) -> FeedImageLoader.Publisher
    private var cancellable: Cancellable?

    var presenter: FeedImagePresenter<View, Image>?

    init(model: FeedImage, imageLoader: @escaping (URL) -> FeedImageLoader.Publisher) {
        self.model = model
        self.imageLoader = imageLoader
    }

    func didRequestImageLoad() {
        presenter?.didStartLoadingImage(model: model)

        cancellable = imageLoader(model.url).sink(receiveCompletion: { [weak self] result in
            switch (result) {
            case .finished: break

            case .failure:
                guard let self = self else { return }
                self.presenter?.didFinishLoadingImageWithError(model: self.model)
            }
        }, receiveValue: { [weak self] image in
            guard let self = self else { return }
            self.presenter?.didFinishLoadingImage(model: self.model, data: image)
        })
    }

    func didCancelImageLoad() {
        cancellable?.cancel()
        cancellable = nil
    }

}
