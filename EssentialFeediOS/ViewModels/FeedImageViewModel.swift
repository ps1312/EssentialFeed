import Foundation
import EssentialFeed

final class FeedImageViewModel<Image> {
    typealias Observer<T> = ((T) -> Void)

    private let model: FeedImage
    private let imageLoader: FeedImageLoader
    private let imageTransformer: (Data) -> Image?
    private var task: FeedImageLoaderTask?

    init(model: FeedImage, imageLoader: FeedImageLoader, imageTransformer: @escaping (Data) -> Image?) {
        self.model = model
        self.imageLoader = imageLoader
        self.imageTransformer = imageTransformer
    }

    var onLoadingChange: Observer<Bool>?
    var onImageLoad: Observer<Image>?
    var onImageLoadedWithError: (() -> Void)?

    var description: String? {
        return model.description
    }

    var hasDescription: Bool {
        return description != nil
    }

    var location: String? {
        return model.location
    }

    var hasLocation: Bool {
        return location != nil
    }

    func loadImage() {
        onLoadingChange?(true)

        task = imageLoader.load(from: model.url) { [weak self] result in
            switch (result) {
            case .failure:
                self?.onImageLoadedWithError?()

            case .success(let data):
                if let image = self?.imageTransformer(data) {
                    self?.onImageLoad?(image)
                } else {
                    self?.onImageLoadedWithError?()
                }
            }

            self?.onLoadingChange?(false)
        }
    }

    func cancelLoad() {
        task?.cancel()
        task = nil
    }
}
