import Foundation

public class FeedPresenter {
    private let loadingView: ResourceLoadingView
    private let feedView: FeedView
    private let errorView: FeedErrorView

    public static var title: String {
        NSLocalizedString(
            "FEED_VIEW_TITLE",
            tableName: "Feed",
            bundle: Bundle(for: FeedPresenter.self),
            comment: "The feed view screen title"
        )
    }

    public static var loadError: String {
        NSLocalizedString(
            "GENERIC_CONNECTION_ERROR",
            tableName: "Shared",
            bundle: Bundle(for: FeedPresenter.self),
            comment: "The error message for load failure"
        )
    }

    public init(loadingView: ResourceLoadingView, feedView: FeedView, errorView: FeedErrorView) {
        self.loadingView = loadingView
        self.feedView = feedView
        self.errorView = errorView
    }

    public func didStartLoadingFeed() {
        errorView.display(FeedErrorViewModel.noError)
        loadingView.display(ResourceLoadingViewModel(isLoading: true))
    }

    public func didLoadFeed(_ feed: [FeedImage]) {
        loadingView.display(ResourceLoadingViewModel(isLoading: false))
        feedView.display(FeedViewModel(feed: feed))
    }

    public func didFinishLoadingFeedWithError() {
        loadingView.display(ResourceLoadingViewModel(isLoading: false))
        errorView.display(FeedErrorViewModel.error(message: FeedPresenter.loadError))
    }
}
