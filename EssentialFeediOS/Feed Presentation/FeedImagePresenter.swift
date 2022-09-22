import Foundation
import EssentialFeed

final class FeedImagePresenter<View: FeedImageView, Image> where View.Image == Image  {
    var feedImageView: View?

    func didStartLoadingImage(model: FeedImage) {
        feedImageView?.display(
            FeedImageViewModel(
                isLoading: true,
                shouldRetry: false,
                image: nil,
                description: model.description,
                location: model.location
            )
        )
    }

    func didFinishLoadingImage(model: FeedImage, image: Image?) {
        feedImageView?.display(
            FeedImageViewModel(
                isLoading: false,
                shouldRetry: false,
                image: image,
                description: model.description,
                location: model.location
            )
        )
    }

    func didFinishLoadingImageWithError(model: FeedImage) {
        feedImageView?.display(
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
