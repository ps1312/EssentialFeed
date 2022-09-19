import Foundation
import EssentialFeed

protocol FeedImageView {
    associatedtype Image
    func display(isLoading: Bool, shouldRetry: Bool, image: Image?, description: String?, location: String?)
}

final class FeedImagePresenter<View: FeedImageView, Image> where View.Image == Image  {
    private let model: FeedImage
    private let imageLoader: FeedImageLoader
    private let imageTransformer: (Data) -> Image?
    private var task: FeedImageLoaderTask?

    init(model: FeedImage, imageLoader: FeedImageLoader, imageTransformer: @escaping (Data) -> Image?) {
        self.model = model
        self.imageLoader = imageLoader
        self.imageTransformer = imageTransformer
    }

    var feedImageView: View?

    func loadImage() {
        feedImageView?.display(isLoading: true, shouldRetry: false, image: nil, description: model.description, location: model.location)

        task = imageLoader.load(from: model.url) { [weak self] result in
            switch (result) {
            case .failure:
                self?.feedImageView?.display(isLoading: false, shouldRetry: true, image: nil, description: self?.model.description, location: self?.model.location)

            case .success(let data):
                if let image = self?.imageTransformer(data) {
                    self?.feedImageView?.display(isLoading: false, shouldRetry: false, image: image, description: self?.model.description, location: self?.model.location)
                } else {
                    self?.feedImageView?.display(isLoading: false, shouldRetry: true, image: nil, description: self?.model.description, location: self?.model.location)
                }
            }
        }
    }

    func cancelLoad() {
        task?.cancel()
        task = nil
    }
}
