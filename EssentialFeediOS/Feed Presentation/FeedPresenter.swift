import Foundation
import EssentialFeed

final class FeedPresenter {
    var loadingView: FeedLoadingView?
    var feedView: FeedView?

    func didStartLoadingFeed() {
        loadingView?.display(FeedLoadingViewModel(isLoading: true))
    }

    func didLoadFeed(_ feed: [FeedImage]) {
        feedView?.display(FeedViewModel(feed: feed))
    }

    func didFinishLoadingFeed() {
        loadingView?.display(FeedLoadingViewModel(isLoading: false))
    }

}
