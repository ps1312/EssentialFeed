import Foundation
import EssentialFeed

struct FeedImageViewModel<Image> {
    let isLoading: Bool
    let shouldRetry: Bool
    let image: Image?
    let description: String?
    let location: String?

    var hasDescription: Bool {
        return description != nil
    }

    var hasLocation: Bool {
        return location != nil
    }
}

protocol FeedImageView {
    associatedtype Image
    func display(_ viewModel: FeedImageViewModel<Image>)
}

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
