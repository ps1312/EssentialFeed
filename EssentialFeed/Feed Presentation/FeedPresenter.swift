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

    public init(loadingView: FeedLoadingView) {
        self.loadingView = loadingView
    }

    public func didStartLoadingFeed() {
        loadingView.display(FeedLoadingViewModel(isLoading: true))
    }
}
