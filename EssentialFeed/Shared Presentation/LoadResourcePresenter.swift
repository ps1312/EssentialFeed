import Foundation

public protocol ResourceView {
    associatedtype ResourceViewModel

    func display(_ viewModel: ResourceViewModel)
}

public final class LoadResourcePresenter<Resource, View: ResourceView> {
    private let loadingView: ResourceLoadingView
    private let errorView: ResourceErrorView

    private let mapper: Mapper
    private let resourceView: View

    public typealias Mapper = (Resource) -> View.ResourceViewModel
    public static var loadError: String {
        NSLocalizedString(
            "GENERIC_CONNECTION_ERROR",
            tableName: "Shared",
            bundle: Bundle(for: LoadResourcePresenter.self),
            comment: "The error message for resource load failure"
        )
    }

    public init(loadingView: ResourceLoadingView, errorView: ResourceErrorView, resourceView: View, mapper: @escaping Mapper) {
        self.loadingView = loadingView
        self.errorView = errorView
        self.resourceView = resourceView
        self.mapper = mapper
    }

    public func didStartLoading() {
        errorView.display(ResourceErrorViewModel.noError)
        loadingView.display(ResourceLoadingViewModel(isLoading: true))
    }

    public func didLoad(_ resource: Resource) {
        loadingView.display(ResourceLoadingViewModel(isLoading: false))
        resourceView.display(mapper(resource))
    }

    public func didFinishLoadingWithError() {
        loadingView.display(ResourceLoadingViewModel(isLoading: false))
        errorView.display(ResourceErrorViewModel.error(message: Self.loadError))
    }
}
