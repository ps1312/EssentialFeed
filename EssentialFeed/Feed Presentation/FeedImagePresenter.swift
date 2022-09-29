import Foundation

public class FeedImagePresenter<View: FeedImageView, Image> where View.Image == Image {
    private let feedImageView: View

    public init(feedImageView: View) {
        self.feedImageView = feedImageView
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

    public func didFinishLoadingImage(model: FeedImage, image: Image?) {
        feedImageView.display(
            FeedImageViewModel(
                isLoading: false,
                shouldRetry: false,
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
}
