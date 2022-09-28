import Foundation

public struct FeedLoadingViewModel: Equatable {
    public let isLoading: Bool

    public init(isLoading: Bool) {
        self.isLoading = isLoading
    }
}

public protocol FeedLoadingView {
    func display(_ viewModel: FeedLoadingViewModel)
}

public struct FeedViewModel: Equatable {
    let feed: [FeedImage]

    public init(feed: [FeedImage]) {
        self.feed = feed
    }
}

public protocol FeedView {
    func display(_ viewModel: FeedViewModel)
}

public class FeedPresenter {
    private let loadingView: FeedLoadingView
    private let feedView: FeedView

    public static var title: String {
        NSLocalizedString(
            "FEED_VIEW_TITLE",
            tableName: "Feed",
            bundle: Bundle(for: FeedPresenter.self),
            comment: "The feed view screen title"
        )
    }

    public init(loadingView: FeedLoadingView, feedView: FeedView) {
        self.loadingView = loadingView
        self.feedView = feedView
    }

    public func didStartLoadingFeed() {
        loadingView.display(FeedLoadingViewModel(isLoading: true))
    }

    public func didLoadFeed(_ feed: [FeedImage]) {
        loadingView.display(FeedLoadingViewModel(isLoading: false))
        feedView.display(FeedViewModel(feed: feed))
    }
}
