import Foundation

public class FeedImagePresenter<View: FeedImageView, Image> where View.Image == Image {
    private let feedImageView: View
    private let imageTransformer: (Data) -> Image?

    public init(feedImageView: View, imageTransformer: @escaping (Data) -> Image?) {
        self.feedImageView = feedImageView
        self.imageTransformer = imageTransformer
    }

    public func didStartLoadingImage(model: FeedImage) {
        feedImageView.display(
            FeedImageViewModel(
                isLoading: true,
                shouldRetry: false,
                image: nil,
                description: model.description,
                location: model.location
            )
        )
    }

    public func didFinishLoadingImage(model: FeedImage, data: Data) {
        let image = imageTransformer(data)

        feedImageView.display(
            FeedImageViewModel(
                isLoading: false,
                shouldRetry: image == nil,
                image: image,
                description: model.description,
                location: model.location
            )
        )
    }

    public func didFinishLoadingImageWithError(model: FeedImage) {
        feedImageView.display(
            FeedImageViewModel(
                isLoading: false,
                shouldRetry: true,
                image: nil,
                description: model.description,
                location: model.location
            )
        )
    }

    public static func map(_ model: FeedImage) -> FeedImageViewModel<Image> {
        FeedImageViewModel(
            isLoading: false,
            shouldRetry: false,
            image: nil,
            description: model.description,
            location: model.location
        )
    }
}
