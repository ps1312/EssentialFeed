import Foundation
import EssentialFeed

public final class FeedPresenter {
    private let loadingView: FeedLoadingView
    private let feedView: FeedView

    init(loadingView: FeedLoadingView, feedView: FeedView) {
        self.loadingView = loadingView
        self.feedView = feedView
    }

    static var title: String {
        NSLocalizedString(
            "FEED_VIEW_TITLE",
            tableName: "Feed",
            bundle: Bundle(for: FeedPresenter.self),
            comment: "The feed view screen title"
        )
    }

    func didStartLoadingFeed() {
        loadingView.display(FeedLoadingViewModel(isLoading: true))
    }

    func didLoadFeed(_ feed: [FeedImage]) {
        feedView.display(FeedViewModel(feed: feed))
    }

    func didFinishLoadingFeed() {
        loadingView.display(FeedLoadingViewModel(isLoading: false))
    }

}
