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

public class FeedPresenter {
    private let loadingView: FeedLoadingView

    public static var title: String {
        NSLocalizedString(
            "FEED_VIEW_TITLE",
            tableName: "Feed",
            bundle: Bundle(for: FeedPresenter.self),
            comment: "The feed view screen title"
        )
    }

    public init(loadingView: FeedLoadingView) {
        self.loadingView = loadingView
    }

    public func didStartLoadingFeed() {
        loadingView.display(FeedLoadingViewModel(isLoading: true))
    }
}
