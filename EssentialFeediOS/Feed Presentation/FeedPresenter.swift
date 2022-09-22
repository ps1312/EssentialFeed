import Foundation
import EssentialFeed

protocol FeedPresenterDelegate {
    func didStartLoadingFeed()
    func didLoadFeed(_ feed: [FeedImage])
    func didFinishLoadingFeed()
}

final class FeedPresenter: FeedPresenterDelegate {
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
