import Foundation
import EssentialFeed

public final class FeedPresenter {
    private let loadingView: FeedLoadingView
    private let feedView: FeedView
    private let errorView: FeedErrorView

    init(loadingView: FeedLoadingView, feedView: FeedView, errorView: FeedErrorView) {
        self.loadingView = loadingView
        self.feedView = feedView
        self.errorView = errorView
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
        loadingView.display(FeedLoadingViewModel(isLoading: false))
        feedView.display(FeedViewModel(feed: feed))
    }

    func didFinishLoadingFeedWithError() {
        loadingView.display(FeedLoadingViewModel(isLoading: false))
        errorView.display(FeedErrorViewModel(message: "VAI TOMAR NO C#"))
    }

}
