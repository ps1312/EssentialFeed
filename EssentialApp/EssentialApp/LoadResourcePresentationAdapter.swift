import Combine
import EssentialFeed
import EssentialFeediOS

final class LoadResourcePresentationAdapter<Resource, View: ResourceView> {
    private let loader: () -> AnyPublisher<Resource, Error>
    private var cancellable: Cancellable?
    var presenter: LoadResourcePresenter<Resource, View>?

    init(loader: @escaping () -> AnyPublisher<Resource, Error>) {
        self.loader = loader
    }

    func loadResource() {
        presenter?.didStartLoading()

        cancellable = loader().sink(receiveCompletion: { [weak self] result in
            switch (result) {
            case .finished: break

            case .failure:
                self?.presenter?.didFinishLoadingWithError()
            }
        }, receiveValue: { [weak self] resource in
            self?.presenter?.didLoad(resource)
        })
    }
}

extension LoadResourcePresentationAdapter: FeedRefreshViewControllerDelegate {
    func didRequestFeedLoad() {
        loadResource()
    }
}

extension LoadResourcePresentationAdapter: FeedImageCellControllerDelegate {
    func didRequestImageLoad() {
        loadResource()
    }

    func didCancelImageLoad() {
        cancellable?.cancel()
    }
}
