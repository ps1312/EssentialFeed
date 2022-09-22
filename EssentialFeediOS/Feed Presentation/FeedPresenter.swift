import Foundation
import EssentialFeed

final class FeedPresenter {
    var loadingView: FeedLoadingView?
    var feedView: FeedView?

    static var title: String {
        NSLocalizedString(
            "FEED_VIEW_TITLE",
            tableName: "Feed",
            bundle: Bundle(for: FeedPresenter.self),
            comment: "The feed view screen title"
        )
    }

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
