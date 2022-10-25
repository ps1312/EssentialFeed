import Foundation

public protocol ResourceView {
    func display(_ viewModel: String)
}

public final class LoadResourcePresenter {
    private let loadingView: FeedLoadingView
    private let errorView: FeedErrorView

    private let mapper: (String) -> String
    private let resourceView: ResourceView

    public static var loadError: String {
        NSLocalizedString(
            "FEED_VIEW_CONNECTION_ERROR",
            tableName: "Feed",
            bundle: Bundle(for: FeedPresenter.self),
            comment: "The error message for feed load failure"
        )
    }

    public init(loadingView: FeedLoadingView, errorView: FeedErrorView, resourceView: ResourceView, mapper: @escaping (String) -> String) {
        self.loadingView = loadingView
        self.errorView = errorView
        self.resourceView = resourceView
        self.mapper = mapper
    }

    public func didStartLoading() {
        errorView.display(FeedErrorViewModel.noError)
        loadingView.display(FeedLoadingViewModel(isLoading: true))
    }

    public func didLoad(_ resource: String) {
        loadingView.display(FeedLoadingViewModel(isLoading: false))
        resourceView.display(mapper(resource))
    }

    public func didFinishLoadingFeedWithError() {
        loadingView.display(FeedLoadingViewModel(isLoading: false))
        errorView.display(FeedErrorViewModel.error(message: FeedPresenter.loadError))
    }
}
