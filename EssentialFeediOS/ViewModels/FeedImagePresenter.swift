import Foundation
import EssentialFeed

struct FeedImageViewModel<Image> {
    let isLoading: Bool
    let shouldRetry: Bool
    let image: Image?
    let description: String?
    let location: String?
}

protocol FeedImageView {
    associatedtype Image
    func display(_ viewModel: FeedImageViewModel<Image>)
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
        feedImageView?.display(
            FeedImageViewModel(
                isLoading: true,
                shouldRetry: false,
                image: nil,
                description: model.description,
                location: model.location
            )
        )

        task = imageLoader.load(from: model.url) { [weak self] result in
            switch (result) {
            case .failure:
                self?.feedImageView?.display(
                    FeedImageViewModel(
                        isLoading: false,
                        shouldRetry: true,
                        image: nil,
                        description: self?.model.description,
                        location: self?.model.location
                    )
                )

            case .success(let data):
                if let image = self?.imageTransformer(data) {
                    self?.feedImageView?.display(
                        FeedImageViewModel(
                            isLoading: false,
                            shouldRetry: false,
                            image: image,
                            description: self?.model.description,
                            location: self?.model.location
                        )
                    )


                } else {
                    self?.feedImageView?.display(
                        FeedImageViewModel(
                            isLoading: false,
                            shouldRetry: true,
                            image: nil,
                            description: self?.model.description,
                            location: self?.model.location
                        )
                    )
                }
            }
        }
    }

    func cancelLoad() {
        task?.cancel()
        task = nil
    }
}
