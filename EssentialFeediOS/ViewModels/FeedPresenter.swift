import Foundation
import EssentialFeed

struct FeedLoadingViewModel {
    let isLoading: Bool
}

protocol FeedLoadingView {
    func display(_ viewModel: FeedLoadingViewModel)
}

struct FeedViewModel {
    let feed: [FeedImage]
}

protocol FeedView {
    func display(_ viewModel: FeedViewModel)
}

protocol FeedPresenterDelegate {
    func didStartLoadingFeed()
    func didFinishLoadingFeed(with feed: [FeedImage])
    func didFinishLoadingFeedWithError()
}

final class FeedPresenter: FeedPresenterDelegate {
    var loadingView: FeedLoadingView?
    var feedView: FeedView?

    func didStartLoadingFeed() {
        loadingView?.display(FeedLoadingViewModel(isLoading: true))
    }

    func didFinishLoadingFeed(with feed: [FeedImage]) {
        feedView?.display(FeedViewModel(feed: feed))
    }

    func didFinishLoadingFeedWithError() {
        loadingView?.display(FeedLoadingViewModel(isLoading: false))
    }

}
