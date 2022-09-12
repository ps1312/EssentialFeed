import Foundation
import EssentialFeed

final class FeedImageViewModel {

    private let model: FeedImage
    private let imageLoader: FeedImageLoader
    private var task: FeedImageLoaderTask?

    init(model: FeedImage, imageLoader: FeedImageLoader) {
        self.model = model
        self.imageLoader = imageLoader
    }

    var onLoadingChange: ((Bool) -> Void)?
    var onImageLoad: ((Data) -> Void)?
    var onLoadError: (() -> Void)?

    var description: String? {
        return model.description
    }

    var hasDescription: Bool {
        return model.description != nil
    }

    var location: String? {
        return model.location
    }

    var hasLocation: Bool {
        return model.location != nil
    }

    func loadImage() {
        onLoadingChange?(true)

        task = imageLoader.load(from: model.url) { [weak self] result in
            if let imageData = try? result.get() {
                self?.onImageLoad?(imageData)
            } else {
                self?.onLoadError?()
            }

            self?.onLoadingChange?(false)
        }
    }

    func cancelLoad() {
        task?.cancel()
        task = nil
    }
}
