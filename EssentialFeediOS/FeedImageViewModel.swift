import Foundation
import EssentialFeed

final class FeedImageViewModel {
    typealias Observer<T> = ((T) -> Void)

    private let model: FeedImage
    private let imageLoader: FeedImageLoader
    private var task: FeedImageLoaderTask?

    init(model: FeedImage, imageLoader: FeedImageLoader) {
        self.model = model
        self.imageLoader = imageLoader
    }

    var onLoadingChange: Observer<Bool>?
    var onImageLoad: Observer<Data>?
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
                self?.onImageLoad?(data)
            }

            self?.onLoadingChange?(false)
        }
    }

    func cancelLoad() {
        task?.cancel()
        task = nil
    }
}
